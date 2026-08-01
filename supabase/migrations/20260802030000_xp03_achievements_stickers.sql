-- XP-03: achievements and stickers.
--
-- Definitions are server-owned. Awards are unique per learner per definition.
-- Evaluation runs after trusted learning events and after level refresh so a
-- capped XP day can still unlock a sticker from the underlying completion.

create table if not exists public.achievement_definitions (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique
    check (slug ~ '^[a-z][a-z0-9_]{1,62}$'),
  kind text not null check (kind in ('achievement', 'sticker')),
  title_en text not null,
  title_ur text not null,
  description_en text not null default '',
  description_ur text not null default '',
  rule_kind text not null check (rule_kind in (
    'topic_completions_at_least',
    'quiz_passes_at_least',
    'level_at_least'
  )),
  rule_payload jsonb not null default '{}'::jsonb,
  sort_order integer not null default 100,
  active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now())
);

comment on table public.achievement_definitions is
  'XP-03 catalog of badges and stickers. Clients read; only ADM-05 may edit.';

create table if not exists public.achievement_awards (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  achievement_id uuid not null
    references public.achievement_definitions (id) on delete cascade,
  awarded_at timestamptz not null default timezone('utc', now()),
  source_note text not null default '',
  unique (user_id, achievement_id)
);

comment on table public.achievement_awards is
  'XP-03 append-only grants. Unique per learner per definition.';

create index if not exists achievement_awards_user_awarded_idx
  on public.achievement_awards (user_id, awarded_at desc);

insert into public.achievement_definitions
  (slug, kind, title_en, title_ur, description_en, description_ur,
   rule_kind, rule_payload, sort_order)
values
  (
    'first_steps', 'sticker',
    'First Steps', 'پہلا قدم',
    'Finish your first topic video.', 'اپنی پہلی موضوع ویڈیو مکمل کریں۔',
    'topic_completions_at_least', '{"count": 1}'::jsonb, 10
  ),
  (
    'quiz_rookie', 'achievement',
    'Quiz Rookie', 'کوئز نوآموز',
    'Pass your first quiz.', 'اپنا پہلا کوئز پاس کریں۔',
    'quiz_passes_at_least', '{"count": 1}'::jsonb, 20
  ),
  (
    'rising_star', 'achievement',
    'Rising Star', 'ابھرتا ستارہ',
    'Reach level 2.', 'سطح ۲ تک پہنچیں۔',
    'level_at_least', '{"level": 2}'::jsonb, 30
  ),
  (
    'level_climber', 'achievement',
    'Level Climber', 'سطح چڑھنے والا',
    'Reach level 3.', 'سطح ۳ تک پہنچیں۔',
    'level_at_least', '{"level": 3}'::jsonb, 40
  )
on conflict (slug) do nothing;

alter table public.achievement_definitions enable row level security;
alter table public.achievement_awards enable row level security;

drop policy if exists achievement_definitions_select on public.achievement_definitions;
create policy achievement_definitions_select on public.achievement_definitions
  for select to authenticated
  using (active);

drop policy if exists achievement_awards_select_own on public.achievement_awards;
create policy achievement_awards_select_own on public.achievement_awards
  for select to authenticated
  using (user_id = auth.uid());

revoke all on table public.achievement_definitions from public, anon, authenticated;
revoke all on table public.achievement_awards from public, anon, authenticated;
grant select on table public.achievement_definitions to authenticated, service_role;
grant select on table public.achievement_awards to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Grant helper (idempotent)
-- ---------------------------------------------------------------------------
create or replace function nano_internal.award_achievement(
  p_user_id uuid,
  p_slug text,
  p_source_note text default ''
)
returns public.achievement_awards
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_def public.achievement_definitions;
  v_row public.achievement_awards;
begin
  if p_user_id is null or btrim(coalesce(p_slug, '')) = '' then
    raise exception using
      errcode = 'NX030',
      message = 'An achievement award needs a learner and a slug.';
  end if;

  select * into v_def
  from public.achievement_definitions
  where slug = btrim(p_slug) and active;

  if v_def.id is null then
    raise exception using
      errcode = 'NX031',
      message = 'That achievement is not defined.';
  end if;

  select * into v_row
  from public.achievement_awards
  where user_id = p_user_id and achievement_id = v_def.id;

  if v_row.id is not null then
    return v_row;
  end if;

  insert into public.achievement_awards
    (user_id, achievement_id, source_note)
  values (p_user_id, v_def.id, coalesce(p_source_note, ''))
  returning * into v_row;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    p_user_id, 'student', 'create', 'achievement_award', v_row.id::text,
    jsonb_build_object(
      'slug', v_def.slug,
      'kind', v_def.kind,
      'source_note', coalesce(p_source_note, '')
    )
  );

  return v_row;
end;
$$;

revoke all on function nano_internal.award_achievement(uuid, text, text)
  from public, anon, authenticated;
grant execute on function nano_internal.award_achievement(uuid, text, text)
  to service_role;

-- ---------------------------------------------------------------------------
-- Evaluate all active rules for one learner
-- ---------------------------------------------------------------------------
create or replace function nano_internal.evaluate_achievements(p_user_id uuid)
returns integer
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_def public.achievement_definitions;
  v_need integer;
  v_have integer;
  v_level integer;
  v_granted integer := 0;
begin
  if p_user_id is null then
    return 0;
  end if;

  for v_def in
    select d.*
    from public.achievement_definitions d
    where d.active
      and not exists (
        select 1 from public.achievement_awards a
        where a.user_id = p_user_id and a.achievement_id = d.id
      )
    order by d.sort_order, d.slug
  loop
    if v_def.rule_kind = 'topic_completions_at_least' then
      v_need := greatest(coalesce((v_def.rule_payload ->> 'count')::integer, 1), 1);
      select count(*) into v_have
      from public.topic_completions
      where user_id = p_user_id;
      if v_have >= v_need then
        perform nano_internal.award_achievement(
          p_user_id, v_def.slug, 'topic_completions'
        );
        v_granted := v_granted + 1;
      end if;

    elsif v_def.rule_kind = 'quiz_passes_at_least' then
      v_need := greatest(coalesce((v_def.rule_payload ->> 'count')::integer, 1), 1);
      select count(*) into v_have
      from public.topic_quiz_progress
      where user_id = p_user_id and passed;
      if v_have >= v_need then
        perform nano_internal.award_achievement(
          p_user_id, v_def.slug, 'quiz_passes'
        );
        v_granted := v_granted + 1;
      end if;

    elsif v_def.rule_kind = 'level_at_least' then
      v_need := greatest(coalesce((v_def.rule_payload ->> 'level')::integer, 1), 1);
      select coalesce(p.level, 1) into v_level
      from public.xp_progress p
      where p.user_id = p_user_id;
      v_level := coalesce(v_level, 1);
      if v_level >= v_need then
        perform nano_internal.award_achievement(
          p_user_id, v_def.slug, 'level'
        );
        v_granted := v_granted + 1;
      end if;
    end if;
  end loop;

  return v_granted;
end;
$$;

revoke all on function nano_internal.evaluate_achievements(uuid)
  from public, anon, authenticated;
grant execute on function nano_internal.evaluate_achievements(uuid)
  to service_role;

-- Refresh also evaluates level-based badges.
create or replace function nano_internal.refresh_xp_progress(p_user_id uuid)
returns public.xp_progress
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_total integer;
  v_prog jsonb;
  v_row public.xp_progress;
begin
  if p_user_id is null then
    raise exception using errcode = 'NX001', message = 'A learner is required.';
  end if;

  select coalesce(sum(amount), 0) into v_total
  from public.xp_ledger
  where user_id = p_user_id;

  v_total := greatest(v_total, 0);
  v_prog := nano_internal.level_progress_for_xp(v_total);

  insert into public.xp_progress as p
    (user_id, total_xp, level, xp_into_level, xp_to_next, xp_per_level, updated_at)
  values (
    p_user_id,
    v_total,
    (v_prog ->> 'level')::integer,
    (v_prog ->> 'xp_into_level')::integer,
    (v_prog ->> 'xp_to_next')::integer,
    (v_prog ->> 'xp_per_level')::integer,
    timezone('utc', now())
  )
  on conflict (user_id) do update
    set total_xp = excluded.total_xp,
        level = excluded.level,
        xp_into_level = excluded.xp_into_level,
        xp_to_next = excluded.xp_to_next,
        xp_per_level = excluded.xp_per_level,
        updated_at = excluded.updated_at
  returning * into v_row;

  perform nano_internal.evaluate_achievements(p_user_id);

  return v_row;
end;
$$;

revoke all on function nano_internal.refresh_xp_progress(uuid)
  from public, anon, authenticated;
grant execute on function nano_internal.refresh_xp_progress(uuid)
  to service_role;

-- Learner read model
create or replace function public.my_achievements()
returns table (
  award_id uuid,
  slug text,
  kind text,
  title_en text,
  title_ur text,
  description_en text,
  description_ur text,
  awarded_at timestamptz
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

  -- Catch up any awards that should already exist (e.g. after a migration).
  perform nano_internal.evaluate_achievements(v_uid);

  return query
  select
    a.id,
    d.slug,
    d.kind,
    d.title_en,
    d.title_ur,
    d.description_en,
    d.description_ur,
    a.awarded_at
  from public.achievement_awards a
  join public.achievement_definitions d on d.id = a.achievement_id
  where a.user_id = v_uid
  order by a.awarded_at desc, d.sort_order, d.slug;
end;
$$;

revoke all on function public.my_achievements() from public, anon;
grant execute on function public.my_achievements() to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- complete_topic: evaluate even when XP is capped or already completed
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
    perform nano_internal.award_xp(
      auth.uid(),
      'video_completion',
      p_topic_version_id::text
    );
    perform nano_internal.evaluate_achievements(auth.uid());
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

  perform nano_internal.evaluate_achievements(auth.uid());

  return v_row;
end;
$$;

comment on function public.complete_topic(uuid) is
  'LRN-03/XP-01/XP-03 marks a topic complete, awards video XP once, and '
  'evaluates achievements including First Steps.';

-- ---------------------------------------------------------------------------
-- submit_quiz_attempt: evaluate after scoring (pass or fail)
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
    perform nano_internal.evaluate_achievements(v_uid);
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

  if v_row.passed then
    perform nano_internal.award_xp(
      v_uid,
      'quiz_pass',
      v_attempt.quiz_version_id::text
    );
  end if;

  perform nano_internal.evaluate_achievements(v_uid);

  return nano_internal.quiz_result_summary(p_attempt_id)
    || jsonb_build_object('idempotent', false);
end;
$$;

comment on function public.submit_quiz_attempt(uuid) is
  'QZ-05/QZ-06/XP-01/XP-03 scores an attempt, awards quiz_pass XP on first '
  'pass, and evaluates achievements including Quiz Rookie.';

-- Backfill anyone who already qualifies.
do $$
declare
  r record;
begin
  for r in
    select id as user_id from public.profiles
    where id in (
      select user_id from public.topic_completions
      union
      select user_id from public.topic_quiz_progress where passed
      union
      select user_id from public.xp_progress where level >= 2
    )
  loop
    perform nano_internal.evaluate_achievements(r.user_id);
  end loop;
end;
$$;
