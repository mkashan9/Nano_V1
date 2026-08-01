-- XP-03: awards are idempotent; learners cannot write the catalog.

begin;

do $$
declare
  v_count int;
begin
  if not exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'achievement_definitions'
  ) then
    raise exception 'achievement_definitions missing';
  end if;

  if not exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'achievement_awards'
  ) then
    raise exception 'achievement_awards missing';
  end if;

  select count(*) into v_count
  from public.achievement_definitions
  where slug in ('first_steps', 'quiz_rookie', 'rising_star', 'level_climber');
  if v_count <> 4 then
    raise exception 'expected 4 seed definitions, found %', v_count;
  end if;

  if has_table_privilege('authenticated', 'public.achievement_definitions', 'insert')
     or has_table_privilege('authenticated', 'public.achievement_awards', 'insert')
     or has_table_privilege('authenticated', 'public.achievement_awards', 'update')
  then
    raise exception 'authenticated must not write achievement tables';
  end if;

  -- Unique key exists for idempotent grants.
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.achievement_awards'::regclass
      and contype = 'u'
  ) then
    raise exception 'achievement_awards needs a unique constraint';
  end if;

  raise notice 'xp03_achievements: ok';
end;
$$;

rollback;
