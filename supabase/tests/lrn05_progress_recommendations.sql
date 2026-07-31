-- LRN-05 adversarial checks: what a recommendation may name, and whose progress
-- a summary may count.
--
-- Both read models sit on public.learning_catalog, so the interesting question
-- is whether anything the learner cannot open can still be suggested to them.

-- A fresh junior learner: locked, senior-only, and draft content must all be
-- absent, and the summary must count only what they can see.
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

insert into public.student_onboarding
  (user_id, current_step, experience_track, self_reported_grade_level, completed_at)
values (auth.uid(), 'ready', 'junior', 3, timezone('utc', now()))
on conflict (user_id) do update
set experience_track = 'junior', self_reported_grade_level = 3;

select 'fresh_next_up' as check,
       string_agg(topic_title || '/' || reason, ' | ' order by rank) as value
from public.learning_next_up;

select 'locked_never_suggested' as check, count(*) as rows
from public.learning_next_up
where topic_slug in ('addition', 'plants-and-animals');

select 'senior_only_subject_hidden' as check, count(*) as rows
from public.learning_next_up
where subject_slug = 'science';

select 'draft_subject_hidden' as check, count(*) as rows
from public.learning_next_up
where subject_slug = 'coding';

select 'summary_counts_visible_only' as check,
       string_agg(
         subject_title || ':' || topics_completed || '/' || topics_total ||
         ' locked=' || topics_locked,
         ' | ' order by subject_order
       ) as value
from public.learning_progress_summary;
rollback;

-- Starting a topic makes it the resume suggestion; finishing it moves the
-- suggestion to the next unlocked topic in the same subject.
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

insert into public.student_onboarding
  (user_id, current_step, experience_track, self_reported_grade_level, completed_at)
values (auth.uid(), 'ready', 'junior', 3, timezone('utc', now()))
on conflict (user_id) do update
set experience_track = 'junior', self_reported_grade_level = 3;

do $$
begin
  perform public.start_topic('40000000-0000-0000-0000-000000000001');
  perform public.record_playback_heartbeat(
    '40000000-0000-0000-0000-000000000001', 20
  );
end $$;

select 'started_topic_is_resume' as check,
       (select topic_title || '/' || reason
          from public.learning_next_up where rank = 1) as value;

reset role;
update public.learning_progress
set status = 'completed', progress = 1, watched_seconds = 120,
    completed_at = timezone('utc', now())
where user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
  and topic_version_id = '40000000-0000-0000-0000-000000000001';

set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

select 'finished_topic_is_gone' as check,
       (select topic_title || '/' || reason
          from public.learning_next_up where rank = 1) as value;

select 'completion_counted' as check,
       string_agg(
         subject_title || ':' || topics_completed || '/' || topics_total ||
         ' watched=' || watched_seconds,
         ' | ' order by subject_order
       ) as value
from public.learning_progress_summary;
rollback;

-- Two unfinished topics: the one touched most recently is offered first.
-- now() is frozen inside a transaction, so one row is pushed forward instead of
-- relying on write order.
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
  perform public.start_topic('40000000-0000-0000-0000-000000000003');
  perform public.record_playback_heartbeat(
    '40000000-0000-0000-0000-000000000003', 30
  );
  perform public.start_topic('40000000-0000-0000-0000-000000000006');
  perform public.record_playback_heartbeat(
    '40000000-0000-0000-0000-000000000006', 60
  );
end $$;

reset role;
update public.learning_progress
set last_heartbeat_at = timezone('utc', now()) + interval '1 hour'
where user_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
  and topic_version_id = '40000000-0000-0000-0000-000000000006';

set local role authenticated;
set local request.jwt.claims =
  '{"sub":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","role":"authenticated"}';

select 'most_recent_resume_first' as check,
       string_agg(topic_title || '/' || reason, ' | ' order by rank) as value
from public.learning_next_up;
rollback;

-- One learner's progress never reaches another learner's summary.
begin;
reset role;
insert into public.learning_progress
  (user_id, topic_version_id, status, progress, resume_seconds,
   watched_seconds, completed_at)
values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        '40000000-0000-0000-0000-000000000001', 'completed', 1, 120, 120,
        timezone('utc', now()))
on conflict (user_id, topic_version_id) do update
set status = 'completed', watched_seconds = 120;

set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

insert into public.student_onboarding
  (user_id, current_step, experience_track, self_reported_grade_level, completed_at)
values (auth.uid(), 'ready', 'junior', 3, timezone('utc', now()))
on conflict (user_id) do update
set experience_track = 'junior', self_reported_grade_level = 3;

select 'other_learner_rows_invisible' as check, count(*) as rows
from public.learning_progress
where user_id <> auth.uid();

select 'summary_ignores_other_learner' as check,
       string_agg(
         subject_title || ':' || topics_completed || ' done watched=' ||
         watched_seconds,
         ' | ' order by subject_order
       ) as value
from public.learning_progress_summary;

select 'still_suggested_to_me' as check,
       (select topic_title || '/' || reason
          from public.learning_next_up where rank = 1) as value;
rollback;

-- The views are read-only for learners.
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';
do $$
begin
  begin
    insert into public.learning_progress_summary (subject_id) values (gen_random_uuid());
    raise exception 'FAIL: summary accepted a write';
  exception when others then null;
  end;
end $$;
select 'summary_is_read_only' as check, true as ok;
rollback;
