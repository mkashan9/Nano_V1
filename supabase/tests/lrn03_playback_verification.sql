-- LRN-03 adversarial checks: watch time is credited by the server, seeking
-- earns nothing, completion needs the threshold, and completion cannot be
-- duplicated. Counting to 20 is 120s at a 0.90 threshold, so 108s are required.

-- A client that jumps to the end earns nothing and cannot complete.
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
declare
  v_row public.learning_progress;
begin
  perform public.start_topic('40000000-0000-0000-0000-000000000001');

  -- First beat only anchors the position.
  v_row := public.record_playback_heartbeat(
    '40000000-0000-0000-0000-000000000001', 0
  );
  if v_row.watched_seconds <> 0 then
    raise exception 'FAIL: first heartbeat credited % seconds',
      v_row.watched_seconds;
  end if;

  -- Instant seek to the end: position moved, wall clock did not.
  v_row := public.record_playback_heartbeat(
    '40000000-0000-0000-0000-000000000001', 120
  );
  if v_row.watched_seconds > 2 then
    raise exception 'FAIL: seeking credited % seconds', v_row.watched_seconds;
  end if;
  if v_row.resume_seconds <> 120 then
    raise exception 'FAIL: resume position not saved';
  end if;

  begin
    perform public.complete_topic('40000000-0000-0000-0000-000000000001');
    raise exception 'FAIL: completed without credited watch time';
  exception
    when sqlstate 'NL005' then null;
    when others then
      if sqlerrm like 'Keep watching%' then null; else raise; end if;
  end;
end $$;

select 'seek_earns_nothing' as check, watched_seconds, resume_seconds, status
from public.learning_progress
where user_id = auth.uid()
  and topic_version_id = '40000000-0000-0000-0000-000000000001';
rollback;

-- A heartbeat can never credit more than wall-clock elapsed plus jitter.
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

do $$
begin
  perform public.start_topic('40000000-0000-0000-0000-000000000001');
  perform public.record_playback_heartbeat(
    '40000000-0000-0000-0000-000000000001', 0
  );
end $$;

-- Pretend the learner left the player open for a minute.
reset role;
update public.learning_progress
set last_heartbeat_at = timezone('utc', now()) - interval '60 seconds'
where user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
  and topic_version_id = '40000000-0000-0000-0000-000000000001';

set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

select 'credit_capped_by_elapsed' as check,
       (public.record_playback_heartbeat(
          '40000000-0000-0000-0000-000000000001', 120
        )).watched_seconds as watched_seconds;
rollback;

-- With enough credited time the learner completes once, and only once.
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

do $$
begin
  perform public.start_topic('40000000-0000-0000-0000-000000000001');
end $$;

reset role;
update public.learning_progress
set watched_seconds = 115, resume_seconds = 115
where user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
  and topic_version_id = '40000000-0000-0000-0000-000000000001';

set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

do $$
declare
  v_first public.learning_progress;
  v_second public.learning_progress;
begin
  v_first := public.complete_topic('40000000-0000-0000-0000-000000000001');
  if v_first.status <> 'completed' or v_first.completed_at is null then
    raise exception 'FAIL: threshold met but topic not completed';
  end if;

  v_second := public.complete_topic('40000000-0000-0000-0000-000000000001');
  if v_second.completed_at <> v_first.completed_at then
    raise exception 'FAIL: second completion rewrote the event';
  end if;

  -- No client write path into the completion ledger.
  begin
    insert into public.topic_completions
      (user_id, topic_version_id, watched_seconds, duration_seconds)
    values (auth.uid(), '40000000-0000-0000-0000-000000000002', 120, 120);
    raise exception 'FAIL: learner inserted a completion directly';
  exception when insufficient_privilege then null;
  end;
end $$;

select 'completion_rows' as check, count(*) as rows
from public.topic_completions
where user_id = auth.uid()
  and topic_version_id = '40000000-0000-0000-0000-000000000001';

-- Completing the prerequisite unlocks the next topic through the same helper.
select 'addition_is_locked' as check, is_locked
from public.learning_catalog
where topic_slug = 'addition';

-- Audit rows are invisible to learners by design, so verify them as the owner
-- of the audit trail. Two completion calls must leave exactly one row.
reset role;
select 'completion_audit_rows' as check, count(*) as rows
from public.audit_events
where target_type = 'topic_completion'
  and target_id = '40000000-0000-0000-0000-000000000001';
rollback;

-- Locked topics refuse playback writes as well.
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

do $$
begin
  begin
    perform public.record_playback_heartbeat(
      '40000000-0000-0000-0000-000000000002', 10
    );
    raise exception 'FAIL: heartbeat accepted for a locked topic';
  exception
    when sqlstate 'NL001' then null;
    when others then
      if sqlerrm like 'Finish % first' then null; else raise; end if;
  end;
end $$;

select 'locked_heartbeat_rejected' as check, true as ok;
rollback;
