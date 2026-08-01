-- XP-04: mission catalog and progress uniqueness.

begin;

do $$
declare
  v_count int;
begin
  if not exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'missions'
  ) then
    raise exception 'missions missing';
  end if;

  if not exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'mission_progress'
  ) then
    raise exception 'mission_progress missing';
  end if;

  select count(*) into v_count from public.missions where active;
  if v_count < 4 then
    raise exception 'expected at least 4 missions, found %', v_count;
  end if;

  if not exists (
    select 1 from public.xp_award_rules where source_kind = 'mission_complete'
  ) then
    raise exception 'mission_complete award rule missing';
  end if;

  if has_table_privilege('authenticated', 'public.missions', 'insert')
     or has_table_privilege('authenticated', 'public.mission_progress', 'insert')
  then
    raise exception 'authenticated must not write mission tables';
  end if;

  raise notice 'xp04_missions: ok';
end;
$$;

rollback;
