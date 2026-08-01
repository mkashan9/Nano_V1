-- QZ-06 adversarial checks: explanations only after submit, owner-only results
-- and history, and progress written by the server rather than the client.
--
-- The seeded counting quiz has one item, so the wrong-answer path is the one
-- exercised here; a right answer is covered by the QZ-05 checks.

begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

do $$
declare
  v_start jsonb;
  v_id uuid;
  v_result jsonb;
  v_item jsonb;
  v_leaked boolean := false;
begin
  v_start := public.start_or_resume_quiz_attempt(
    '40000000-0000-0000-0000-000000000001'::uuid
  );
  v_id := (v_start->>'attempt_id')::uuid;

  -- Mid-quiz: results, correct answers, and explanations must be refused.
  begin
    perform public.get_attempt_result(v_id);
    v_leaked := true;
  exception when others then
    if sqlstate <> 'NQ030' then raise; end if;
  end;
  if v_leaked then
    raise exception 'FAIL: explanations released before submit';
  end if;

  -- 'a' is wrong for this question, so the review must say so.
  perform public.save_attempt_answer(
    v_id, '51000000-0000-0000-0000-000000000001'::uuid, 'a'
  );
  perform public.submit_quiz_attempt(v_id);

  v_result := public.get_attempt_result(v_id);
  v_item := v_result->'items'->0;

  if jsonb_array_length(v_result->'items') <> 1 then
    raise exception 'FAIL: unexpected review length %', v_result->'items';
  end if;
  if (v_item->>'was_correct')::boolean is not false then
    raise exception 'FAIL: wrong answer not marked wrong';
  end if;
  if (v_item->>'correct_option_id') <> 'b' then
    raise exception 'FAIL: review has no correct option to show';
  end if;
  if coalesce(v_item->>'explanation', '') = '' then
    raise exception 'FAIL: explanation missing after submit';
  end if;
  if (v_result->>'score_percent')::numeric <> 0
     or (v_result->>'passed')::boolean is not false then
    raise exception 'FAIL: unexpected outcome %', v_result;
  end if;

  -- No retake cap on this fixture, so a retake stays available.
  if (v_result->>'can_retake')::boolean is not true then
    raise exception 'FAIL: retake refused without a cap';
  end if;

  -- Server recorded the outcome; the client never wrote it.
  if not exists (
    select 1 from public.topic_quiz_progress
    where quiz_version_id = (v_result->>'quiz_version_id')::uuid
      and attempts_count = 1
      and last_score_percent = 0
      and passed = false
  ) then
    raise exception 'FAIL: topic_quiz_progress not recorded';
  end if;
end $$;
select 'results_after_submit_only' as check, true as ok;

-- Own history is visible.
select 'own_history_rows' as check, count(*) > 0 as ok
from public.learner_quiz_history;

-- A failed quiz keeps the topic in the recommendations as review work.
select 'review_quiz_reason' as check, count(*) > 0 as ok
from public.learning_next_up
where reason = 'review_quiz';

-- Client cannot write the outcome table itself.
do $$
begin
  begin
    insert into public.topic_quiz_progress (
      user_id, quiz_version_id, topic_version_id, passed
    ) values (
      'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid,
      '60000000-0000-0000-0000-000000000001'::uuid,
      '40000000-0000-0000-0000-000000000001'::uuid,
      true
    );
    raise exception 'FAIL: learner wrote topic_quiz_progress';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
  end;
end $$;
select 'learner_cannot_write_quiz_progress' as check, true as ok;
rollback;

-- Another learner sees neither the history nor the outcome rows.
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","role":"authenticated"}';
select 'other_learner_history' as check, count(*) as rows
from public.learner_quiz_history;
select 'other_learner_quiz_progress' as check, count(*) as rows
from public.topic_quiz_progress;
rollback;
