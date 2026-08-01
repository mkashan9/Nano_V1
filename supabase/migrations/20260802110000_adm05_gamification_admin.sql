-- ADM-05: gamification administration for platform staff.
-- Catalogs already exist (XP-01..04). This adds curated write RPCs + admin list.

create or replace function public.list_gamification_admin()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_cap integer;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NX030',
      message = 'Gamification admin is limited to platform staff.';
  end if;

  select daily_cap into v_cap from public.xp_policy where id;

  return jsonb_build_object(
    'daily_cap', coalesce(v_cap, 200),
    'award_rules', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'source_kind', r.source_kind,
          'amount', r.amount,
          'notes', r.notes
        )
        order by r.source_kind
      )
      from public.xp_award_rules r
    ), '[]'::jsonb),
    'level_rules', coalesce((
      select jsonb_agg(
        jsonb_build_object('level', lr.level, 'min_xp', lr.min_xp)
        order by lr.level
      )
      from public.level_rules lr
    ), '[]'::jsonb),
    'achievements', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', a.id,
          'slug', a.slug,
          'kind', a.kind,
          'title_en', a.title_en,
          'title_ur', a.title_ur,
          'rule_kind', a.rule_kind,
          'rule_payload', a.rule_payload,
          'sort_order', a.sort_order,
          'active', a.active
        )
        order by a.sort_order, a.slug
      )
      from public.achievement_definitions a
    ), '[]'::jsonb),
    'missions', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', m.id,
          'slug', m.slug,
          'cadence', m.cadence,
          'title_en', m.title_en,
          'title_ur', m.title_ur,
          'rule_kind', m.rule_kind,
          'target_count', m.target_count,
          'xp_bonus', m.xp_bonus,
          'sort_order', m.sort_order,
          'active', m.active
        )
        order by m.sort_order, m.slug
      )
      from public.missions m
    ), '[]'::jsonb)
  );
end;
$fn$;

revoke all on function public.list_gamification_admin() from public, anon;
grant execute on function public.list_gamification_admin()
  to authenticated, service_role;

create or replace function public.set_xp_daily_cap(p_daily_cap integer)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NX030',
      message = 'Gamification admin is limited to platform staff.';
  end if;

  if p_daily_cap is null or p_daily_cap < 1 then
    raise exception using
      errcode = 'NX031',
      message = 'Daily cap must be at least 1.';
  end if;

  update public.xp_policy
  set daily_cap = p_daily_cap,
      updated_at = timezone('utc', now())
  where id;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'superadmin', 'update', 'xp_policy', 'daily_cap',
    jsonb_build_object('daily_cap', p_daily_cap)
  );

  return jsonb_build_object('daily_cap', p_daily_cap);
end;
$fn$;

revoke all on function public.set_xp_daily_cap(integer) from public, anon;
grant execute on function public.set_xp_daily_cap(integer)
  to authenticated, service_role;

create or replace function public.set_xp_award_amount(
  p_source_kind text,
  p_amount integer
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NX030',
      message = 'Gamification admin is limited to platform staff.';
  end if;

  if p_source_kind not in ('video_completion', 'quiz_pass', 'game_result') then
    raise exception using
      errcode = 'NX032',
      message = 'Only video, quiz, and game award amounts can be edited here.';
  end if;

  if p_amount is null or p_amount < 1 then
    raise exception using
      errcode = 'NX033',
      message = 'Award amount must be at least 1.';
  end if;

  update public.xp_award_rules
  set amount = p_amount,
      updated_at = timezone('utc', now())
  where source_kind = p_source_kind;

  if not found then
    raise exception using errcode = 'NX034', message = 'Unknown award rule.';
  end if;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'superadmin', 'update', 'xp_award_rules', p_source_kind,
    jsonb_build_object('amount', p_amount)
  );

  return jsonb_build_object('source_kind', p_source_kind, 'amount', p_amount);
end;
$fn$;

revoke all on function public.set_xp_award_amount(text, integer) from public, anon;
grant execute on function public.set_xp_award_amount(text, integer)
  to authenticated, service_role;

create or replace function public.set_level_step(p_xp_per_level integer)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_max integer := 40;
  v_user uuid;
  v_count integer := 0;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NX030',
      message = 'Gamification admin is limited to platform staff.';
  end if;

  if p_xp_per_level is null or p_xp_per_level < 50 or p_xp_per_level > 5000 then
    raise exception using
      errcode = 'NX035',
      message = 'XP per level must be between 50 and 5000.';
  end if;

  -- Two-phase update avoids unique(min_xp) collisions when the step grows.
  update public.level_rules
  set min_xp = 1000000 + level;

  insert into public.level_rules (level, min_xp)
  select g, (g - 1) * p_xp_per_level
  from generate_series(1, v_max) as g
  on conflict (level) do update
    set min_xp = excluded.min_xp;

  delete from public.level_rules where level > v_max;

  for v_user in
    select distinct user_id from public.xp_ledger
  loop
    perform nano_internal.refresh_xp_progress(v_user);
    v_count := v_count + 1;
  end loop;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'superadmin', 'update', 'level_rules', 'step',
    jsonb_build_object(
      'xp_per_level', p_xp_per_level,
      'levels', v_max,
      'refreshed_users', v_count
    )
  );

  return jsonb_build_object(
    'xp_per_level', p_xp_per_level,
    'levels', v_max,
    'refreshed_users', v_count
  );
end;
$fn$;

revoke all on function public.set_level_step(integer) from public, anon;
grant execute on function public.set_level_step(integer)
  to authenticated, service_role;

create or replace function public.set_achievement_active(
  p_achievement_id uuid,
  p_active boolean
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_slug text;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NX030',
      message = 'Gamification admin is limited to platform staff.';
  end if;

  update public.achievement_definitions
  set active = coalesce(p_active, false)
  where id = p_achievement_id
  returning slug into v_slug;

  if v_slug is null then
    raise exception using errcode = 'NX036', message = 'Unknown achievement.';
  end if;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'superadmin', 'update', 'achievement_definitions', v_slug,
    jsonb_build_object('active', coalesce(p_active, false))
  );

  return jsonb_build_object(
    'id', p_achievement_id,
    'slug', v_slug,
    'active', coalesce(p_active, false)
  );
end;
$fn$;

revoke all on function public.set_achievement_active(uuid, boolean)
  from public, anon;
grant execute on function public.set_achievement_active(uuid, boolean)
  to authenticated, service_role;

create or replace function public.set_mission_active(
  p_mission_id uuid,
  p_active boolean
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_slug text;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NX030',
      message = 'Gamification admin is limited to platform staff.';
  end if;

  update public.missions
  set active = coalesce(p_active, false)
  where id = p_mission_id
  returning slug into v_slug;

  if v_slug is null then
    raise exception using errcode = 'NX037', message = 'Unknown mission.';
  end if;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'superadmin', 'update', 'missions', v_slug,
    jsonb_build_object('active', coalesce(p_active, false))
  );

  return jsonb_build_object(
    'id', p_mission_id,
    'slug', v_slug,
    'active', coalesce(p_active, false)
  );
end;
$fn$;

revoke all on function public.set_mission_active(uuid, boolean) from public, anon;
grant execute on function public.set_mission_active(uuid, boolean)
  to authenticated, service_role;

create or replace function public.set_mission_rewards(
  p_mission_id uuid,
  p_target_count integer,
  p_xp_bonus integer
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_slug text;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NX030',
      message = 'Gamification admin is limited to platform staff.';
  end if;

  if p_target_count is null or p_target_count < 1 then
    raise exception using
      errcode = 'NX038',
      message = 'Mission target must be at least 1.';
  end if;

  if p_xp_bonus is null or p_xp_bonus < 0 then
    raise exception using
      errcode = 'NX039',
      message = 'Mission XP bonus cannot be negative.';
  end if;

  update public.missions
  set target_count = p_target_count,
      xp_bonus = p_xp_bonus
  where id = p_mission_id
  returning slug into v_slug;

  if v_slug is null then
    raise exception using errcode = 'NX037', message = 'Unknown mission.';
  end if;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'superadmin', 'update', 'missions', v_slug,
    jsonb_build_object(
      'target_count', p_target_count,
      'xp_bonus', p_xp_bonus
    )
  );

  return jsonb_build_object(
    'id', p_mission_id,
    'slug', v_slug,
    'target_count', p_target_count,
    'xp_bonus', p_xp_bonus
  );
end;
$fn$;

revoke all on function public.set_mission_rewards(uuid, integer, integer)
  from public, anon;
grant execute on function public.set_mission_rewards(uuid, integer, integer)
  to authenticated, service_role;

-- adjust_xp already exists from XP-01; require non-empty reason at the edge.
create or replace function public.admin_adjust_xp(
  p_user_id uuid,
  p_amount integer,
  p_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_reason text := btrim(coalesce(p_reason, ''));
  v_row public.xp_ledger;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NX030',
      message = 'Gamification admin is limited to platform staff.';
  end if;

  if v_reason = '' then
    raise exception using
      errcode = 'NX040',
      message = 'A reason is required for manual XP adjustments.';
  end if;

  if p_amount is null or p_amount = 0 then
    raise exception using
      errcode = 'NX041',
      message = 'Adjustment amount cannot be zero.';
  end if;

  v_row := public.adjust_xp(p_user_id, p_amount, v_reason);

  return jsonb_build_object(
    'ledger_id', v_row.id,
    'user_id', v_row.user_id,
    'amount', v_row.amount,
    'reason', v_row.reason,
    'awarded_at', v_row.awarded_at
  );
end;
$fn$;

revoke all on function public.admin_adjust_xp(uuid, integer, text)
  from public, anon;
grant execute on function public.admin_adjust_xp(uuid, integer, text)
  to authenticated, service_role;
