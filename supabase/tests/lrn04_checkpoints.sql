-- LRN-04 adversarial checks: the long-video rule, curator guardrails, the
-- required-checkpoint credit gate, and content-configured seeking.
--
-- Ecosystems in depth is 2400s with a protected assessment chapter from 1140
-- to 1320. Generated checkpoints land at 660 and 1800; the required one at
-- 1320 was hand-placed and must survive a rebuild.

-- Short videos are never interrupted, and the plan snaps to safe boundaries.
begin;
select 'short_video_has_no_plan' as check, count(*) as rows
from nano_internal.plan_refresh_checkpoints(
  '40000000-0000-0000-0000-000000000001'
);

select 'long_video_plan' as check, at_seconds, kind
from nano_internal.plan_refresh_checkpoints(
  '40000000-0000-0000-0000-000000000006'
)
order by at_seconds;

select 'nothing_inside_protected_chapter' as check,
       nano_internal.checkpoint_is_protected(
         '40000000-0000-0000-0000-000000000006', 1200
       ) as protected_1200,
       nano_internal.checkpoint_is_protected(
         '40000000-0000-0000-0000-000000000006', 1320
       ) as protected_1320;

select 'rebuild_keeps_hand_placed' as check, at_seconds, is_required, generated
from public.rebuild_refresh_checkpoints(
  '40000000-0000-0000-0000-000000000006'
)
order by at_seconds;
rollback;

-- Curator guardrails apply to hand edits too.
begin;
do $$
begin
  begin
    insert into public.refresh_checkpoints
      (topic_version_id, at_seconds, kind, prompt)
    values ('40000000-0000-0000-0000-000000000006', 60, 'ready', 'Too early');
    raise exception 'FAIL: checkpoint accepted at the very start';
  exception when sqlstate 'NL007' then null;
  end;

  begin
    insert into public.refresh_checkpoints
      (topic_version_id, at_seconds, kind, prompt)
    values ('40000000-0000-0000-0000-000000000006', 1200, 'ready',
            'Mid-assessment');
    raise exception 'FAIL: checkpoint accepted inside a protected chapter';
  exception when sqlstate 'NL008' then null;
  end;

  begin
    insert into public.refresh_checkpoints
      (topic_version_id, at_seconds, kind, prompt)
    values ('40000000-0000-0000-0000-000000000006', 1900, 'ready',
            'Too soon after 1800');
    raise exception 'FAIL: checkpoint accepted within five minutes of another';
  exception when sqlstate 'NL009' then null;
  end;
end $$;
select 'placement_guards_hold' as check, true as ok;
rollback;

-- Learners read checkpoints and never write them, and cannot rebuild.
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","role":"authenticated"}';

insert into public.student_onboarding
  (user_id, current_step, experience_track, self_reported_grade_level, completed_at)
values (auth.uid(), 'ready', 'senior', 8, timezone('utc', now()))
on conflict (user_id) do update
set experience_track = 'senior', self_reported_grade_level = 8;

do $$
begin
  begin
    insert into public.refresh_checkpoints
      (topic_version_id, at_seconds, kind, prompt)
    values ('40000000-0000-0000-0000-000000000006', 900, 'ready', 'Mine now');
    raise exception 'FAIL: learner inserted a checkpoint';
  exception when insufficient_privilege then null;
  end;

  begin
    perform public.rebuild_refresh_checkpoints(
      '40000000-0000-0000-0000-000000000006'
    );
    raise exception 'FAIL: learner rebuilt checkpoints';
  exception when insufficient_privilege then null;
  end;

  begin
    insert into public.checkpoint_events
      (user_id, checkpoint_id, topic_version_id, response)
    select auth.uid(), rc.id, rc.topic_version_id, 'continued'
    from public.refresh_checkpoints rc
    where rc.topic_version_id = '40000000-0000-0000-0000-000000000006'
      and rc.is_required;
    raise exception 'FAIL: learner cleared a required gate directly';
  exception when insufficient_privilege then null;
  end;
end $$;

select 'learner_sees_checkpoints' as check, count(*) as rows
from public.refresh_checkpoints
where topic_version_id = '40000000-0000-0000-0000-000000000006';
rollback;

-- Watch credit stops at an unanswered required checkpoint and resumes after.
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","role":"authenticated"}';

insert into public.student_onboarding
  (user_id, current_step, experience_track, self_reported_grade_level, completed_at)
values (auth.uid(), 'ready', 'senior', 8, timezone('utc', now()))
on conflict (user_id) do update
set experience_track = 'senior', self_reported_grade_level = 8;

do $$
begin
  perform public.start_topic('40000000-0000-0000-0000-000000000006');
end $$;

-- Stand in for twenty-one minutes of real watching.
reset role;
update public.learning_progress
set watched_seconds = 1300,
    resume_seconds = 1300,
    last_heartbeat_at = timezone('utc', now()) - interval '120 seconds'
where user_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
  and topic_version_id = '40000000-0000-0000-0000-000000000006';

set local role authenticated;
set local request.jwt.claims =
  '{"sub":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","role":"authenticated"}';

select 'credit_stops_at_required_checkpoint' as check,
       (public.record_playback_heartbeat(
          '40000000-0000-0000-0000-000000000006', 1420
        )).watched_seconds as watched_seconds;

do $$
declare
  v_id uuid;
  v_first public.checkpoint_events;
  v_second public.checkpoint_events;
begin
  select id into v_id from public.refresh_checkpoints
  where topic_version_id = '40000000-0000-0000-0000-000000000006'
    and is_required;

  begin
    perform public.acknowledge_checkpoint(v_id, 'nonsense');
    raise exception 'FAIL: unknown response accepted';
  exception when sqlstate 'NL011' then null;
  end;

  v_first := public.acknowledge_checkpoint(v_id, 'answered');
  v_second := public.acknowledge_checkpoint(v_id, 'continued');
  if v_first.id <> v_second.id then
    raise exception 'FAIL: acknowledgement is not idempotent';
  end if;
end $$;

reset role;
update public.learning_progress
set last_heartbeat_at = timezone('utc', now()) - interval '120 seconds'
where user_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
  and topic_version_id = '40000000-0000-0000-0000-000000000006';

set local role authenticated;
set local request.jwt.claims =
  '{"sub":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","role":"authenticated"}';

select 'credit_resumes_after_acknowledgement' as check,
       (public.record_playback_heartbeat(
          '40000000-0000-0000-0000-000000000006', 1500
        )).watched_seconds as watched_seconds;
rollback;

-- Content that forbids skipping ahead: the reported head is clamped server-side.
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

insert into public.student_onboarding
  (user_id, current_step, experience_track, self_reported_grade_level, completed_at)
values (auth.uid(), 'ready', 'junior', 3, timezone('utc', now()))
on conflict (user_id) do update
set experience_track = 'junior', self_reported_grade_level = 3;

-- Unlock addition the only way a learner can: by finishing counting.
reset role;
insert into public.learning_progress
  (user_id, topic_version_id, status, progress, resume_seconds,
   watched_seconds, completed_at)
values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        '40000000-0000-0000-0000-000000000001', 'completed', 1, 120, 120,
        timezone('utc', now()))
on conflict (user_id, topic_version_id) do update
set status = 'completed', completed_at = timezone('utc', now());

set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

do $$
begin
  perform public.start_topic('40000000-0000-0000-0000-000000000002');
  perform public.record_playback_heartbeat(
    '40000000-0000-0000-0000-000000000002', 0
  );
end $$;

select 'no_skip_ahead_clamps_position' as check,
       (public.record_playback_heartbeat(
          '40000000-0000-0000-0000-000000000002', 145
        )).resume_seconds as resume_seconds;
rollback;
