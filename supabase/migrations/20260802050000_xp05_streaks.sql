-- XP-05: streaks with gentle pause messaging.
--
-- A UTC calendar day with a topic completion or quiz pass extends the streak.
-- Missing a day pauses it; the next activity restarts at 1 with a welcome-back
-- notice. Clients never write this table.

create table if not exists public.streaks (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  current_count integer not null default 0 check (current_count >= 0),
  longest_count integer not null default 0 check (longest_count >= 0),
  last_active_on date,
  pending_notice text
    check (pending_notice is null or pending_notice in ('welcome_back')),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.streaks is
  'XP-05 consecutive learning days. touch_streak is the only writer.';

alter table public.streaks enable row level security;

drop policy if exists streaks_select_own on public.streaks;
create policy streaks_select_own on public.streaks
  for select to authenticated
  using (user_id = auth.uid());

revoke all on table public.streaks from public, anon, authenticated;
grant select on table public.streaks to authenticated, service_role;

create or replace function nano_internal.touch_streak(p_user_id uuid)
returns public.streaks
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_today date := (timezone('utc', now()))::date;
  v_row public.streaks;
  v_prev integer;
begin
  if p_user_id is null then
    raise exception using errcode = 'NX001', message = 'A learner is required.';
  end if;

  select * into v_row from public.streaks where user_id = p_user_id;

  if v_row.user_id is null then
    insert into public.streaks
      (user_id, current_count, longest_count, last_active_on, pending_notice, updated_at)
    values (p_user_id, 1, 1, v_today, null, timezone('utc', now()))
    returning * into v_row;
    return v_row;
  end if;

  -- Already counted today.
  if v_row.last_active_on = v_today then
    return v_row;
  end if;

  -- Consecutive day.
  if v_row.last_active_on = v_today - 1 then
    update public.streaks
    set current_count = v_row.current_count + 1,
        longest_count = greatest(v_row.longest_count, v_row.current_count + 1),
        last_active_on = v_today,
        pending_notice = null,
        updated_at = timezone('utc', now())
    where user_id = p_user_id
    returning * into v_row;
    return v_row;
  end if;

  -- Gap: pause gently and start again at 1.
  v_prev := v_row.current_count;
  update public.streaks
  set current_count = 1,
      longest_count = greatest(v_row.longest_count, v_prev, 1),
      last_active_on = v_today,
      pending_notice = case when v_prev > 0 then 'welcome_back' else null end,
      updated_at = timezone('utc', now())
  where user_id = p_user_id
  returning * into v_row;

  return v_row;
end;
$$;

revoke all on function nano_internal.touch_streak(uuid)
  from public, anon, authenticated;
grant execute on function nano_internal.touch_streak(uuid) to service_role;

create or replace function public.my_streak()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_uid uuid := auth.uid();
  v_today date := (timezone('utc', now()))::date;
  v_row public.streaks;
  v_status text;
  v_notice text;
  v_msg_en text := '';
  v_msg_ur text := '';
begin
  if v_uid is null then
    raise exception using errcode = 'NX010', message = 'Authentication required.';
  end if;

  select * into v_row from public.streaks where user_id = v_uid;

  if v_row.user_id is null then
    return jsonb_build_object(
      'current', 0,
      'longest', 0,
      'last_active_on', null,
      'status', 'fresh',
      'notice', null,
      'message_en', '',
      'message_ur', ''
    );
  end if;

  -- Soft-pause on read if the last active day is older than yesterday.
  if v_row.last_active_on is not null
     and v_row.last_active_on < v_today - 1
     and v_row.current_count > 0 then
    update public.streaks
    set current_count = 0,
        pending_notice = 'welcome_back',
        updated_at = timezone('utc', now())
    where user_id = v_uid
    returning * into v_row;
  end if;

  v_notice := v_row.pending_notice;
  if v_notice = 'welcome_back' then
    v_msg_en :=
      'Welcome back. Rest is part of learning — a new streak starts when you are ready.';
    v_msg_ur :=
      'خوش آمدید۔ آرام سیکھنے کا حصہ ہے — نیا سلسلہ تب شروع ہوگا جب آپ تیار ہوں۔';
    -- One-shot: clear after the learner has been told.
    update public.streaks
    set pending_notice = null, updated_at = timezone('utc', now())
    where user_id = v_uid and pending_notice = 'welcome_back';
  end if;

  if v_row.last_active_on = v_today or v_row.last_active_on = v_today - 1 then
    v_status := 'active';
  elsif v_row.current_count = 0 then
    v_status := 'paused';
  else
    v_status := 'fresh';
  end if;

  return jsonb_build_object(
    'current', v_row.current_count,
    'longest', v_row.longest_count,
    'last_active_on', v_row.last_active_on,
    'status', v_status,
    'notice', v_notice,
    'message_en', v_msg_en,
    'message_ur', v_msg_ur
  );
end;
$$;

revoke all on function public.my_streak() from public, anon;
grant execute on function public.my_streak() to authenticated, service_role;

-- Extend complete_topic / submit_quiz_attempt to touch the streak.
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

  if v_row.status = 'completed' then
    perform nano_internal.award_xp(
      auth.uid(), 'video_completion', p_topic_version_id::text
    );
    perform nano_internal.evaluate_achievements(auth.uid());
    perform nano_internal.evaluate_missions(auth.uid());
    perform nano_internal.touch_streak(auth.uid());
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

  perform nano_internal.award_xp(
    auth.uid(), 'video_completion', p_topic_version_id::text
  );

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

  perform nano_internal.evaluate_achievements(auth.uid());
  perform nano_internal.evaluate_missions(auth.uid());
  perform nano_internal.touch_streak(auth.uid());

  return v_row;
end;
$$;

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

  select * into v_attempt from public.quiz_attempts where id = p_attempt_id;
  if v_attempt.id is null or v_attempt.user_id <> v_uid then
    raise exception using errcode = 'NQ022', message = 'Attempt not found.';
  end if;

  select * into v_existing from public.score_results where attempt_id = p_attempt_id;
  if v_existing.attempt_id is not null then
    perform nano_internal.evaluate_achievements(v_uid);
    perform nano_internal.evaluate_missions(v_uid);
    if v_existing.passed then
      perform nano_internal.touch_streak(v_uid);
    end if;
    return nano_internal.quiz_result_summary(p_attempt_id)
      || jsonb_build_object('idempotent', true);
  end if;

  if v_attempt.status <> 'in_progress' then
    raise exception using errcode = 'NQ027',
      message = 'Attempt is not open for submit.';
  end if;

  select * into v_policy from public.quiz_policies
  where quiz_version_id = v_attempt.quiz_version_id;

  select count(*) into v_total from public.quiz_items
  where quiz_version_id = v_attempt.quiz_version_id;
  select count(*) into v_answered from public.attempt_answers
  where attempt_id = p_attempt_id;
  if v_answered < v_total then
    raise exception using errcode = 'NQ028',
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
  set status = 'submitted', submitted_at = timezone('utc', now())
  where id = p_attempt_id;

  insert into public.score_results (
    attempt_id, score_percent, passed, correct_count, total_count, scored_at
  ) values (
    p_attempt_id, v_percent, v_passed, v_correct, v_total, timezone('utc', now())
  ) returning * into v_row;

  insert into public.topic_quiz_progress as tqp (
    user_id, quiz_version_id, topic_version_id, attempts_count,
    best_score_percent, last_score_percent, passed, passed_at, last_attempt_at
  ) values (
    v_uid, v_attempt.quiz_version_id, v_attempt.topic_version_id, 1,
    v_row.score_percent, v_row.score_percent, v_row.passed,
    case when v_row.passed then v_row.scored_at end, v_row.scored_at
  )
  on conflict (user_id, quiz_version_id) do update
  set attempts_count = tqp.attempts_count + 1,
      best_score_percent = greatest(tqp.best_score_percent, excluded.best_score_percent),
      last_score_percent = excluded.last_score_percent,
      passed = tqp.passed or excluded.passed,
      passed_at = coalesce(tqp.passed_at, excluded.passed_at),
      last_attempt_at = excluded.last_attempt_at;

  insert into public.attempt_events (attempt_id, event_kind, payload)
  values (
    p_attempt_id, 'submitted',
    jsonb_build_object('score_percent', v_row.score_percent, 'passed', v_row.passed)
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

  if v_row.passed then
    perform nano_internal.award_xp(
      v_uid, 'quiz_pass', v_attempt.quiz_version_id::text
    );
    perform nano_internal.touch_streak(v_uid);
  end if;

  perform nano_internal.evaluate_achievements(v_uid);
  perform nano_internal.evaluate_missions(v_uid);

  return nano_internal.quiz_result_summary(p_attempt_id)
    || jsonb_build_object('idempotent', false);
end;
$$;
