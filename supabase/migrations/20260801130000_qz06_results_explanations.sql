-- QZ-06: quiz results, explanations, retake budget, and quiz-aware progress.
--
-- Explanations and correct answers are the one thing a learner must not see
-- before submitting, so they are released by an RPC that refuses to answer for
-- an attempt without a score row. The learner-facing quiz projection
-- (public.learner_quiz) still carries neither, which keeps the pre-submit path
-- safe even if a client asks for the wrong thing.

-- Per-learner outcome for one quiz version. Written only by submit.
create table if not exists public.topic_quiz_progress (
  user_id uuid not null references public.profiles (id) on delete cascade,
  quiz_version_id uuid not null references public.quiz_versions (id) on delete cascade,
  topic_version_id uuid not null references public.topic_versions (id) on delete cascade,
  attempts_count integer not null default 0 check (attempts_count >= 0),
  best_score_percent numeric(5,2) not null default 0
    check (best_score_percent >= 0 and best_score_percent <= 100),
  last_score_percent numeric(5,2) not null default 0
    check (last_score_percent >= 0 and last_score_percent <= 100),
  passed boolean not null default false,
  passed_at timestamptz,
  last_attempt_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, quiz_version_id)
);

comment on table public.topic_quiz_progress is
  'QZ-06 per-learner quiz outcome: attempts, best and last score, pass state. '
  'Written only by public.submit_quiz_attempt; learners read their own row.';

create index if not exists topic_quiz_progress_topic_idx
  on public.topic_quiz_progress (user_id, topic_version_id);

alter table public.topic_quiz_progress enable row level security;

drop policy if exists topic_quiz_progress_select_own on public.topic_quiz_progress;
create policy topic_quiz_progress_select_own on public.topic_quiz_progress
  for select to authenticated
  using (user_id = auth.uid() or nano_internal.is_platform_admin());

revoke insert, update, delete on public.topic_quiz_progress from authenticated;

drop trigger if exists topic_quiz_progress_set_updated_at
  on public.topic_quiz_progress;
create trigger topic_quiz_progress_set_updated_at
  before update on public.topic_quiz_progress
  for each row execute function public.set_updated_at();

-- One summary shape for submit and for a later result read, so a retake budget
-- shown after finishing cannot disagree with the one submit enforced.
create or replace function nano_internal.quiz_result_summary(p_attempt_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_attempt public.quiz_attempts;
  v_score public.score_results;
  v_policy public.quiz_policies;
  v_quiz public.quiz_versions;
  v_topic public.topic_versions;
  v_submitted integer;
  v_remaining integer;
begin
  select * into v_attempt from public.quiz_attempts where id = p_attempt_id;
  if v_attempt.id is null then
    return null;
  end if;

  select * into v_score from public.score_results where attempt_id = p_attempt_id;
  select * into v_policy
  from public.quiz_policies
  where quiz_version_id = v_attempt.quiz_version_id;
  select * into v_quiz
  from public.quiz_versions
  where id = v_attempt.quiz_version_id;
  select * into v_topic
  from public.topic_versions
  where id = v_attempt.topic_version_id;

  select count(*) into v_submitted
  from public.quiz_attempts
  where user_id = v_attempt.user_id
    and quiz_version_id = v_attempt.quiz_version_id
    and status = 'submitted';

  -- max_retakes counts retakes, so the total allowed sittings is one more.
  if v_policy.max_retakes is null then
    v_remaining := null;
  else
    v_remaining := greatest(v_policy.max_retakes + 1 - v_submitted, 0);
  end if;

  return jsonb_build_object(
    'attempt_id', v_attempt.id,
    'quiz_version_id', v_attempt.quiz_version_id,
    'topic_version_id', v_attempt.topic_version_id,
    'attempt_number', v_attempt.attempt_number,
    'quiz_title', v_quiz.title,
    'quiz_title_ur', v_quiz.title_ur,
    'topic_title', v_topic.title,
    'topic_title_ur', v_topic.title_ur,
    'pass_percent', coalesce(v_policy.pass_percent, 70),
    'score_percent', v_score.score_percent,
    'passed', v_score.passed,
    'correct_count', v_score.correct_count,
    'total_count', v_score.total_count,
    'scored_at', v_score.scored_at,
    'attempts_used', v_submitted,
    'max_retakes', v_policy.max_retakes,
    'retakes_remaining', v_remaining,
    'can_retake', v_policy.max_retakes is null or v_remaining > 0
  );
end;
$$;

revoke all on function nano_internal.quiz_result_summary(uuid) from public, anon;

-- Results, per-question review, and explanations. Submitted attempts only.
create or replace function public.get_attempt_result(p_attempt_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_uid uuid := auth.uid();
  v_attempt public.quiz_attempts;
  v_scored boolean;
  v_items jsonb;
begin
  if v_uid is null then
    raise exception using errcode = 'NQ001', message = 'Authentication required.';
  end if;

  select * into v_attempt
  from public.quiz_attempts
  where id = p_attempt_id;

  if v_attempt.id is null
     or (v_attempt.user_id <> v_uid and not nano_internal.is_platform_admin())
  then
    raise exception using errcode = 'NQ022', message = 'Attempt not found.';
  end if;

  select exists (
    select 1 from public.score_results where attempt_id = p_attempt_id
  ) into v_scored;

  if not v_scored then
    raise exception using
      errcode = 'NQ030',
      message = 'Results are available after the attempt is submitted.';
  end if;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'sort_order', qi.sort_order,
      'question_version_id', qn.id,
      'stem', qn.stem,
      'stem_ur', qn.stem_ur,
      'kind', qn.kind,
      'options', (
        select coalesce(jsonb_agg(
          jsonb_build_object(
            'id', opt->>'id',
            'label', opt->>'label',
            'label_ur', opt->>'label_ur'
          )
          order by ord
        ), '[]'::jsonb)
        from jsonb_array_elements(qn.options) with ordinality as t(opt, ord)
      ),
      'selected_option_id', aa.selected_option_id,
      'correct_option_id', (
        select opt->>'id'
        from jsonb_array_elements(qn.options) as t(opt)
        where coalesce((opt->>'is_correct')::boolean, false)
        limit 1
      ),
      'was_correct', case
        when aa.selected_option_id is null then false
        else nano_internal.option_is_correct(qn.options, aa.selected_option_id)
      end,
      'explanation', qn.explanation,
      'explanation_ur', qn.explanation_ur
    )
    order by qi.sort_order
  ), '[]'::jsonb)
  into v_items
  from public.quiz_items qi
  join public.question_versions qn on qn.id = qi.question_version_id
  left join public.attempt_answers aa
    on aa.attempt_id = p_attempt_id
   and aa.question_version_id = qn.id
  where qi.quiz_version_id = v_attempt.quiz_version_id;

  return nano_internal.quiz_result_summary(p_attempt_id)
    || jsonb_build_object('items', v_items);
end;
$$;

comment on function public.get_attempt_result is
  'QZ-06 returns the server score plus per-question review and explanations '
  'for a submitted attempt. Raises NQ030 while the attempt is still open, so '
  'correct answers cannot be read mid-quiz.';

revoke all on function public.get_attempt_result(uuid) from public, anon;
grant execute on function public.get_attempt_result(uuid)
  to authenticated, service_role;

-- Attempt history. Definer, because learners cannot read quiz_versions
-- directly; the owner filter below is the whole access rule.
create or replace view public.learner_quiz_history
with (security_invoker = false)
as
select
  a.id as attempt_id,
  a.user_id,
  a.quiz_version_id,
  a.topic_version_id,
  a.attempt_number,
  a.status,
  a.started_at,
  a.submitted_at,
  qv.title as quiz_title,
  qv.title_ur as quiz_title_ur,
  tv.title as topic_title,
  tv.title_ur as topic_title_ur,
  sr.score_percent,
  sr.passed,
  sr.correct_count,
  sr.total_count,
  sr.scored_at
from public.quiz_attempts a
join public.quiz_versions qv on qv.id = a.quiz_version_id
join public.topic_versions tv on tv.id = a.topic_version_id
left join public.score_results sr on sr.attempt_id = a.id
where a.user_id = auth.uid() or nano_internal.is_platform_admin();

comment on view public.learner_quiz_history is
  'QZ-06 attempt history for the calling learner: attempt number, score, and '
  'pass state. Definer view filtered to the caller''s own attempts.';

grant select on public.learner_quiz_history to authenticated, service_role;

-- Submit now also records the outcome and returns the retake budget.
create or replace function public.submit_quiz_attempt(p_attempt_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_uid uuid := auth.uid();
  v_attempt public.quiz_attempts;
  v_policy public.quiz_policies;
  v_existing public.score_results;
  v_total integer;
  v_answered integer;
  v_correct integer := 0;
  v_percent numeric(5,2);
  v_passed boolean;
  v_row public.score_results;
  r record;
begin
  if v_uid is null then
    raise exception using errcode = 'NQ001', message = 'Authentication required.';
  end if;

  select * into v_attempt
  from public.quiz_attempts
  where id = p_attempt_id;

  if v_attempt.id is null or v_attempt.user_id <> v_uid then
    raise exception using errcode = 'NQ022', message = 'Attempt not found.';
  end if;

  select * into v_existing
  from public.score_results
  where attempt_id = p_attempt_id;

  if v_existing.attempt_id is not null then
    return nano_internal.quiz_result_summary(p_attempt_id)
      || jsonb_build_object('idempotent', true);
  end if;

  if v_attempt.status <> 'in_progress' then
    raise exception using
      errcode = 'NQ027',
      message = 'Attempt is not open for submit.';
  end if;

  select * into v_policy
  from public.quiz_policies
  where quiz_version_id = v_attempt.quiz_version_id;

  select count(*) into v_total
  from public.quiz_items
  where quiz_version_id = v_attempt.quiz_version_id;

  select count(*) into v_answered
  from public.attempt_answers
  where attempt_id = p_attempt_id;

  if v_answered < v_total then
    raise exception using
      errcode = 'NQ028',
      message = 'Answer every question before submitting.';
  end if;

  for r in
    select qi.question_version_id, aa.selected_option_id, qv.options
    from public.quiz_items qi
    join public.attempt_answers aa
      on aa.attempt_id = p_attempt_id
     and aa.question_version_id = qi.question_version_id
    join public.question_versions qv on qv.id = qi.question_version_id
    where qi.quiz_version_id = v_attempt.quiz_version_id
  loop
    if nano_internal.option_is_correct(r.options, r.selected_option_id) then
      v_correct := v_correct + 1;
    end if;
  end loop;

  v_percent := round((v_correct::numeric / v_total::numeric) * 100, 2);
  v_passed := v_percent >= coalesce(v_policy.pass_percent, 70);

  update public.quiz_attempts
  set status = 'submitted',
      submitted_at = timezone('utc', now())
  where id = p_attempt_id;

  insert into public.score_results (
    attempt_id, score_percent, passed, correct_count, total_count, scored_at
  ) values (
    p_attempt_id, v_percent, v_passed, v_correct, v_total, timezone('utc', now())
  )
  returning * into v_row;

  insert into public.topic_quiz_progress as tqp (
    user_id, quiz_version_id, topic_version_id, attempts_count,
    best_score_percent, last_score_percent, passed, passed_at, last_attempt_at
  ) values (
    v_uid, v_attempt.quiz_version_id, v_attempt.topic_version_id, 1,
    v_row.score_percent, v_row.score_percent, v_row.passed,
    case when v_row.passed then v_row.scored_at end,
    v_row.scored_at
  )
  on conflict (user_id, quiz_version_id) do update
  set attempts_count = tqp.attempts_count + 1,
      best_score_percent =
        greatest(tqp.best_score_percent, excluded.best_score_percent),
      last_score_percent = excluded.last_score_percent,
      passed = tqp.passed or excluded.passed,
      passed_at = coalesce(tqp.passed_at, excluded.passed_at),
      last_attempt_at = excluded.last_attempt_at;

  insert into public.attempt_events (attempt_id, event_kind, payload)
  values (
    p_attempt_id,
    'submitted',
    jsonb_build_object(
      'score_percent', v_row.score_percent,
      'passed', v_row.passed
    )
  );

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    v_uid, 'student', 'update', 'quiz_attempt', p_attempt_id::text,
    jsonb_build_object(
      'status', 'submitted',
      'score_percent', v_row.score_percent,
      'passed', v_row.passed
    )
  );

  return nano_internal.quiz_result_summary(p_attempt_id)
    || jsonb_build_object('idempotent', false);
end;
$$;

comment on function public.submit_quiz_attempt(uuid) is
  'QZ-05/QZ-06 scores an attempt on the server, records the outcome in '
  'topic_quiz_progress, and returns the score with the retake budget. '
  'Duplicate calls return the same result.';

revoke all on function public.submit_quiz_attempt(uuid) from public, anon;
grant execute on function public.submit_quiz_attempt(uuid)
  to authenticated, service_role;

-- Recommendations become quiz-aware: a topic whose quiz has not been passed
-- comes back as review work instead of disappearing once the video is done.
drop view if exists public.learning_next_up;
create view public.learning_next_up with (security_invoker = true) as
with visible as (
  select * from public.learning_catalog
),
quiz_state as (
  select
    tqp.topic_version_id,
    tqp.passed,
    tqp.attempts_count,
    tqp.best_score_percent
  from public.topic_quiz_progress tqp
  where tqp.user_id = auth.uid()
),
subject_state as (
  select
    subject_id,
    max(last_activity_at) as subject_last_activity_at,
    count(*) filter (where progress_status <> 'not_started') as touched
  from visible
  group by subject_id
),
candidates as (
  select
    v.subject_id,
    v.subject_slug,
    v.subject_order,
    v.subject_title,
    v.subject_title_ur,
    v.world_color_hex,
    v.topic_id,
    v.topic_slug,
    v.topic_order,
    v.topic_version_id,
    v.topic_title,
    v.topic_title_ur,
    v.estimated_minutes,
    v.duration_seconds,
    v.watched_seconds,
    v.resume_seconds,
    v.progress,
    v.progress_status,
    v.last_activity_at,
    ss.subject_last_activity_at,
    coalesce(qs.attempts_count, 0) > 0 as quiz_attempted,
    coalesce(qs.passed, false) as quiz_passed,
    coalesce(qs.best_score_percent, 0) as best_score_percent,
    case
      when v.progress_status = 'in_progress' then 'resume'
      when qs.topic_version_id is not null and not qs.passed then 'review_quiz'
      when coalesce(ss.touched, 0) > 0 then 'next_in_subject'
      else 'new_subject'
    end as reason
  from visible v
  join subject_state ss on ss.subject_id = v.subject_id
  left join quiz_state qs on qs.topic_version_id = v.topic_version_id
  where not v.is_locked
    and (
      v.progress_status <> 'completed'
      or (qs.topic_version_id is not null and not qs.passed)
    )
)
select
  c.*,
  row_number() over (
    order by
      case c.reason
        when 'resume' then 1
        when 'review_quiz' then 2
        when 'next_in_subject' then 3
        else 4
      end,
      c.last_activity_at desc nulls last,
      c.subject_last_activity_at desc nulls last,
      c.subject_order,
      c.topic_order
  )::integer as rank
from candidates c;

comment on view public.learning_next_up is
  'LRN-05/QZ-06 ranked next-up suggestions for the calling learner with a '
  'reason. Built on learning_catalog, so a suggestion can only name a topic '
  'the learner may already open. A failed or unpassed quiz keeps the topic in '
  'the list as review_quiz.';

grant select on public.learning_next_up to authenticated, service_role;

update public.app_health
set schema_version = 'QZ-06',
    notes = 'Quiz results with explanations, retake budget, quiz-aware next up',
    updated_at = timezone('utc', now())
where id = 'default';
