-- LRN-02: topic ordering and prerequisite gates that bind.
--
-- LRN-01 showed lock state on reads. Here the same rule decides writes: the
-- learner cannot start or record progress on a locked, unpublished, or
-- ineligible topic, and cannot write `learning_progress` directly at all.
-- Completion is deliberately absent from both RPCs; verified completion is
-- LRN-03 (video) and QZ-05 (scoring) authority.

-- Ordering is curated data, so the database keeps it unambiguous.
create unique index if not exists topics_subject_order_unique
  on public.topics (subject_id, sort_order);

-- A prerequisite must live in the same subject and must not close a loop,
-- otherwise a whole subject could become permanently unreachable.
create or replace function nano_internal.assert_prerequisite_shape()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_subject uuid;
  v_requires_subject uuid;
begin
  select subject_id into v_subject from public.topics where id = new.topic_id;
  select subject_id into v_requires_subject
  from public.topics where id = new.requires_topic_id;

  if v_subject is null or v_requires_subject is null then
    raise exception 'Prerequisite references a missing topic'
      using errcode = 'NL004';
  end if;

  if v_subject <> v_requires_subject then
    raise exception 'Prerequisites must stay inside one subject'
      using errcode = 'NL004';
  end if;

  if exists (
    with recursive chain (topic_id) as (
      select new.requires_topic_id
      union
      select tp.requires_topic_id
      from public.topic_prerequisites tp
      join chain c on c.topic_id = tp.topic_id
    )
    select 1 from chain where topic_id = new.topic_id
  ) then
    raise exception 'Prerequisites must not form a cycle'
      using errcode = 'NL004';
  end if;

  return new;
end;
$$;

revoke all on function nano_internal.assert_prerequisite_shape() from public, anon;

drop trigger if exists topic_prerequisites_shape on public.topic_prerequisites;
create trigger topic_prerequisites_shape
  before insert or update on public.topic_prerequisites
  for each row execute function nano_internal.assert_prerequisite_shape();

-- Single source of truth for "what is still blocking this topic for me".
-- The catalog view reads it and the write guards enforce it, so what a learner
-- sees and what the server allows cannot drift apart.
create or replace function nano_internal.topic_lock_titles(p_topic_version_id uuid)
returns text[]
language sql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
  select coalesce(array_agg(distinct rtv.title order by rtv.title), '{}')
  from public.topic_versions tv
  join public.topic_prerequisites tp on tp.topic_id = tv.topic_id
  join public.topic_versions rtv
    on rtv.topic_id = tp.requires_topic_id and rtv.status = 'published'
  where tv.id = p_topic_version_id
    and not exists (
      select 1
      from public.learning_progress lp
      join public.topic_versions done on done.id = lp.topic_version_id
      where done.topic_id = tp.requires_topic_id
        and lp.user_id = auth.uid()
        and lp.status = 'completed'
    );
$$;

revoke all on function nano_internal.topic_lock_titles(uuid) from public, anon;
grant execute on function nano_internal.topic_lock_titles(uuid)
  to authenticated, service_role;

create or replace function nano_internal.topic_is_playable(p_topic_version_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
  select exists (
    select 1
    from public.topic_versions tv
    join public.subject_versions sv on sv.id = tv.subject_version_id
    where tv.id = p_topic_version_id
      and tv.status = 'published'
      and sv.status = 'published'
      and nano_internal.subject_is_eligible(sv.subject_id)
  );
$$;

revoke all on function nano_internal.topic_is_playable(uuid) from public, anon;
grant execute on function nano_internal.topic_is_playable(uuid)
  to authenticated, service_role;

-- Rebuilt on the shared helper. Column list and semantics are unchanged.
drop view if exists public.learning_catalog;
create view public.learning_catalog with (security_invoker = true) as
select
  s.id                as subject_id,
  s.slug              as subject_slug,
  s.sort_order        as subject_order,
  sv.id               as subject_version_id,
  sv.version          as subject_version,
  sv.title            as subject_title,
  sv.title_ur         as subject_title_ur,
  sv.summary          as subject_summary,
  sv.world_color_hex,
  t.id                as topic_id,
  t.slug              as topic_slug,
  t.sort_order        as topic_order,
  tv.id               as topic_version_id,
  tv.version          as topic_version,
  tv.title            as topic_title,
  tv.title_ur         as topic_title_ur,
  tv.objectives,
  tv.estimated_minutes,
  tv.resources,
  coalesce(lp.status, 'not_started') as progress_status,
  coalesce(lp.progress, 0)           as progress,
  coalesce(lp.resume_seconds, 0)     as resume_seconds,
  nullif(blocking.titles, '{}')                      as blocking_titles,
  coalesce(array_length(blocking.titles, 1), 0) > 0   as is_locked
from public.topic_versions tv
join public.topics t on t.id = tv.topic_id
join public.subject_versions sv on sv.id = tv.subject_version_id
join public.learning_subjects s on s.id = t.subject_id
left join public.learning_progress lp
  on lp.topic_version_id = tv.id and lp.user_id = auth.uid()
left join lateral (
  select nano_internal.topic_lock_titles(tv.id) as titles
) blocking on true;

comment on view public.learning_catalog is
  'LRN-01/LRN-02 catalog read model. Hides unpublished and ineligible content '
  'via the caller''s RLS and reports lock state from '
  'nano_internal.topic_lock_titles, the same helper the write guards use.';

grant select on public.learning_catalog to authenticated, service_role;

-- Progress becomes RPC-only: no client insert or update path remains.
drop policy if exists learning_progress_insert_self on public.learning_progress;
drop policy if exists learning_progress_update_self on public.learning_progress;
revoke insert, update, delete on public.learning_progress from authenticated;

comment on table public.learning_progress is
  'LRN-01/LRN-02 per-learner progress. Owner-only reads; writes only through '
  'public.start_topic and public.save_topic_progress so prerequisite locks '
  'cannot be bypassed. Completion is written by LRN-03 / QZ-05 authority.';

-- Shared guard for both write RPCs.
create or replace function nano_internal.assert_topic_writable(p_topic_version_id uuid)
returns void
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_blocking text[];
begin
  if auth.uid() is null or not nano_internal.is_student() then
    raise exception 'Only an active learner can record learning progress'
      using errcode = 'NL003';
  end if;

  if not nano_internal.topic_is_playable(p_topic_version_id) then
    raise exception 'This topic is not available'
      using errcode = 'NL002';
  end if;

  v_blocking := nano_internal.topic_lock_titles(p_topic_version_id);
  if coalesce(array_length(v_blocking, 1), 0) > 0 then
    raise exception 'Finish % first', array_to_string(v_blocking, ', ')
      using errcode = 'NL001';
  end if;
end;
$$;

revoke all on function nano_internal.assert_topic_writable(uuid) from public, anon;

create or replace function public.start_topic(p_topic_version_id uuid)
returns public.learning_progress
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_row public.learning_progress;
begin
  perform nano_internal.assert_topic_writable(p_topic_version_id);

  insert into public.learning_progress as lp
    (user_id, topic_version_id, status, progress, resume_seconds)
  values (auth.uid(), p_topic_version_id, 'in_progress', 0, 0)
  on conflict (user_id, topic_version_id) do update
    -- Repeat taps are idempotent, and a finished topic stays finished.
    set status = case
                   when lp.status = 'completed' then 'completed'
                   else 'in_progress'
                 end
  returning * into v_row;

  return v_row;
end;
$$;

comment on function public.start_topic(uuid) is
  'LRN-02 opens a topic for the calling learner. Refuses locked, unpublished, '
  'and ineligible topics, is idempotent, and never sets completed.';

revoke all on function public.start_topic(uuid) from public, anon;
grant execute on function public.start_topic(uuid) to authenticated, service_role;

create or replace function public.save_topic_progress(
  p_topic_version_id uuid,
  p_resume_seconds integer,
  p_progress numeric
)
returns public.learning_progress
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_row public.learning_progress;
  v_progress numeric(4,3) := least(greatest(coalesce(p_progress, 0), 0), 1);
  v_seconds integer := greatest(coalesce(p_resume_seconds, 0), 0);
begin
  perform nano_internal.assert_topic_writable(p_topic_version_id);

  insert into public.learning_progress as lp
    (user_id, topic_version_id, status, progress, resume_seconds)
  values (auth.uid(), p_topic_version_id, 'in_progress', v_progress, v_seconds)
  on conflict (user_id, topic_version_id) do update
    set status = case
                   when lp.status = 'completed' then 'completed'
                   else 'in_progress'
                 end,
        -- Progress never walks backwards on a late heartbeat.
        progress = greatest(lp.progress, excluded.progress),
        resume_seconds = excluded.resume_seconds
  returning * into v_row;

  return v_row;
end;
$$;

comment on function public.save_topic_progress(uuid, integer, numeric) is
  'LRN-02 records resume position and watched fraction. Clamps input, never '
  'lowers progress, and cannot mark a topic completed.';

revoke all on function public.save_topic_progress(uuid, integer, numeric)
  from public, anon;
grant execute on function public.save_topic_progress(uuid, integer, numeric)
  to authenticated, service_role;

-- A second senior topic so ordering and prerequisites are exercised outside
-- the junior fixture as well.
insert into public.topics (id, subject_id, slug, sort_order) values
  ('30000000-0000-0000-0000-000000000005',
   '10000000-0000-0000-0000-000000000002', 'plants-and-animals', 2)
on conflict (id) do nothing;

insert into public.topic_versions
  (id, topic_id, subject_version_id, version, title, title_ur, objectives,
   estimated_minutes, status, published_at) values
  ('40000000-0000-0000-0000-000000000005',
   '30000000-0000-0000-0000-000000000005',
   '20000000-0000-0000-0000-000000000002', 1,
   'Plants and animals', 'پودے اور جانور',
   array['Compare plants and animals', 'Name what living things need'],
   16, 'published', timezone('utc', now()))
on conflict (id) do nothing;

insert into public.topic_prerequisites (topic_id, requires_topic_id) values
  ('30000000-0000-0000-0000-000000000005',
   '30000000-0000-0000-0000-000000000003')
on conflict do nothing;

update public.app_health
set schema_version = 'LRN-02',
    notes = 'Topic ordering, prerequisite gates, RPC-only progress writes',
    updated_at = timezone('utc', now())
where id = 'default';
