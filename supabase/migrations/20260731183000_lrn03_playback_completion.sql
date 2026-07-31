-- LRN-03: verified playback progress and completion.
--
-- The client no longer claims a progress fraction. It reports where the player
-- head is, and the server credits watch time from wall-clock elapsed since the
-- previous heartbeat. Seeking forward therefore earns nothing, and completion
-- requires the published version's threshold of credited time. Completion is
-- recorded once per (learner, topic version) and audited.

alter table public.topic_versions
  add column if not exists duration_seconds integer not null default 300,
  add column if not exists completion_threshold numeric(3,2) not null default 0.90,
  add column if not exists video_provider text,
  add column if not exists video_ref text,
  add column if not exists captions jsonb not null default '[]'::jsonb;

alter table public.topic_versions
  drop constraint if exists topic_versions_duration_check;
alter table public.topic_versions
  add constraint topic_versions_duration_check
  check (duration_seconds between 30 and 14400);

alter table public.topic_versions
  drop constraint if exists topic_versions_threshold_check;
alter table public.topic_versions
  add constraint topic_versions_threshold_check
  check (completion_threshold between 0.50 and 1.00);

comment on column public.topic_versions.video_ref is
  'LRN-03 approved-provider reference. Never a signed URL or credential; '
  'MED-01 resolves playback URLs server-side.';

alter table public.learning_progress
  add column if not exists watched_seconds integer not null default 0,
  add column if not exists last_heartbeat_at timestamptz;

alter table public.learning_progress
  drop constraint if exists learning_progress_watched_check;
alter table public.learning_progress
  add constraint learning_progress_watched_check
  check (watched_seconds >= 0);

comment on table public.learning_progress is
  'LRN-01/02/03 per-learner progress. Owner-only reads; writes only through '
  'public.start_topic, public.record_playback_heartbeat, and '
  'public.complete_topic, so prerequisite locks stay binding and watch time is '
  'credited by the server rather than claimed by the client.';

-- One completion per learner per published version. The unique key is the
-- reason "completion cannot be duplicated" is a database fact, not a code path.
create table if not exists public.topic_completions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  topic_version_id uuid not null references public.topic_versions (id) on delete cascade,
  watched_seconds integer not null,
  duration_seconds integer not null,
  completed_at timestamptz not null default timezone('utc', now()),
  unique (user_id, topic_version_id)
);

comment on table public.topic_completions is
  'LRN-03 verified completion source event. XP-01 reads this; learners can '
  'read their own rows and never write them.';

create index if not exists topic_completions_user_idx
  on public.topic_completions (user_id, completed_at desc);

alter table public.topic_completions enable row level security;

drop policy if exists topic_completions_select_self on public.topic_completions;
create policy topic_completions_select_self on public.topic_completions
  for select to authenticated
  using (user_id = auth.uid() or nano_internal.is_platform_admin());

revoke insert, update, delete on public.topic_completions from authenticated;

-- How much credit a single heartbeat may earn. Wall-clock elapsed with a small
-- tolerance for jitter, capped so a backgrounded tab cannot bank an hour.
create or replace function nano_internal.playback_credit(
  p_position_delta integer,
  p_elapsed_seconds numeric
)
returns integer
language sql
immutable
set search_path = pg_catalog
as $$
  select greatest(
    0,
    least(
      coalesce(p_position_delta, 0),
      floor(coalesce(p_elapsed_seconds, 0) * 1.25)::integer,
      120
    )
  );
$$;

comment on function nano_internal.playback_credit(integer, numeric) is
  'LRN-03 watch-time credit for one heartbeat: never more than the position '
  'advanced, never more than wall-clock elapsed plus jitter, never more than '
  '120s per beat.';

revoke all on function nano_internal.playback_credit(integer, numeric)
  from public, anon;

-- Replaces LRN-02 save_topic_progress: the fraction is derived, not accepted.
drop function if exists public.save_topic_progress(uuid, integer, numeric);

create or replace function public.record_playback_heartbeat(
  p_topic_version_id uuid,
  p_position_seconds integer
)
returns public.learning_progress
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_row public.learning_progress;
  v_duration integer;
  v_position integer;
  v_credit integer;
  v_now timestamptz := timezone('utc', now());
begin
  perform nano_internal.assert_topic_writable(p_topic_version_id);

  select duration_seconds into v_duration
  from public.topic_versions
  where id = p_topic_version_id;

  v_position := least(greatest(coalesce(p_position_seconds, 0), 0), v_duration);

  select * into v_row
  from public.learning_progress
  where user_id = auth.uid() and topic_version_id = p_topic_version_id;

  if v_row.user_id is null then
    insert into public.learning_progress
      (user_id, topic_version_id, status, progress, resume_seconds,
       watched_seconds, last_heartbeat_at)
    values (auth.uid(), p_topic_version_id, 'in_progress', 0, v_position,
            0, v_now)
    returning * into v_row;
    return v_row;
  end if;

  v_credit := nano_internal.playback_credit(
    v_position - v_row.resume_seconds,
    extract(epoch from v_now - coalesce(v_row.last_heartbeat_at, v_now))
  );

  update public.learning_progress lp
  set resume_seconds = v_position,
      watched_seconds = least(lp.watched_seconds + v_credit, v_duration),
      progress = least(
        (least(lp.watched_seconds + v_credit, v_duration))::numeric
          / greatest(v_duration, 1),
        1
      ),
      status = case when lp.status = 'completed' then 'completed'
                    else 'in_progress' end,
      last_heartbeat_at = v_now
  where lp.user_id = auth.uid()
    and lp.topic_version_id = p_topic_version_id
  returning * into v_row;

  return v_row;
end;
$$;

comment on function public.record_playback_heartbeat(uuid, integer) is
  'LRN-03 records the player position and credits watch time from elapsed '
  'wall-clock. Idempotent under retry: a repeated beat earns no extra credit.';

revoke all on function public.record_playback_heartbeat(uuid, integer)
  from public, anon;
grant execute on function public.record_playback_heartbeat(uuid, integer)
  to authenticated, service_role;

create or replace function public.complete_topic(p_topic_version_id uuid)
returns public.learning_progress
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_row public.learning_progress;
  v_duration integer;
  v_threshold numeric(3,2);
  v_required integer;
begin
  perform nano_internal.assert_topic_writable(p_topic_version_id);

  select duration_seconds, completion_threshold
  into v_duration, v_threshold
  from public.topic_versions
  where id = p_topic_version_id;

  select * into v_row
  from public.learning_progress
  where user_id = auth.uid() and topic_version_id = p_topic_version_id;

  -- Already finished: return the same row rather than recording a second event.
  if v_row.status = 'completed' then
    return v_row;
  end if;

  v_required := ceil(v_duration * v_threshold)::integer;
  if coalesce(v_row.watched_seconds, 0) < v_required then
    raise exception 'Keep watching: % of % seconds credited',
      coalesce(v_row.watched_seconds, 0), v_required
      using errcode = 'NL005';
  end if;

  update public.learning_progress lp
  set status = 'completed',
      progress = 1,
      completed_at = timezone('utc', now())
  where lp.user_id = auth.uid()
    and lp.topic_version_id = p_topic_version_id
  returning * into v_row;

  insert into public.topic_completions
    (user_id, topic_version_id, watched_seconds, duration_seconds)
  values (auth.uid(), p_topic_version_id, v_row.watched_seconds, v_duration)
  on conflict (user_id, topic_version_id) do nothing;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'student', 'create', 'topic_completion',
    p_topic_version_id::text,
    jsonb_build_object(
      'watched_seconds', v_row.watched_seconds,
      'duration_seconds', v_duration,
      'threshold', v_threshold
    )
  );

  return v_row;
end;
$$;

comment on function public.complete_topic(uuid) is
  'LRN-03 marks a topic complete once the server-credited watch time reaches '
  'the version threshold. Idempotent, audited, and never client-forced.';

revoke all on function public.complete_topic(uuid) from public, anon;
grant execute on function public.complete_topic(uuid) to authenticated, service_role;

-- Playback metadata joins the existing read model so the player needs no
-- second query and cannot see a different version than the catalog.
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
  tv.duration_seconds,
  tv.completion_threshold,
  tv.video_provider,
  tv.video_ref,
  tv.captions,
  coalesce(lp.status, 'not_started') as progress_status,
  coalesce(lp.progress, 0)           as progress,
  coalesce(lp.resume_seconds, 0)     as resume_seconds,
  coalesce(lp.watched_seconds, 0)    as watched_seconds,
  nullif(blocking.titles, '{}')                     as blocking_titles,
  coalesce(array_length(blocking.titles, 1), 0) > 0 as is_locked
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
  'LRN-01/02/03 catalog read model: eligibility and drafts via the caller''s '
  'RLS, lock state from nano_internal.topic_lock_titles, and playback '
  'metadata with the learner''s credited watch time.';

grant select on public.learning_catalog to authenticated, service_role;

-- Development playback fixtures: short durations so the owner test is quick.
update public.topic_versions
set duration_seconds = 120,
    completion_threshold = 0.90,
    video_provider = 'fixture',
    video_ref = 'counting-to-20',
    captions = jsonb_build_array(
      jsonb_build_object('at', 0, 'text', 'Let us count to twenty.',
                         'text_ur', 'آئیے بیس تک گنتی کریں۔'),
      jsonb_build_object('at', 30, 'text', 'Ten comes after nine.',
                         'text_ur', 'نو کے بعد دس آتا ہے۔'),
      jsonb_build_object('at', 75, 'text', 'Now count with me.',
                         'text_ur', 'اب میرے ساتھ گنیں۔')
    )
where id = '40000000-0000-0000-0000-000000000001';

update public.topic_versions
set duration_seconds = 150,
    video_provider = 'fixture',
    video_ref = 'adding-small-numbers'
where id = '40000000-0000-0000-0000-000000000002';

update public.topic_versions
set duration_seconds = 180,
    video_provider = 'fixture',
    video_ref = 'living-things',
    captions = jsonb_build_array(
      jsonb_build_object('at', 0, 'text', 'Living things grow.',
                         'text_ur', 'جاندار بڑھتے ہیں۔')
    )
where id = '40000000-0000-0000-0000-000000000003';

update public.topic_versions
set duration_seconds = 160,
    video_provider = 'fixture',
    video_ref = 'plants-and-animals'
where id = '40000000-0000-0000-0000-000000000005';

update public.app_health
set schema_version = 'LRN-03',
    notes = 'Verified playback credit, resume, captions, audited completion',
    updated_at = timezone('utc', now())
where id = 'default';
