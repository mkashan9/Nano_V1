-- XP-01: trusted XP ledger.
--
-- Clients never write this table. Awards happen inside the same transactions
-- that already own the source events (topic completion, quiz submit), so a
-- completion that rolls back cannot leave a credit behind, and a credit that
-- fails cannot leave a completion without its XP once the unique key lands.
--
-- Duplicate source events cannot award twice: the unique key is
-- (user_id, source_kind, source_id). Replay of complete_topic or
-- submit_quiz_attempt is therefore free.

create table if not exists public.xp_award_rules (
  source_kind text primary key
    check (source_kind in (
      'video_completion',
      'quiz_pass',
      'manual_adjust',
      'reversal',
      'game_result'
    )),
  amount integer not null,
  notes text not null default '',
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.xp_award_rules is
  'XP-01 server-owned award amounts. Clients read nothing here; only the '
  'award helper does. game_result is reserved for GME-05.';

insert into public.xp_award_rules (source_kind, amount, notes)
values
  ('video_completion', 10,
   'Handbook 11.4: small, one per published topic version.'),
  ('quiz_pass', 30,
   'Handbook 11.4: medium, one primary award per quiz version on first pass.'),
  ('manual_adjust', 0,
   'Amount is supplied per call; this row exists so the kind is legal.'),
  ('reversal', 0,
   'Amount is the negation of the original award.'),
  ('game_result', 20,
   'Reserved for GME-05. Not awarded by XP-01.')
on conflict (source_kind) do nothing;

-- Daily anti-abuse ceiling across every positive award for one learner.
create table if not exists public.xp_policy (
  id boolean primary key default true check (id),
  daily_cap integer not null default 200 check (daily_cap > 0),
  updated_at timestamptz not null default timezone('utc', now())
);

insert into public.xp_policy (id, daily_cap)
values (true, 200)
on conflict (id) do nothing;

create table if not exists public.xp_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  amount integer not null check (amount <> 0),
  source_kind text not null
    references public.xp_award_rules (source_kind),
  source_id text not null check (char_length(btrim(source_id)) > 0),
  reason text not null default '',
  awarded_at timestamptz not null default timezone('utc', now()),
  awarded_by uuid references public.profiles (id),
  unique (user_id, source_kind, source_id)
);

comment on table public.xp_ledger is
  'XP-01 append-only ledger. Unique (user, kind, source) is the idempotency '
  'key. Learners read their own rows; nobody inserts except the award helper.';

create index if not exists xp_ledger_user_awarded_idx
  on public.xp_ledger (user_id, awarded_at desc);

alter table public.xp_ledger enable row level security;
alter table public.xp_award_rules enable row level security;
alter table public.xp_policy enable row level security;

drop policy if exists xp_ledger_select_own on public.xp_ledger;
create policy xp_ledger_select_own on public.xp_ledger
  for select to authenticated
  using (
    user_id = auth.uid()
    or nano_internal.is_platform_admin()
  );

-- No insert/update/delete policies for authenticated. RPC-only writes.
drop policy if exists xp_rules_select_admin on public.xp_award_rules;
create policy xp_rules_select_admin on public.xp_award_rules
  for select to authenticated
  using (nano_internal.is_platform_admin());

drop policy if exists xp_policy_select_admin on public.xp_policy;
create policy xp_policy_select_admin on public.xp_policy
  for select to authenticated
  using (nano_internal.is_platform_admin());

revoke all on table public.xp_ledger from public, anon;
revoke all on table public.xp_award_rules from public, anon;
revoke all on table public.xp_policy from public, anon;
grant select on table public.xp_ledger to authenticated, service_role;
grant select on table public.xp_award_rules to authenticated, service_role;
grant select on table public.xp_policy to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Award helper. Security definer; never granted to authenticated directly.
-- ---------------------------------------------------------------------------
create or replace function nano_internal.award_xp(
  p_user_id uuid,
  p_source_kind text,
  p_source_id text,
  p_amount integer default null,
  p_reason text default '',
  p_awarded_by uuid default null
)
returns public.xp_ledger
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_amount integer;
  v_rule_amount integer;
  v_cap integer;
  v_today integer;
  v_row public.xp_ledger;
begin
  if p_user_id is null or btrim(coalesce(p_source_id, '')) = '' then
    raise exception using
      errcode = 'NX001',
      message = 'An XP award needs a learner and a source.';
  end if;

  select amount into v_rule_amount
  from public.xp_award_rules
  where source_kind = p_source_kind;

  if v_rule_amount is null then
    raise exception using
      errcode = 'NX002',
      message = 'That XP source is not defined.';
  end if;

  -- Manual and reversal amounts are supplied per call; everything else is
  -- owned by the rules table so a client release cannot change the economy.
  if p_source_kind in ('manual_adjust', 'reversal') then
    v_amount := p_amount;
    if v_amount is null or v_amount = 0 then
      raise exception using
        errcode = 'NX003',
        message = 'A manual XP change needs a non-zero amount.';
    end if;
    if btrim(coalesce(p_reason, '')) = '' then
      raise exception using
        errcode = 'NX004',
        message = 'A manual XP change needs a reason.';
    end if;
  else
    v_amount := v_rule_amount;
  end if;

  -- Already awarded for this source: return the existing row. Replay is free.
  select * into v_row
  from public.xp_ledger
  where user_id = p_user_id
    and source_kind = p_source_kind
    and source_id = btrim(p_source_id);

  if v_row.id is not null then
    return v_row;
  end if;

  -- Daily cap applies to positive awards only. A reversal must always land,
  -- otherwise an admin cannot undo a mistake on a capped day.
  if v_amount > 0 then
    select daily_cap into v_cap from public.xp_policy where id;
    select coalesce(sum(amount), 0) into v_today
    from public.xp_ledger
    where user_id = p_user_id
      and amount > 0
      and awarded_at >= date_trunc('day', timezone('utc', now()));

    if v_today >= v_cap then
      -- Cap hit: refuse the credit without failing the source action. The
      -- caller (complete_topic / submit) still succeeds; the learner simply
      -- gets no XP for this event today.
      return null;
    end if;

    if v_today + v_amount > v_cap then
      v_amount := v_cap - v_today;
    end if;
  end if;

  insert into public.xp_ledger
    (user_id, amount, source_kind, source_id, reason, awarded_by)
  values (
    p_user_id,
    v_amount,
    p_source_kind,
    btrim(p_source_id),
    coalesce(p_reason, ''),
    p_awarded_by
  )
  returning * into v_row;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    coalesce(p_awarded_by, p_user_id),
    case when p_awarded_by is not null then 'platform_admin' else 'student' end,
    'create',
    'xp_ledger',
    v_row.id::text,
    jsonb_build_object(
      'user_id', p_user_id,
      'amount', v_amount,
      'source_kind', p_source_kind,
      'source_id', btrim(p_source_id),
      'reason', coalesce(p_reason, '')
    )
  );

  return v_row;
end;
$$;

revoke all on function nano_internal.award_xp(uuid, text, text, integer, text, uuid)
  from public, anon, authenticated;
grant execute on function nano_internal.award_xp(uuid, text, text, integer, text, uuid)
  to service_role;

-- ---------------------------------------------------------------------------
-- Learner read models
-- ---------------------------------------------------------------------------
create or replace function public.my_xp_balance()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_uid uuid := auth.uid();
  v_total integer;
  v_today integer;
  v_cap integer;
begin
  if v_uid is null then
    raise exception using errcode = 'NX010', message = 'Authentication required.';
  end if;

  select coalesce(sum(amount), 0) into v_total
  from public.xp_ledger
  where user_id = v_uid;

  select coalesce(sum(amount), 0) into v_today
  from public.xp_ledger
  where user_id = v_uid
    and amount > 0
    and awarded_at >= date_trunc('day', timezone('utc', now()));

  select daily_cap into v_cap from public.xp_policy where id;

  return jsonb_build_object(
    'total', v_total,
    'today', v_today,
    'daily_cap', v_cap,
    'remaining_today', greatest(v_cap - v_today, 0)
  );
end;
$$;

revoke all on function public.my_xp_balance() from public, anon;
grant execute on function public.my_xp_balance() to authenticated, service_role;

create or replace function public.my_xp_ledger(p_limit integer default 50)
returns setof public.xp_ledger
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
begin
  if auth.uid() is null then
    raise exception using errcode = 'NX010', message = 'Authentication required.';
  end if;

  return query
  select *
  from public.xp_ledger
  where user_id = auth.uid()
  order by awarded_at desc
  limit greatest(coalesce(p_limit, 50), 1);
end;
$$;

revoke all on function public.my_xp_ledger(integer) from public, anon;
grant execute on function public.my_xp_ledger(integer) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Platform admin manual adjust
-- ---------------------------------------------------------------------------
create or replace function public.adjust_xp(
  p_user_id uuid,
  p_amount integer,
  p_reason text
)
returns public.xp_ledger
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_actor uuid := auth.uid();
  v_row public.xp_ledger;
begin
  if v_actor is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NX020',
      message = 'Only platform admins can adjust XP.';
  end if;

  v_row := nano_internal.award_xp(
    p_user_id,
    'manual_adjust',
    'manual:' || gen_random_uuid()::text,
    p_amount,
    p_reason,
    v_actor
  );

  if v_row.id is null then
    raise exception using
      errcode = 'NX021',
      message = 'That adjustment could not be recorded.';
  end if;

  return v_row;
end;
$$;

revoke all on function public.adjust_xp(uuid, integer, text) from public, anon;
grant execute on function public.adjust_xp(uuid, integer, text)
  to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Hook: video completion awards once
-- ---------------------------------------------------------------------------
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
    -- Already finished: still attempt the award so a completion that landed
    -- before XP-01 can pick up its credit exactly once.
    perform nano_internal.award_xp(
      auth.uid(),
      'video_completion',
      p_topic_version_id::text
    );
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

  -- Award is keyed on the topic version, so a replay or a completion that
  -- already existed without XP still lands exactly once.
  perform nano_internal.award_xp(
    auth.uid(),
    'video_completion',
    p_topic_version_id::text
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

  return v_row;
end;
$$;

comment on function public.complete_topic(uuid) is
  'LRN-03/XP-01 marks a topic complete once watch time reaches the threshold, '
  'and awards video_completion XP once per topic version.';

-- ---------------------------------------------------------------------------
-- Hook: first quiz pass awards once
-- ---------------------------------------------------------------------------
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

  -- Handbook 11.4: a quiz attempt by itself awards nothing; a pass awards
  -- once per quiz version. The unique key is the quiz_version, not the
  -- attempt, so a retake after a pass cannot credit again.
  if v_row.passed then
    perform nano_internal.award_xp(
      v_uid,
      'quiz_pass',
      v_attempt.quiz_version_id::text
    );
  end if;

  return nano_internal.quiz_result_summary(p_attempt_id)
    || jsonb_build_object('idempotent', false);
end;
$$;

comment on function public.submit_quiz_attempt(uuid) is
  'QZ-05/QZ-06/XP-01 scores an attempt, records progress, and awards quiz_pass '
  'XP once per quiz version on the first pass.';
