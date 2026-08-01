-- ADM-03: user search, profile suspend/restore, replace school admin,
-- platform session revoke. Password-reset email deferred.

create or replace function public.search_platform_users(p_query text default '')
returns table (
  id uuid,
  display_name text,
  account_kind text,
  status text,
  active_session_count integer,
  schools jsonb
)
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_q text := lower(btrim(coalesce(p_query, '')));
begin
  if not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NX090',
      message = 'User control is limited to platform staff.';
  end if;

  return query
  select
    p.id,
    p.display_name,
    p.account_kind::text,
    p.status::text,
    (
      select count(*)::int
      from public.device_sessions ds
      where ds.user_id = p.id and ds.revoked_at is null
    ) as active_session_count,
    coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'school_id', sm.school_id,
          'school_code', sch.code,
          'role', sm.role::text,
          'status', sm.status::text
        )
        order by sch.code
      )
      from public.school_memberships sm
      join public.schools sch on sch.id = sm.school_id
      where sm.user_id = p.id
    ), '[]'::jsonb) as schools
  from public.profiles p
  where v_q = ''
     or lower(p.display_name) like '%' || v_q || '%'
     or p.id::text like '%' || v_q || '%'
  order by p.display_name
  limit 50;
end;
$$;

revoke all on function public.search_platform_users(text) from public, anon;
grant execute on function public.search_platform_users(text)
  to authenticated, service_role;

create or replace function public.set_profile_status(
  p_user_id uuid,
  p_status text,
  p_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_status public.membership_status;
  v_reason text := btrim(coalesce(p_reason, ''));
  v_prev public.profiles;
begin
  if not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NX090',
      message = 'User control is limited to platform staff.';
  end if;

  if v_reason = '' then
    raise exception using
      errcode = 'NX091',
      message = 'A reason is required.';
  end if;

  if p_user_id = auth.uid() then
    raise exception using
      errcode = 'NX092',
      message = 'You cannot change your own account status here.';
  end if;

  if p_status not in ('active', 'suspended') then
    raise exception using
      errcode = 'NX093',
      message = 'Only active or suspended is allowed.';
  end if;
  v_status := p_status::public.membership_status;

  select * into v_prev from public.profiles where id = p_user_id;
  if v_prev.id is null then
    raise exception using
      errcode = 'NX094',
      message = 'User profile not found.';
  end if;

  update public.profiles
  set status = v_status,
      updated_at = timezone('utc', now())
  where id = p_user_id;

  insert into public.audit_events (
    actor_user_id, actor_role, action, target_type, target_id,
    previous_value, new_value, reason
  ) values (
    auth.uid(),
    'platform',
    case
      when v_status = 'suspended'::public.membership_status
        then 'suspend'::public.audit_action_kind
      else 'restore'::public.audit_action_kind
    end,
    'profiles',
    p_user_id::text,
    jsonb_build_object('status', v_prev.status::text),
    jsonb_build_object('status', v_status::text),
    v_reason
  );

  return (
    select jsonb_build_object(
      'id', p.id,
      'display_name', p.display_name,
      'account_kind', p.account_kind::text,
      'status', p.status::text,
      'active_session_count', (
        select count(*)::int
        from public.device_sessions ds
        where ds.user_id = p.id and ds.revoked_at is null
      ),
      'schools', coalesce((
        select jsonb_agg(
          jsonb_build_object(
            'school_id', sm.school_id,
            'school_code', sch.code,
            'role', sm.role::text,
            'status', sm.status::text
          )
        )
        from public.school_memberships sm
        join public.schools sch on sch.id = sm.school_id
        where sm.user_id = p.id
      ), '[]'::jsonb)
    )
    from public.profiles p
    where p.id = p_user_id
  );
end;
$$;

revoke all on function public.set_profile_status(uuid, text, text)
  from public, anon;
grant execute on function public.set_profile_status(uuid, text, text)
  to authenticated, service_role;

create or replace function public.replace_school_admin(
  p_school_id uuid,
  p_new_user_id uuid,
  p_reason text
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_reason text := btrim(coalesce(p_reason, ''));
  v_profile public.profiles;
  v_old uuid;
begin
  if not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NX090',
      message = 'User control is limited to platform staff.';
  end if;

  if v_reason = '' then
    raise exception using
      errcode = 'NX091',
      message = 'A reason is required.';
  end if;

  if not exists (select 1 from public.schools where id = p_school_id) then
    raise exception using
      errcode = 'NX095',
      message = 'School not found.';
  end if;

  select * into v_profile from public.profiles where id = p_new_user_id;
  if v_profile.id is null then
    raise exception using
      errcode = 'NX094',
      message = 'User profile not found.';
  end if;

  if v_profile.account_kind not in (
    'school_staff'::public.account_kind,
    'platform'::public.account_kind,
    'teacher'::public.account_kind
  ) then
    raise exception using
      errcode = 'NX096',
      message = 'Only staff accounts can be school administrators.';
  end if;

  if v_profile.status <> 'active'::public.membership_status then
    raise exception using
      errcode = 'NX097',
      message = 'The new admin must be an active profile.';
  end if;

  for v_old in
    select sm.user_id
    from public.school_memberships sm
    where sm.school_id = p_school_id
      and sm.role = 'school_admin'::public.membership_role
      and sm.status = 'active'::public.membership_status
      and sm.user_id <> p_new_user_id
  loop
    update public.school_memberships
    set status = 'left'::public.membership_status,
        updated_at = timezone('utc', now())
    where school_id = p_school_id
      and user_id = v_old
      and role = 'school_admin'::public.membership_role;

    insert into public.audit_events (
      actor_user_id, actor_role, school_id, action, target_type, target_id,
      previous_value, new_value, reason
    ) values (
      auth.uid(), 'platform', p_school_id, 'revoke'::public.audit_action_kind,
      'school_memberships', v_old::text,
      jsonb_build_object('role', 'school_admin', 'status', 'active'),
      jsonb_build_object('role', 'school_admin', 'status', 'left'),
      v_reason
    );
  end loop;

  insert into public.school_memberships (school_id, user_id, role, status)
  values (
    p_school_id,
    p_new_user_id,
    'school_admin'::public.membership_role,
    'active'::public.membership_status
  )
  on conflict (school_id, user_id, role) do update
    set status = 'active'::public.membership_status,
        updated_at = timezone('utc', now());

  insert into public.audit_events (
    actor_user_id, actor_role, school_id, action, target_type, target_id,
    new_value, reason
  ) values (
    auth.uid(), 'platform', p_school_id, 'create'::public.audit_action_kind,
    'school_memberships', p_new_user_id::text,
    jsonb_build_object('role', 'school_admin', 'user_id', p_new_user_id),
    v_reason
  );
end;
$$;

revoke all on function public.replace_school_admin(uuid, uuid, text)
  from public, anon;
grant execute on function public.replace_school_admin(uuid, uuid, text)
  to authenticated, service_role;

create or replace function public.admin_revoke_user_sessions(
  p_user_id uuid,
  p_reason text,
  p_session_id uuid default null
)
returns integer
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_reason text := btrim(coalesce(p_reason, ''));
  v_count integer := 0;
begin
  if not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NX090',
      message = 'User control is limited to platform staff.';
  end if;

  if v_reason = '' then
    raise exception using
      errcode = 'NX091',
      message = 'A reason is required.';
  end if;

  if not exists (select 1 from public.profiles where id = p_user_id) then
    raise exception using
      errcode = 'NX094',
      message = 'User profile not found.';
  end if;

  update public.device_sessions ds
  set revoked_at = timezone('utc', now())
  where ds.user_id = p_user_id
    and ds.revoked_at is null
    and (p_session_id is null or ds.id = p_session_id);

  get diagnostics v_count = row_count;

  if v_count > 0 then
    insert into public.login_events (user_id, event_kind, user_agent)
    values (
      p_user_id,
      'revoke'::public.login_event_kind,
      'adm03-admin-revoke'
    );

    insert into public.audit_events (
      actor_user_id, actor_role, action, target_type, target_id,
      new_value, reason
    ) values (
      auth.uid(), 'platform', 'revoke'::public.audit_action_kind,
      'device_sessions', p_user_id::text,
      jsonb_build_object(
        'revoked_count', v_count,
        'session_id', p_session_id
      ),
      v_reason
    );
  end if;

  return v_count;
end;
$$;

revoke all on function public.admin_revoke_user_sessions(uuid, text, uuid)
  from public, anon;
grant execute on function public.admin_revoke_user_sessions(uuid, text, uuid)
  to authenticated, service_role;
