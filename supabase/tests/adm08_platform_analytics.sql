-- ADM-08: platform analytics RPC exists for platform staff.

begin;

do $$
begin
  if to_regprocedure('public.platform_analytics()') is null then
    raise exception 'platform_analytics missing';
  end if;
  if has_function_privilege('anon', 'public.platform_analytics()', 'execute')
  then
    raise exception 'anon must not call platform_analytics';
  end if;

  raise notice 'adm08_platform_analytics: ok';
end;
$$;

rollback;
