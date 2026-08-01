-- XP-05: streak table is read-only for learners.

begin;

do $$
begin
  if not exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'streaks'
  ) then
    raise exception 'streaks missing';
  end if;

  if has_table_privilege('authenticated', 'public.streaks', 'insert')
     or has_table_privilege('authenticated', 'public.streaks', 'update')
  then
    raise exception 'authenticated must not write streaks';
  end if;

  if to_regprocedure('nano_internal.touch_streak(uuid)') is null then
    raise exception 'touch_streak missing';
  end if;

  if to_regprocedure('public.my_streak()') is null then
    raise exception 'my_streak missing';
  end if;

  raise notice 'xp05_streaks: ok';
end;
$$;

rollback;
