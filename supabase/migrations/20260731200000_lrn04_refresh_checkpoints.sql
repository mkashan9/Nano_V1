-- LRN-04: long-video refresh checkpoints and content-configured seeking.
--
-- Handbook 10.4: past thirty minutes, offer refresh moments near ten-minute
-- intervals, snapped to chapter boundaries, never inside an assessment or
-- mid-sentence segment. Learners can silence optional prompts; required ones
-- stay, and watch credit stops at a required checkpoint until it is answered,
-- so silencing prompts can never become a way to skim a video.

alter table public.topic_versions
  add column if not exists chapters jsonb not null default '[]'::jsonb,
  add column if not exists seek_policy text not null default 'free';

alter table public.topic_versions
  drop constraint if exists topic_versions_seek_policy_check;
alter table public.topic_versions
  add constraint topic_versions_seek_policy_check
  check (seek_policy in ('free', 'no_skip_ahead'));

comment on column public.topic_versions.chapters is
  'LRN-04 ordered [{at, title, title_ur, protected}]. A protected chapter is a '
  'segment that must not be interrupted, such as an assessment or a narration '
  'that would be cut mid-sentence.';

comment on column public.topic_versions.seek_policy is
  'LRN-04 content-configured seeking. no_skip_ahead clamps a reported position '
  'to what the learner has actually watched.';

create table if not exists public.refresh_checkpoints (
  id uuid primary key default gen_random_uuid(),
  topic_version_id uuid not null
    references public.topic_versions (id) on delete cascade,
  at_seconds integer not null check (at_seconds > 0),
  kind text not null default 'ready'
    check (kind in ('stretch', 'recall', 'ready')),
  prompt text not null,
  prompt_ur text,
  is_required boolean not null default false,
  generated boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (topic_version_id, at_seconds)
);

comment on table public.refresh_checkpoints is
  'LRN-04 optional refresh moments inside a long video. Curator-owned: '
  'learners read them and never write them.';

create index if not exists refresh_checkpoints_version_idx
  on public.refresh_checkpoints (topic_version_id, at_seconds);

drop trigger if exists refresh_checkpoints_set_updated_at
  on public.refresh_checkpoints;
create trigger refresh_checkpoints_set_updated_at
  before update on public.refresh_checkpoints
  for each row execute function public.set_updated_at();

create table if not exists public.checkpoint_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  checkpoint_id uuid not null
    references public.refresh_checkpoints (id) on delete cascade,
  topic_version_id uuid not null
    references public.topic_versions (id) on delete cascade,
  response text not null
    check (response in ('continued', 'stretched', 'answered', 'postponed')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (user_id, checkpoint_id)
);

comment on table public.checkpoint_events is
  'LRN-04 one row per learner per checkpoint. Written only by '
  'public.acknowledge_checkpoint so a client cannot clear a required gate by '
  'inventing rows.';

drop trigger if exists checkpoint_events_set_updated_at on public.checkpoint_events;
create trigger checkpoint_events_set_updated_at
  before update on public.checkpoint_events
  for each row execute function public.set_updated_at();

alter table public.refresh_checkpoints enable row level security;
alter table public.checkpoint_events enable row level security;

-- Checkpoints follow whatever the learner may already see of the topic.
drop policy if exists refresh_checkpoints_select on public.refresh_checkpoints;
create policy refresh_checkpoints_select on public.refresh_checkpoints
  for select to authenticated
  using (
    nano_internal.is_platform_admin()
    or exists (
      select 1 from public.topic_versions tv
      where tv.id = topic_version_id
    )
  );

revoke insert, update, delete on public.refresh_checkpoints from authenticated;

drop policy if exists checkpoint_events_select_self on public.checkpoint_events;
create policy checkpoint_events_select_self on public.checkpoint_events
  for select to authenticated
  using (user_id = auth.uid() or nano_internal.is_platform_admin());

revoke insert, update, delete on public.checkpoint_events from authenticated;

-- Placement guardrails. These apply to curator edits as well as to generated
-- rows, so "editors can move checkpoints" cannot silently produce a prompt in
-- the middle of an assessment.
create or replace function nano_internal.assert_checkpoint_placement()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_duration integer;
  v_chapter jsonb;
  v_next_at integer;
begin
  select duration_seconds into v_duration
  from public.topic_versions
  where id = new.topic_version_id;

  if v_duration is null then
    raise exception 'Unknown topic version' using errcode = 'NL006';
  end if;

  -- Never at the very start, and never so close to the end that the prompt
  -- interrupts a learner who is about to finish anyway.
  if new.at_seconds < 120 or new.at_seconds > v_duration - 120 then
    raise exception
      'Checkpoint at % s is too close to the edges of a % second video',
      new.at_seconds, v_duration
      using errcode = 'NL007';
  end if;

  -- Inside a protected chapter is never a safe boundary.
  for v_chapter in
    select value from jsonb_array_elements(
      coalesce(
        (select chapters from public.topic_versions
          where id = new.topic_version_id),
        '[]'::jsonb
      )
    )
  loop
    if coalesce((v_chapter->>'protected')::boolean, false) then
      select coalesce(min((c->>'at')::integer), v_duration)
      into v_next_at
      from jsonb_array_elements(
        (select chapters from public.topic_versions
          where id = new.topic_version_id)
      ) c
      where (c->>'at')::integer > (v_chapter->>'at')::integer;

      if new.at_seconds > (v_chapter->>'at')::integer
        and new.at_seconds < v_next_at then
        raise exception 'Checkpoint at % s falls inside protected chapter %',
          new.at_seconds, coalesce(v_chapter->>'title', 'untitled')
          using errcode = 'NL008';
      end if;
    end if;
  end loop;

  -- Two prompts within five minutes is the "interrupt every ten minutes
  -- blindly" failure the handbook warns about.
  if exists (
    select 1 from public.refresh_checkpoints rc
    where rc.topic_version_id = new.topic_version_id
      and rc.id <> coalesce(new.id, '00000000-0000-0000-0000-000000000000'::uuid)
      and abs(rc.at_seconds - new.at_seconds) < 300
  ) then
    raise exception 'Checkpoint at % s is within five minutes of another one',
      new.at_seconds
      using errcode = 'NL009';
  end if;

  return new;
end;
$$;

revoke all on function nano_internal.assert_checkpoint_placement()
  from public, anon;

drop trigger if exists refresh_checkpoints_placement on public.refresh_checkpoints;
create trigger refresh_checkpoints_placement
  before insert or update on public.refresh_checkpoints
  for each row execute function nano_internal.assert_checkpoint_placement();

-- The handbook rule as a function: only past thirty minutes, aim for ten-minute
-- spacing, then snap each candidate to the nearest chapter boundary within two
-- minutes and drop anything that lands in a protected segment.
create or replace function nano_internal.checkpoint_is_protected(
  p_topic_version_id uuid,
  p_at_seconds integer
)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
  with ordered as (
    select (c->>'at')::integer as at_seconds,
           coalesce((c->>'protected')::boolean, false) as protected,
           lead((c->>'at')::integer) over (order by (c->>'at')::integer)
             as next_at
    from public.topic_versions tv
    cross join jsonb_array_elements(coalesce(tv.chapters, '[]'::jsonb)) c
    where tv.id = p_topic_version_id
  )
  select exists (
    select 1 from ordered
    where protected
      and p_at_seconds > at_seconds
      and p_at_seconds < coalesce(next_at, 2147483647)
  );
$$;

create or replace function nano_internal.plan_refresh_checkpoints(
  p_topic_version_id uuid
)
returns table (at_seconds integer, kind text)
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_duration integer;
  v_chapters jsonb;
  v_candidate integer;
  v_snapped integer;
  v_last integer := 0;
  v_index integer := 0;
begin
  select duration_seconds, chapters
  into v_duration, v_chapters
  from public.topic_versions
  where id = p_topic_version_id;

  -- Short videos are never interrupted.
  if coalesce(v_duration, 0) <= 1800 then
    return;
  end if;

  v_candidate := 600;
  while v_candidate < v_duration - 120 loop
    select c_at into v_snapped
    from (
      select (c->>'at')::integer as c_at,
             coalesce((c->>'protected')::boolean, false) as c_protected
      from jsonb_array_elements(coalesce(v_chapters, '[]'::jsonb)) c
    ) boundaries
    where not c_protected
      and abs(c_at - v_candidate) <= 120
      and c_at >= 120
      and c_at <= v_duration - 120
    order by abs(c_at - v_candidate)
    limit 1;

    v_snapped := coalesce(v_snapped, v_candidate);

    if not nano_internal.checkpoint_is_protected(p_topic_version_id, v_snapped)
      and v_snapped - v_last >= 300 then
      v_index := v_index + 1;
      at_seconds := v_snapped;
      -- Alternate a body-break and a recall prompt so a long sitting is not
      -- three identical interruptions.
      kind := case when v_index % 2 = 1 then 'stretch' else 'recall' end;
      v_last := v_snapped;
      return next;
    end if;

    v_candidate := v_candidate + 600;
  end loop;
end;
$$;

revoke all on function nano_internal.plan_refresh_checkpoints(uuid)
  from public, anon;
revoke all on function nano_internal.checkpoint_is_protected(uuid, integer)
  from public, anon;

-- Curator entry point. Regenerating replaces generated rows and leaves
-- hand-placed ones alone, so an editor's move or removal survives a rebuild.
create or replace function public.rebuild_refresh_checkpoints(
  p_topic_version_id uuid
)
returns setof public.refresh_checkpoints
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_plan record;
begin
  -- Trusted backend contexts have no auth.uid(); a signed-in caller must be a
  -- platform admin. EXECUTE is revoked from authenticated regardless.
  if auth.uid() is not null and not nano_internal.is_platform_admin() then
    raise exception 'Only a platform admin can rebuild checkpoints'
      using errcode = 'NL010';
  end if;

  delete from public.refresh_checkpoints
  where topic_version_id = p_topic_version_id and generated;

  for v_plan in
    select * from nano_internal.plan_refresh_checkpoints(p_topic_version_id)
  loop
    begin
      insert into public.refresh_checkpoints
        (topic_version_id, at_seconds, kind, prompt, prompt_ur,
         is_required, generated)
      values (
        p_topic_version_id,
        v_plan.at_seconds,
        v_plan.kind,
        case v_plan.kind
          when 'stretch' then 'Stand up and stretch for a moment.'
          else 'What is the one thing you remember most so far?'
        end,
        case v_plan.kind
          when 'stretch' then 'ایک لمحے کے لیے کھڑے ہو کر جسم کو ڈھیلا کریں۔'
          else 'اب تک آپ کو سب سے زیادہ کیا یاد ہے؟'
        end,
        false,
        true
      );
    exception
      -- A hand-placed checkpoint already owns this moment; leave it alone.
      when unique_violation then null;
      when sqlstate 'NL009' then null;
    end;
  end loop;

  return query
    select * from public.refresh_checkpoints
    where topic_version_id = p_topic_version_id
    order by at_seconds;
end;
$$;

comment on function public.rebuild_refresh_checkpoints(uuid) is
  'LRN-04 regenerates generated checkpoints for one topic version. Platform '
  'admins only; hand-placed checkpoints are preserved.';

revoke all on function public.rebuild_refresh_checkpoints(uuid)
  from public, anon, authenticated;
grant execute on function public.rebuild_refresh_checkpoints(uuid)
  to service_role;

-- Where watch credit has to stop for this learner: the first required
-- checkpoint they have not answered.
create or replace function nano_internal.checkpoint_credit_gate(
  p_topic_version_id uuid,
  p_duration integer
)
returns integer
language sql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
  select coalesce(
    min(rc.at_seconds),
    p_duration
  )
  from public.refresh_checkpoints rc
  where rc.topic_version_id = p_topic_version_id
    and rc.is_required
    and not exists (
      select 1 from public.checkpoint_events ce
      where ce.checkpoint_id = rc.id
        and ce.user_id = auth.uid()
    );
$$;

revoke all on function nano_internal.checkpoint_credit_gate(uuid, integer)
  from public, anon;

create or replace function public.acknowledge_checkpoint(
  p_checkpoint_id uuid,
  p_response text
)
returns public.checkpoint_events
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_version uuid;
  v_row public.checkpoint_events;
begin
  select topic_version_id into v_version
  from public.refresh_checkpoints
  where id = p_checkpoint_id;

  if v_version is null then
    raise exception 'Unknown checkpoint' using errcode = 'NL006';
  end if;

  -- Same gate as any other progress write: an active learner, on a topic they
  -- are allowed to be watching.
  perform nano_internal.assert_topic_writable(v_version);

  if coalesce(p_response, '') not in
    ('continued', 'stretched', 'answered', 'postponed') then
    raise exception 'Unknown checkpoint response %', p_response
      using errcode = 'NL011';
  end if;

  insert into public.checkpoint_events
    (user_id, checkpoint_id, topic_version_id, response)
  values (auth.uid(), p_checkpoint_id, v_version, p_response)
  on conflict (user_id, checkpoint_id) do update
    set response = excluded.response
  returning * into v_row;

  return v_row;
end;
$$;

comment on function public.acknowledge_checkpoint(uuid, text) is
  'LRN-04 records the learner''s answer to a refresh checkpoint. Idempotent, '
  'owner-only, and the only way to clear a required checkpoint gate.';

revoke all on function public.acknowledge_checkpoint(uuid, text)
  from public, anon;
grant execute on function public.acknowledge_checkpoint(uuid, text)
  to authenticated, service_role;

-- Heartbeat now honours the seeking policy and the required-checkpoint gate.
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
  v_seek text;
  v_position integer;
  v_credit integer;
  v_gate integer;
  v_watched integer;
  v_now timestamptz := timezone('utc', now());
begin
  perform nano_internal.assert_topic_writable(p_topic_version_id);

  select duration_seconds, seek_policy
  into v_duration, v_seek
  from public.topic_versions
  where id = p_topic_version_id;

  v_position := least(greatest(coalesce(p_position_seconds, 0), 0), v_duration);

  select * into v_row
  from public.learning_progress
  where user_id = auth.uid() and topic_version_id = p_topic_version_id;

  -- Content that forbids skipping ahead: the head may sit a little past what
  -- was watched, never far past it.
  if v_seek = 'no_skip_ahead' then
    v_position := least(v_position, coalesce(v_row.watched_seconds, 0) + 30);
  end if;

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

  v_gate := nano_internal.checkpoint_credit_gate(p_topic_version_id, v_duration);
  v_watched := least(v_row.watched_seconds + v_credit, v_duration, v_gate);
  -- A gate never takes back credit the learner already earned.
  v_watched := greatest(v_watched, v_row.watched_seconds);

  update public.learning_progress lp
  set resume_seconds = v_position,
      watched_seconds = v_watched,
      progress = least(v_watched::numeric / greatest(v_duration, 1), 1),
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
  'LRN-03/04 records the player position and credits watch time from elapsed '
  'wall-clock, clamped by the content seeking policy and stopped at the first '
  'unanswered required checkpoint. Idempotent under retry.';

revoke all on function public.record_playback_heartbeat(uuid, integer)
  from public, anon;
grant execute on function public.record_playback_heartbeat(uuid, integer)
  to authenticated, service_role;

-- Catalog carries the seeking policy and chapters so the player can lay out
-- the scrubber correctly on first paint.
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
  tv.chapters,
  tv.seek_policy,
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
  'LRN-01..04 catalog read model: eligibility and drafts via the caller''s RLS, '
  'lock state from nano_internal.topic_lock_titles, playback metadata, '
  'chapters, and the content seeking policy.';

grant select on public.learning_catalog to authenticated, service_role;

-- A long senior fixture so the rule has something real to act on: forty
-- minutes, five chapters, and an assessment segment that must not be cut.
insert into public.topics (id, subject_id, slug, sort_order) values
  ('30000000-0000-0000-0000-000000000006',
   '10000000-0000-0000-0000-000000000002', 'ecosystems-in-depth', 3)
on conflict (id) do nothing;

insert into public.topic_versions
  (id, topic_id, subject_version_id, version, title, title_ur, objectives,
   estimated_minutes, status, published_at, duration_seconds,
   completion_threshold, video_provider, video_ref, seek_policy, chapters)
values (
  '40000000-0000-0000-0000-000000000006',
  '30000000-0000-0000-0000-000000000006',
  '20000000-0000-0000-0000-000000000002', 1,
  'Ecosystems in depth', 'ماحولیاتی نظام تفصیل سے',
  array['Trace energy through a food web', 'Explain one balance that fails'],
  40, 'published', timezone('utc', now()), 2400,
  0.90, 'fixture', 'ecosystems-in-depth', 'free',
  jsonb_build_array(
    jsonb_build_object('at', 0, 'title', 'What an ecosystem is',
                       'title_ur', 'ماحولیاتی نظام کیا ہے', 'protected', false),
    jsonb_build_object('at', 660, 'title', 'Food webs',
                       'title_ur', 'غذائی جالیں', 'protected', false),
    jsonb_build_object('at', 1140, 'title', 'Check yourself',
                       'title_ur', 'اپنا جائزہ لیں', 'protected', true),
    jsonb_build_object('at', 1320, 'title', 'When balance fails',
                       'title_ur', 'توازن بگڑنے پر', 'protected', false),
    jsonb_build_object('at', 1980, 'title', 'Recovery',
                       'title_ur', 'بحالی', 'protected', false)
  )
)
on conflict (id) do nothing;

-- Hand-placed first, so the rebuild below has to work around it. This is the
-- required checkpoint: watch credit stops here until the learner answers.
insert into public.refresh_checkpoints
  (topic_version_id, at_seconds, kind, prompt, prompt_ur, is_required,
   generated)
values (
  '40000000-0000-0000-0000-000000000006', 1320, 'recall',
  'Before the last part: name one thing that keeps an ecosystem in balance.',
  'آخری حصے سے پہلے: ایک چیز بتائیں جو ماحولیاتی نظام کا توازن رکھتی ہے۔',
  true, false
)
on conflict (topic_version_id, at_seconds) do nothing;

select public.rebuild_refresh_checkpoints(
  '40000000-0000-0000-0000-000000000006'
);

-- Short content is where a no-skip-ahead policy is easy to feel.
update public.topic_versions
set seek_policy = 'no_skip_ahead'
where id = '40000000-0000-0000-0000-000000000002';

update public.app_health
set schema_version = 'LRN-04',
    notes = 'Long-video checkpoints, required-checkpoint credit gate, seek policy',
    updated_at = timezone('utc', now())
where id = 'default';
