-- XP-04: daily and weekly missions.
--
-- Definitions are server-owned. Progress is unique per learner, mission, and
-- period. Completing a mission awards bonus XP once through the ledger with
-- source_kind = mission_complete and source_id = mission_id:period_key.

-- Allow mission bonuses on the ledger.
alter table public.xp_award_rules
  drop constraint if exists xp_award_rules_source_kind_check;

alter table public.xp_award_rules
  add constraint xp_award_rules_source_kind_check
  check (source_kind in (
    'video_completion',
    'quiz_pass',
    'manual_adjust',
    'reversal',
    'game_result',
    'mission_complete'
  ));

insert into public.xp_award_rules (source_kind, amount, notes)
values (
  'mission_complete', 0,
  'XP-04: amount comes from the mission definition per completion.'
)
on conflict (source_kind) do nothing;

-- award_xp: treat mission_complete like manual_adjust (amount required).
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

  if p_source_kind in ('manual_adjust', 'reversal', 'mission_complete') then
    v_amount := p_amount;
    if v_amount is null or v_amount = 0 then
      raise exception using
        errcode = 'NX003',
        message = 'A manual XP change needs a non-zero amount.';
    end if;
    if p_source_kind <> 'mission_complete'
       and btrim(coalesce(p_reason, '')) = '' then
      raise exception using
        errcode = 'NX004',
        message = 'A manual XP change needs a reason.';
    end if;
  else
    v_amount := v_rule_amount;
  end if;

  select * into v_row
  from public.xp_ledger
  where user_id = p_user_id
    and source_kind = p_source_kind
    and source_id = btrim(p_source_id);

  if v_row.id is not null then
    return v_row;
  end if;

  if v_amount > 0 then
    select daily_cap into v_cap from public.xp_policy where id;
    select coalesce(sum(amount), 0) into v_today
    from public.xp_ledger
    where user_id = p_user_id
      and amount > 0
      and awarded_at >= date_trunc('day', timezone('utc', now()));

    if v_today >= v_cap then
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

  perform nano_internal.refresh_xp_progress(p_user_id);

  return v_row;
end;
$$;

revoke all on function nano_internal.award_xp(uuid, text, text, integer, text, uuid)
  from public, anon, authenticated;
grant execute on function nano_internal.award_xp(uuid, text, text, integer, text, uuid)
  to service_role;

-- ---------------------------------------------------------------------------
-- Catalog + progress
-- ---------------------------------------------------------------------------
create table if not exists public.missions (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique
    check (slug ~ '^[a-z][a-z0-9_]{1,62}$'),
  cadence text not null check (cadence in ('daily', 'weekly')),
  title_en text not null,
  title_ur text not null,
  subtitle_en text not null default '',
  subtitle_ur text not null default '',
  rule_kind text not null check (rule_kind in (
    'topic_completions_in_period',
    'quiz_passes_in_period'
  )),
  target_count integer not null check (target_count >= 1),
  xp_bonus integer not null check (xp_bonus >= 0),
  sort_order integer not null default 100,
  active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now())
);

comment on table public.missions is
  'XP-04 daily/weekly mission catalog. Clients read; ADM-05 may edit.';

create table if not exists public.mission_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  mission_id uuid not null references public.missions (id) on delete cascade,
  period_key text not null,
  progress_count integer not null default 0 check (progress_count >= 0),
  completed_at timestamptz,
  updated_at timestamptz not null default timezone('utc', now()),
  unique (user_id, mission_id, period_key)
);

comment on table public.mission_progress is
  'XP-04 per-period progress. Unique so a replay cannot complete twice.';

create index if not exists mission_progress_user_period_idx
  on public.mission_progress (user_id, period_key);

insert into public.missions
  (slug, cadence, title_en, title_ur, subtitle_en, subtitle_ur,
   rule_kind, target_count, xp_bonus, sort_order)
values
  (
    'daily_lesson', 'daily',
    'Complete a lesson', 'ایک سبق مکمل کریں',
    'Today', 'آج',
    'topic_completions_in_period', 1, 15, 10
  ),
  (
    'daily_quiz', 'daily',
    'Pass a quiz', 'ایک کوئز پاس کریں',
    'Today', 'آج',
    'quiz_passes_in_period', 1, 20, 20
  ),
  (
    'weekly_lessons', 'weekly',
    'Finish 3 lessons', '۳ سبق مکمل کریں',
    'This week', 'اس ہفتے',
    'topic_completions_in_period', 3, 50, 30
  ),
  (
    'weekly_quizzes', 'weekly',
    'Pass 2 quizzes', '۲ کوئز پاس کریں',
    'This week', 'اس ہفتے',
    'quiz_passes_in_period', 2, 40, 40
  )
on conflict (slug) do nothing;

alter table public.missions enable row level security;
alter table public.mission_progress enable row level security;

drop policy if exists missions_select on public.missions;
create policy missions_select on public.missions
  for select to authenticated
  using (active);

drop policy if exists mission_progress_select_own on public.mission_progress;
create policy mission_progress_select_own on public.mission_progress
  for select to authenticated
  using (user_id = auth.uid());

revoke all on table public.missions from public, anon, authenticated;
revoke all on table public.mission_progress from public, anon, authenticated;
grant select on table public.missions to authenticated, service_role;
grant select on table public.mission_progress to authenticated, service_role;

create or replace function nano_internal.mission_period_key(p_cadence text)
returns text
language sql
stable
set search_path = pg_catalog, public
as $$
  select case p_cadence
    when 'daily' then to_char(timezone('utc', now()), 'YYYY-MM-DD')
    when 'weekly' then to_char(timezone('utc', now()), 'IYYY-"W"IW')
    else null
  end;
$$;

create or replace function nano_internal.mission_period_start(p_cadence text)
returns timestamptz
language sql
stable
set search_path = pg_catalog, public
as $$
  select case p_cadence
    when 'daily' then date_trunc('day', timezone('utc', now()))
    when 'weekly' then date_trunc('week', timezone('utc', now()))
    else null
  end;
$$;

create or replace function nano_internal.evaluate_missions(p_user_id uuid)
returns integer
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_mission public.missions;
  v_period text;
  v_start timestamptz;
  v_count integer;
  v_prog public.mission_progress;
  v_completed integer := 0;
  v_source text;
begin
  if p_user_id is null then
    return 0;
  end if;

  for v_mission in
    select * from public.missions where active order by sort_order, slug
  loop
    v_period := nano_internal.mission_period_key(v_mission.cadence);
    v_start := nano_internal.mission_period_start(v_mission.cadence);

    if v_mission.rule_kind = 'topic_completions_in_period' then
      select count(*) into v_count
      from public.topic_completions
      where user_id = p_user_id
        and completed_at >= v_start;
    elsif v_mission.rule_kind = 'quiz_passes_in_period' then
      select count(*) into v_count
      from public.topic_quiz_progress
      where user_id = p_user_id
        and passed
        and passed_at >= v_start;
    else
      v_count := 0;
    end if;

    insert into public.mission_progress as mp
      (user_id, mission_id, period_key, progress_count, updated_at)
    values (
      p_user_id, v_mission.id, v_period,
      least(v_count, v_mission.target_count),
      timezone('utc', now())
    )
    on conflict (user_id, mission_id, period_key) do update
      set progress_count = greatest(
            mp.progress_count,
            least(excluded.progress_count, v_mission.target_count)
          ),
          updated_at = excluded.updated_at
    returning * into v_prog;

    -- Re-read after upsert.
    select * into v_prog
    from public.mission_progress
    where user_id = p_user_id
      and mission_id = v_mission.id
      and period_key = v_period;

    if v_prog.progress_count >= v_mission.target_count
       and v_prog.completed_at is null then
      update public.mission_progress
      set completed_at = timezone('utc', now()),
          progress_count = v_mission.target_count,
          updated_at = timezone('utc', now())
      where id = v_prog.id;

      if v_mission.xp_bonus > 0 then
        v_source := v_mission.id::text || ':' || v_period;
        perform nano_internal.award_xp(
          p_user_id,
          'mission_complete',
          v_source,
          v_mission.xp_bonus,
          'Mission ' || v_mission.slug
        );
      end if;

      v_completed := v_completed + 1;
    end if;
  end loop;

  return v_completed;
end;
$$;

revoke all on function nano_internal.evaluate_missions(uuid)
  from public, anon, authenticated;
grant execute on function nano_internal.evaluate_missions(uuid)
  to service_role;

create or replace function public.my_missions()
returns table (
  mission_id uuid,
  slug text,
  cadence text,
  title_en text,
  title_ur text,
  subtitle_en text,
  subtitle_ur text,
  xp_bonus integer,
  target_count integer,
  progress_count integer,
  period_key text,
  completed boolean,
  completed_at timestamptz
)
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception using errcode = 'NX010', message = 'Authentication required.';
  end if;

  perform nano_internal.evaluate_missions(v_uid);

  return query
  select
    m.id,
    m.slug,
    m.cadence,
    m.title_en,
    m.title_ur,
    m.subtitle_en,
    m.subtitle_ur,
    m.xp_bonus,
    m.target_count,
    coalesce(p.progress_count, 0),
    coalesce(p.period_key, nano_internal.mission_period_key(m.cadence)),
    p.completed_at is not null,
    p.completed_at
  from public.missions m
  left join public.mission_progress p
    on p.mission_id = m.id
   and p.user_id = v_uid
   and p.period_key = nano_internal.mission_period_key(m.cadence)
  where m.active
  order by m.sort_order, m.slug;
end;
$$;

revoke all on function public.my_missions() from public, anon;
grant execute on function public.my_missions() to authenticated, service_role;

-- Hook evaluate into complete_topic and submit_quiz_attempt (after achievements).
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
  end if;

  perform nano_internal.evaluate_achievements(v_uid);
  perform nano_internal.evaluate_missions(v_uid);

  return nano_internal.quiz_result_summary(p_attempt_id)
    || jsonb_build_object('idempotent', false);
end;
$$;
