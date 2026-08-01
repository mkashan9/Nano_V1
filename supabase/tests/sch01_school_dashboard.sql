-- SCH-01: school dashboard RPCs exist for school admins.

begin;

do $$
begin
  if to_regprocedure('public.school_dashboard()') is null then
    raise exception 'school_dashboard missing';
  end if;
  if to_regprocedure(
    'public.update_school_branding(text, text, text, text, text, text, text, text, text, boolean)'
  ) is null then
    raise exception 'update_school_branding missing';
  end if;
  if has_function_privilege('anon', 'public.school_dashboard()', 'execute')
  then
    raise exception 'anon must not call school_dashboard';
  end if;
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'schools'
      and column_name = 'primary_color'
  ) then
    raise exception 'schools.primary_color missing';
  end if;

  raise notice 'sch01_school_dashboard: ok';
end;
$$;

rollback;
