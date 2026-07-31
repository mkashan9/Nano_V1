-- LRN-02 adversarial checks: prerequisite shape, write refusals, RPC-only
-- progress, and shared lock helper.

-- Shape and ordering are service-role curator rules.
begin;

do $$
begin
  begin
    insert into public.topic_prerequisites (topic_id, requires_topic_id)
    values (
      '30000000-0000-0000-0000-000000000002',
      '30000000-0000-0000-0000-000000000003'
    );
    raise exception 'FAIL: cross-subject prerequisite accepted';
  exception
    when sqlstate 'NL004' then null;
    when others then
      if sqlerrm like '%stay inside one subject%' then null;
      else raise;
      end if;
  end;

  begin
    insert into public.topic_prerequisites (topic_id, requires_topic_id)
    values (
      '30000000-0000-0000-0000-000000000001',
      '30000000-0000-0000-0000-000000000002'
    );
    raise exception 'FAIL: cyclic prerequisite accepted';
  exception
    when sqlstate 'NL004' then null;
    when others then
      if sqlerrm like '%must not form a cycle%' then null;
      else raise;
      end if;
  end;

  begin
    insert into public.topics (id, subject_id, slug, sort_order)
    values (
      '30000000-0000-0000-0000-000000000099',
      '10000000-0000-0000-0000-000000000001',
      'dup-order', 1
    );
    raise exception 'FAIL: duplicate subject order accepted';
  exception when unique_violation then null;
  end;
end $$;

select 'shape_and_order_ok' as check, true as ok;
rollback;

-- Ali as junior: locked write refused, unlocked write allowed, completion
-- unreachable from the client, direct table writes gone.
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

insert into public.student_onboarding
  (user_id, current_step, experience_track, self_reported_grade_level, completed_at)
values (auth.uid(), 'ready', 'junior', 3, timezone('utc', now()))
on conflict (user_id) do update
set experience_track = 'junior',
    self_reported_grade_level = 3,
    completed_at = coalesce(public.student_onboarding.completed_at, excluded.completed_at);

select 'junior_addition_locked' as check,
       is_locked::text,
       coalesce(array_to_string(blocking_titles, ','), '') as blocking
from public.learning_catalog
where topic_slug = 'addition';

do $$
declare
  v_row public.learning_progress;
  v_second public.learning_progress;
begin
  begin
    perform public.start_topic('40000000-0000-0000-0000-000000000002');
    raise exception 'FAIL: started a locked topic';
  exception
    when sqlstate 'NL001' then null;
    when others then
      if sqlerrm like 'Finish % first' then null;
      else raise;
      end if;
  end;

  v_row := public.start_topic('40000000-0000-0000-0000-000000000001');
  if v_row.status <> 'in_progress' then
    raise exception 'FAIL: start_topic did not open Counting';
  end if;

  v_second := public.start_topic('40000000-0000-0000-0000-000000000001');
  if v_second.status <> 'in_progress' then
    raise exception 'FAIL: start_topic is not idempotent';
  end if;

  -- LRN-03 replaced save_topic_progress with record_playback_heartbeat, so the
  -- LRN-02 invariants are checked through the current write path: the resume
  -- position is stored and the client still cannot mark a topic completed.
  v_row := public.record_playback_heartbeat(
    '40000000-0000-0000-0000-000000000001', 45
  );
  if v_row.resume_seconds <> 45 then
    raise exception 'FAIL: heartbeat did not store the resume position';
  end if;

  v_row := public.record_playback_heartbeat(
    '40000000-0000-0000-0000-000000000001', 120
  );
  if v_row.status <> 'in_progress' or v_row.completed_at is not null then
    raise exception 'FAIL: client was able to mark a topic completed';
  end if;

  begin
    insert into public.learning_progress
      (user_id, topic_version_id, status, progress, resume_seconds)
    values (
      auth.uid(),
      '40000000-0000-0000-0000-000000000002',
      'completed', 1, 0
    );
    raise exception 'FAIL: direct learning_progress write accepted';
  exception when insufficient_privilege then null;
  end;

  begin
    perform public.start_topic('40000000-0000-0000-0000-000000000004');
    raise exception 'FAIL: started a draft topic';
  exception
    when sqlstate 'NL002' then null;
    when others then
      if sqlerrm like 'This topic is not available%' then null;
      else raise;
      end if;
  end;
end $$;

select 'junior_gates_ok' as check, true as ok;
select 'junior_counting_progress' as check, status, resume_seconds, progress::text
from public.learning_progress
where user_id = auth.uid()
  and topic_version_id = '40000000-0000-0000-0000-000000000001';
rollback;

-- Bina as senior: Plants and animals is locked and ordered after Living things.
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","role":"authenticated"}';

insert into public.student_onboarding
  (user_id, current_step, experience_track, self_reported_grade_level, completed_at)
values (auth.uid(), 'ready', 'senior', 8, timezone('utc', now()))
on conflict (user_id) do update
set experience_track = 'senior',
    self_reported_grade_level = 8,
    completed_at = coalesce(public.student_onboarding.completed_at, excluded.completed_at);

select 'senior_science_order' as check, topic_slug, topic_order, is_locked
from public.learning_catalog
where subject_slug = 'science'
order by topic_order;

do $$
begin
  begin
    perform public.start_topic('40000000-0000-0000-0000-000000000005');
    raise exception 'FAIL: started Plants and animals while locked';
  exception
    when sqlstate 'NL001' then null;
    when others then
      if sqlerrm like 'Finish % first' then null;
      else raise;
      end if;
  end;
end $$;

select 'senior_gates_ok' as check, true as ok;
rollback;

-- A teacher cannot open a student topic.
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"cccccccc-cccc-cccc-cccc-cccccccccccc","role":"authenticated"}';

do $$
begin
  begin
    perform public.start_topic('40000000-0000-0000-0000-000000000001');
    raise exception 'FAIL: teacher started a topic';
  exception
    when sqlstate 'NL003' then null;
    when others then
      if sqlerrm like 'Only an active learner%' then null;
      else raise;
      end if;
  end;
end $$;

select 'teacher_gates_ok' as check, true as ok;
rollback;
