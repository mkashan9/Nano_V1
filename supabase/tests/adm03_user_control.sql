-- ADM-03: user-control RPCs exist for platform staff.

begin;

do $$
begin
  if to_regprocedure('public.search_platform_users(text)') is null then
    raise exception 'search_platform_users missing';
  end if;
  if to_regprocedure('public.set_profile_status(uuid, text, text)') is null then
    raise exception 'set_profile_status missing';
  end if;
  if to_regprocedure('public.replace_school_admin(uuid, uuid, text)') is null then
    raise exception 'replace_school_admin missing';
  end if;
  if to_regprocedure('public.admin_revoke_user_sessions(uuid, text, uuid)') is null then
    raise exception 'admin_revoke_user_sessions missing';
  end if;

  if has_function_privilege('anon', 'public.search_platform_users(text)', 'execute') then
    raise exception 'anon must not execute search_platform_users';
  end if;

  raise notice 'adm03_user_control: ok';
end;
$$;

rollback;
