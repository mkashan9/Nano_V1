-- QZ-05 adversarial checks: own-attempt isolation, idempotent submit,
-- learner cannot write score_results directly.

begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

do $$
declare
  v_start jsonb;
  v_id uuid;
  v_score jsonb;
  v_again jsonb;
begin
  v_start := public.start_or_resume_quiz_attempt(
    '40000000-0000-0000-0000-000000000001'::uuid
  );
  v_id := (v_start->>'attempt_id')::uuid;

  perform public.save_attempt_answer(
    v_id,
    '51000000-0000-0000-0000-000000000001'::uuid,
    'b'
  );

  -- Resume must keep the answer.
  if not exists (
    select 1 from public.attempt_answers
    where attempt_id = v_id
      and selected_option_id = 'b'
  ) then
    raise exception 'FAIL: answer not preserved';
  end if;

  v_score := public.submit_quiz_attempt(v_id);
  if (v_score->>'score_percent')::numeric <> 100 then
    raise exception 'FAIL: unexpected score %', v_score;
  end if;

  v_again := public.submit_quiz_attempt(v_id);
  if coalesce((v_again->>'idempotent')::boolean, false) is not true then
    raise exception 'FAIL: submit was not idempotent';
  end if;
  if (v_again->>'score_percent') <> (v_score->>'score_percent') then
    raise exception 'FAIL: idempotent score changed';
  end if;
end $$;
select 'learner_submit_ok' as check, true as ok;

-- Direct score insert must fail under RLS (no insert policy).
do $$
begin
  begin
    insert into public.score_results (
      attempt_id, score_percent, passed, correct_count, total_count
    ) values (
      gen_random_uuid(), 100, true, 1, 1
    );
    raise exception 'FAIL: learner wrote score_results';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
  end;
end $$;
select 'learner_cannot_write_scores' as check, true as ok;
rollback;

-- Another learner cannot see Ali's attempts.
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","role":"authenticated"}';
select 'other_learner_attempts' as check, count(*) as rows
from public.quiz_attempts;
rollback;
