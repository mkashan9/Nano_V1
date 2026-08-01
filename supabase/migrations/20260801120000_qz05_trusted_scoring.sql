-- QZ-05: trusted quiz attempts, answer persistence, and server-side scoring.
-- Clients never write score_results. Submit is idempotent.

create table if not exists public.quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  quiz_version_id uuid not null references public.quiz_versions (id),
  topic_version_id uuid not null references public.topic_versions (id),
  status text not null default 'in_progress'
    check (status in ('in_progress', 'submitted')),
  attempt_number integer not null check (attempt_number >= 1),
  started_at timestamptz not null default timezone('utc', now()),
  submitted_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (user_id, quiz_version_id, attempt_number)
);

comment on table public.quiz_attempts is
  'QZ-05 learner attempt against an immutable quiz_version. One in_progress '
  'row per learner+quiz; submitted rows keep history for retakes.';

create table if not exists public.attempt_answers (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.quiz_attempts (id) on delete cascade,
  question_version_id uuid not null references public.question_versions (id),
  selected_option_id text not null check (char_length(btrim(selected_option_id)) > 0),
  answered_at timestamptz not null default timezone('utc', now()),
  unique (attempt_id, question_version_id)
);

comment on table public.attempt_answers is
  'QZ-05 selected option ids for an attempt. Correctness is never stored here.';

create table if not exists public.attempt_events (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.quiz_attempts (id) on delete cascade,
  event_kind text not null
    check (event_kind in ('started', 'resumed', 'answer_saved', 'submitted')),
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.score_results (
  attempt_id uuid primary key references public.quiz_attempts (id) on delete cascade,
  score_percent numeric(5,2) not null
    check (score_percent >= 0 and score_percent <= 100),
  passed boolean not null,
  correct_count integer not null check (correct_count >= 0),
  total_count integer not null check (total_count > 0),
  scored_at timestamptz not null default timezone('utc', now())
);

comment on table public.score_results is
  'QZ-05 server-authored score for a submitted attempt. RPC-only writes.';

create table if not exists public.suspicious_attempt_flags (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.quiz_attempts (id) on delete cascade,
  flag_kind text not null,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists quiz_attempts_one_open_idx
  on public.quiz_attempts (user_id, quiz_version_id)
  where status = 'in_progress';

create index if not exists quiz_attempts_user_idx
  on public.quiz_attempts (user_id, started_at desc);
create index if not exists attempt_answers_attempt_idx
  on public.attempt_answers (attempt_id);
create index if not exists attempt_events_attempt_idx
  on public.attempt_events (attempt_id, created_at);

drop trigger if exists quiz_attempts_set_updated_at on public.quiz_attempts;
create trigger quiz_attempts_set_updated_at
  before update on public.quiz_attempts
  for each row execute function public.set_updated_at();

alter table public.quiz_attempts enable row level security;
alter table public.attempt_answers enable row level security;
alter table public.attempt_events enable row level security;
alter table public.score_results enable row level security;
alter table public.suspicious_attempt_flags enable row level security;

drop policy if exists quiz_attempts_select_own on public.quiz_attempts;
create policy quiz_attempts_select_own on public.quiz_attempts
  for select to authenticated
  using (user_id = auth.uid() or nano_internal.is_platform_admin());

drop policy if exists attempt_answers_select_own on public.attempt_answers;
create policy attempt_answers_select_own on public.attempt_answers
  for select to authenticated
  using (
    exists (
      select 1 from public.quiz_attempts a
      where a.id = attempt_id
        and (a.user_id = auth.uid() or nano_internal.is_platform_admin())
    )
  );

drop policy if exists attempt_events_select_own on public.attempt_events;
create policy attempt_events_select_own on public.attempt_events
  for select to authenticated
  using (
    exists (
      select 1 from public.quiz_attempts a
      where a.id = attempt_id
        and (a.user_id = auth.uid() or nano_internal.is_platform_admin())
    )
  );

drop policy if exists score_results_select_own on public.score_results;
create policy score_results_select_own on public.score_results
  for select to authenticated
  using (
    exists (
      select 1 from public.quiz_attempts a
      where a.id = attempt_id
        and (a.user_id = auth.uid() or nano_internal.is_platform_admin())
    )
  );

drop policy if exists suspicious_flags_select_admin on public.suspicious_attempt_flags;
create policy suspicious_flags_select_admin on public.suspicious_attempt_flags
  for select to authenticated
  using (nano_internal.is_platform_admin());

-- No direct inserts/updates/deletes for learners; RPCs are security definer.

create or replace function nano_internal.option_is_correct(
  p_options jsonb,
  p_option_id text
)
returns boolean
language sql
immutable
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from jsonb_array_elements(coalesce(p_options, '[]'::jsonb)) opt
    where opt->>'id' = p_option_id
      and coalesce((opt->>'is_correct')::boolean, false)
  );
$$;

revoke all on function nano_internal.option_is_correct(jsonb, text)
  from public, anon;

create or replace function public.start_or_resume_quiz_attempt(
  p_topic_version_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_uid uuid := auth.uid();
  v_quiz public.quiz_versions;
  v_policy public.quiz_policies;
  v_attempt public.quiz_attempts;
  v_submitted integer;
  v_answers jsonb;
begin
  if v_uid is null then
    raise exception using errcode = 'NQ001', message = 'Authentication required.';
  end if;

  select * into v_quiz
  from public.quiz_versions
  where topic_version_id = p_topic_version_id
    and status = 'published'
  limit 1;

  if v_quiz.id is null then
    raise exception using
      errcode = 'NQ020',
      message = 'No published quiz for this topic.';
  end if;

  select * into v_policy
  from public.quiz_policies
  where quiz_version_id = v_quiz.id;

  select * into v_attempt
  from public.quiz_attempts
  where user_id = v_uid
    and quiz_version_id = v_quiz.id
    and status = 'in_progress'
  limit 1;

  if v_attempt.id is not null then
    insert into public.attempt_events (attempt_id, event_kind, payload)
    values (v_attempt.id, 'resumed', '{}'::jsonb);

    select coalesce(jsonb_agg(jsonb_build_object(
      'question_version_id', aa.question_version_id,
      'selected_option_id', aa.selected_option_id,
      'answered_at', aa.answered_at
    ) order by aa.answered_at), '[]'::jsonb)
    into v_answers
    from public.attempt_answers aa
    where aa.attempt_id = v_attempt.id;

    return jsonb_build_object(
      'attempt_id', v_attempt.id,
      'quiz_version_id', v_quiz.id,
      'topic_version_id', v_quiz.topic_version_id,
      'status', v_attempt.status,
      'attempt_number', v_attempt.attempt_number,
      'resumed', true,
      'answers', v_answers
    );
  end if;

  select count(*) into v_submitted
  from public.quiz_attempts
  where user_id = v_uid
    and quiz_version_id = v_quiz.id
    and status = 'submitted';

  if v_policy.max_retakes is not null
     and v_submitted > v_policy.max_retakes then
    raise exception using
      errcode = 'NQ021',
      message = 'No retakes remaining for this quiz.';
  end if;

  insert into public.quiz_attempts (
    user_id, quiz_version_id, topic_version_id, status, attempt_number
  ) values (
    v_uid, v_quiz.id, v_quiz.topic_version_id, 'in_progress', v_submitted + 1
  )
  returning * into v_attempt;

  insert into public.attempt_events (attempt_id, event_kind, payload)
  values (
    v_attempt.id,
    'started',
    jsonb_build_object('attempt_number', v_attempt.attempt_number)
  );

  return jsonb_build_object(
    'attempt_id', v_attempt.id,
    'quiz_version_id', v_quiz.id,
    'topic_version_id', v_quiz.topic_version_id,
    'status', v_attempt.status,
    'attempt_number', v_attempt.attempt_number,
    'resumed', false,
    'answers', '[]'::jsonb
  );
end;
$$;

comment on function public.start_or_resume_quiz_attempt(uuid) is
  'QZ-05 opens or resumes an in-progress attempt for the published quiz on a topic.';

revoke all on function public.start_or_resume_quiz_attempt(uuid)
  from public, anon;
grant execute on function public.start_or_resume_quiz_attempt(uuid)
  to authenticated, service_role;

create or replace function public.save_attempt_answer(
  p_attempt_id uuid,
  p_question_version_id uuid,
  p_selected_option_id text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_uid uuid := auth.uid();
  v_attempt public.quiz_attempts;
  v_item public.quiz_items;
  v_qv public.question_versions;
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
  if v_attempt.status <> 'in_progress' then
    raise exception using
      errcode = 'NQ023',
      message = 'Submitted attempts cannot accept answers.';
  end if;

  select * into v_item
  from public.quiz_items
  where quiz_version_id = v_attempt.quiz_version_id
    and question_version_id = p_question_version_id;

  if v_item.id is null then
    raise exception using
      errcode = 'NQ024',
      message = 'Question is not part of this quiz.';
  end if;

  select * into v_qv from public.question_versions where id = p_question_version_id;
  if v_qv.id is null or v_qv.status <> 'published' then
    raise exception using
      errcode = 'NQ025',
      message = 'Question version is not published.';
  end if;

  if not exists (
    select 1
    from jsonb_array_elements(v_qv.options) opt
    where opt->>'id' = p_selected_option_id
  ) then
    raise exception using
      errcode = 'NQ026',
      message = 'Selected option is not on this question.';
  end if;

  insert into public.attempt_answers (
    attempt_id, question_version_id, selected_option_id, answered_at
  ) values (
    p_attempt_id, p_question_version_id, p_selected_option_id, timezone('utc', now())
  )
  on conflict (attempt_id, question_version_id) do update
    set selected_option_id = excluded.selected_option_id,
        answered_at = excluded.answered_at;

  insert into public.attempt_events (attempt_id, event_kind, payload)
  values (
    p_attempt_id,
    'answer_saved',
    jsonb_build_object(
      'question_version_id', p_question_version_id,
      'selected_option_id', p_selected_option_id
    )
  );

  return jsonb_build_object(
    'attempt_id', p_attempt_id,
    'question_version_id', p_question_version_id,
    'selected_option_id', p_selected_option_id
  );
end;
$$;

revoke all on function public.save_attempt_answer(uuid, uuid, text)
  from public, anon;
grant execute on function public.save_attempt_answer(uuid, uuid, text)
  to authenticated, service_role;

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
    return jsonb_build_object(
      'attempt_id', v_existing.attempt_id,
      'score_percent', v_existing.score_percent,
      'passed', v_existing.passed,
      'correct_count', v_existing.correct_count,
      'total_count', v_existing.total_count,
      'scored_at', v_existing.scored_at,
      'idempotent', true
    );
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

  return jsonb_build_object(
    'attempt_id', v_row.attempt_id,
    'score_percent', v_row.score_percent,
    'passed', v_row.passed,
    'correct_count', v_row.correct_count,
    'total_count', v_row.total_count,
    'scored_at', v_row.scored_at,
    'idempotent', false
  );
end;
$$;

comment on function public.submit_quiz_attempt(uuid) is
  'QZ-05 scores an attempt on the server. Duplicate calls return the same result.';

revoke all on function public.submit_quiz_attempt(uuid) from public, anon;
grant execute on function public.submit_quiz_attempt(uuid)
  to authenticated, service_role;

update public.app_health
set schema_version = 'QZ-05',
    notes = 'Trusted quiz attempts, answer save, idempotent server scoring',
    updated_at = timezone('utc', now())
where id = 'default';
