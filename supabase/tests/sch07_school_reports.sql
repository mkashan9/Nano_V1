-- SCH-07 school reports RPC presence.

do $$
begin
  if to_regprocedure('public.school_reports_summary()') is null then
    raise exception 'school_reports_summary missing';
  end if;
end $$;
