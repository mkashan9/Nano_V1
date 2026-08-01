-- ADM-01: platform_dashboard is platform-admin only.

begin;

do $$
begin
  if to_regprocedure('public.platform_dashboard(text)') is null then
    raise exception 'platform_dashboard missing';
  end if;

  raise notice 'adm01_platform_dashboard: ok';
end;
$$;

rollback;
