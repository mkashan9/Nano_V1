-- ADM-02: school write RPCs exist for platform staff.

begin;

do $$
begin
  if to_regprocedure('public.create_school(text, text)') is null then
    raise exception 'create_school missing';
  end if;
  if to_regprocedure('public.set_school_status(uuid, text, text)') is null then
    raise exception 'set_school_status missing';
  end if;
  if to_regprocedure('public.assign_first_school_admin(uuid, uuid)') is null then
    raise exception 'assign_first_school_admin missing';
  end if;
  if to_regprocedure('public.list_managed_schools(text)') is null then
    raise exception 'list_managed_schools missing';
  end if;

  if has_table_privilege('authenticated', 'public.schools', 'insert')
     or has_table_privilege('authenticated', 'public.schools', 'update')
  then
    raise exception 'authenticated must not write schools directly';
  end if;

  raise notice 'adm02_school_ops: ok';
end;
$$;

rollback;
