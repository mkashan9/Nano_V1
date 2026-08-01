-- ADM-05: gamification admin RPCs exist for platform staff.

begin;

do $$
begin
  if to_regprocedure('public.list_gamification_admin()') is null then
    raise exception 'list_gamification_admin missing';
  end if;
  if to_regprocedure('public.set_xp_daily_cap(integer)') is null then
    raise exception 'set_xp_daily_cap missing';
  end if;
  if to_regprocedure('public.set_xp_award_amount(text, integer)') is null then
    raise exception 'set_xp_award_amount missing';
  end if;
  if to_regprocedure('public.set_level_step(integer)') is null then
    raise exception 'set_level_step missing';
  end if;
  if to_regprocedure('public.set_achievement_active(uuid, boolean)') is null then
    raise exception 'set_achievement_active missing';
  end if;
  if to_regprocedure('public.set_mission_active(uuid, boolean)') is null then
    raise exception 'set_mission_active missing';
  end if;
  if to_regprocedure('public.admin_adjust_xp(uuid, integer, text)') is null then
    raise exception 'admin_adjust_xp missing';
  end if;
  if has_function_privilege('anon', 'public.set_xp_daily_cap(integer)', 'execute')
  then
    raise exception 'anon must not set daily cap';
  end if;

  raise notice 'adm05_gamification_admin: ok';
end;
$$;

rollback;
