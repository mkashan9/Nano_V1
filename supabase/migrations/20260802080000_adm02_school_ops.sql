-- ADM-02: create school, set status with reason, assign first school admin.
-- Codes are immutable after insert. Replace-admin waits on ADM-03.

create or replace function nano_internal.managed_school_row(p_school_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select jsonb_build_object(
    'id', sch.id,
    'code', sch.code,
    'name', sch.name,
    'status', sch.status::text,
    'has_school_admin', exists (
      select 1
      from public.school_memberships sm
      where sm.school_id = sch.id
        and sm.role = 'school_admin'::public.membership_role
        and sm.status = 'active'::public.membership_status
    ),
    'learner_count', (
      select count(*)::int
      from public.school_memberships sm
      where sm.school_id = sch.id
        and sm.role = 'student'::public.membership_role
        and sm.status = 'active'::public.membership_status
    ),
    'staff_count', (
      select count(*)::int
      from public.school_memberships sm
      where sm.school_id = sch.id
        and sm.role in (
          'teacher'::public.membership_role,
          'school_admin'::public.membership_role
        )
        and sm.status = 'active'::public.membership_status
    )
  )
  from public.schools sch
  where sch.id = p_school_id;
$$;

create or replace function public.list_managed_schools(p_query text default '')
returns table (
  id uuid,
  code text,
  name text,
  status text,
  has_school_admin boolean,
  learner_count integer,
  staff_count integer
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
      errcode = 'NX080',
      message = 'School management is limited to platform staff.';
  end if;

  return query
  select
    s.id,
    s.code,
    s.name,
    s.status::text,
    exists (
      select 1
      from public.school_memberships sm
      where sm.school_id = s.id
        and sm.role = 'school_admin'::public.membership_role
        and sm.status = 'active'::public.membership_status
    ) as has_school_admin,
    (
      select count(*)::int
      from public.school_memberships sm
      where sm.school_id = s.id
        and sm.role = 'student'::public.membership_role
        and sm.status = 'active'::public.membership_status
    ) as learner_count,
    (
      select count(*)::int
      from public.school_memberships sm
      where sm.school_id = s.id
        and sm.role in (
          'teacher'::public.membership_role,
          'school_admin'::public.membership_role
        )
        and sm.status = 'active'::public.membership_status
    ) as staff_count
  from public.schools s
  where v_q = ''
     or lower(s.name) like '%' || v_q || '%'
     or lower(s.code) like '%' || v_q || '%'
  order by s.name;
end;
$$;

revoke all on function public.list_managed_schools(text) from public, anon;
grant execute on function public.list_managed_schools(text)
  to authenticated, service_role;

create or replace function public.create_school(p_code text, p_name text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_code text := upper(btrim(coalesce(p_code, '')));
  v_name text := btrim(coalesce(p_name, ''));
  v_id uuid;
begin
  if not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NX080',
      message = 'School management is limited to platform staff.';
  end if;

  if v_code !~ '^[A-Z0-9]{3,16}$' then
    raise exception using
      errcode = 'NX081',
      message = 'School code must be 3–16 uppercase letters or digits.';
  end if;

  if v_name = '' then
    raise exception using
      errcode = 'NX082',
      message = 'School name is required.';
  end if;

  insert into public.schools (code, name, status)
  values (v_code, v_name, 'active'::public.school_status)
  returning id into v_id;

  insert into public.audit_events (
    actor_user_id, actor_role, school_id, action, target_type, target_id,
    new_value, reason
  ) values (
    auth.uid(), 'platform', v_id, 'create'::public.audit_action_kind,
    'schools', v_id::text,
    jsonb_build_object('code', v_code, 'name', v_name, 'status', 'active'),
    'create_school'
  );

  return nano_internal.managed_school_row(v_id);
exception
  when unique_violation then
    raise exception using
      errcode = 'NX083',
      message = 'That school code is already in use.';
end;
$$;

revoke all on function public.create_school(text, text) from public, anon;
grant execute on function public.create_school(text, text)
  to authenticated, service_role;

create or replace function public.set_school_status(
  p_school_id uuid,
  p_status text,
  p_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_status public.school_status;
  v_reason text := btrim(coalesce(p_reason, ''));
  v_prev public.schools;
begin
  if not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NX080',
      message = 'School management is limited to platform staff.';
  end if;

  if v_reason = '' then
    raise exception using
      errcode = 'NX084',
      message = 'A reason is required to change school status.';
  end if;

  begin
    v_status := p_status::public.school_status;
  exception when others then
    raise exception using
      errcode = 'NX085',
      message = 'Unknown school status.';
  end;

  select * into v_prev from public.schools where id = p_school_id;
  if v_prev.id is null then
    raise exception using
      errcode = 'NX086',
      message = 'School not found.';
  end if;

  update public.schools
  set status = v_status,
      updated_at = timezone('utc', now())
  where id = p_school_id;

  insert into public.audit_events (
    actor_user_id, actor_role, school_id, action, target_type, target_id,
    previous_value, new_value, reason
  ) values (
    auth.uid(),
    'platform',
    p_school_id,
    case
      when v_status = 'suspended'::public.school_status
        then 'suspend'::public.audit_action_kind
      when v_prev.status = 'suspended'::public.school_status
        and v_status = 'active'::public.school_status
        then 'restore'::public.audit_action_kind
      else 'update'::public.audit_action_kind
    end,
    'schools',
    p_school_id::text,
    jsonb_build_object('status', v_prev.status::text),
    jsonb_build_object('status', v_status::text),
    v_reason
  );

  return nano_internal.managed_school_row(p_school_id);
end;
$$;

revoke all on function public.set_school_status(uuid, text, text)
  from public, anon;
grant execute on function public.set_school_status(uuid, text, text)
  to authenticated, service_role;

create or replace function public.assign_first_school_admin(
  p_school_id uuid,
  p_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_profile public.profiles;
begin
  if not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NX080',
      message = 'School management is limited to platform staff.';
  end if;

  if not exists (select 1 from public.schools where id = p_school_id) then
    raise exception using
      errcode = 'NX086',
      message = 'School not found.';
  end if;

  if exists (
    select 1
    from public.school_memberships sm
    where sm.school_id = p_school_id
      and sm.role = 'school_admin'::public.membership_role
      and sm.status = 'active'::public.membership_status
  ) then
    raise exception using
      errcode = 'NX087',
      message = 'This school already has an administrator.';
  end if;

  select * into v_profile from public.profiles where id = p_user_id;
  if v_profile.id is null then
    raise exception using
      errcode = 'NX088',
      message = 'User profile not found.';
  end if;

  if v_profile.account_kind not in (
    'school_staff'::public.account_kind,
    'platform'::public.account_kind,
    'teacher'::public.account_kind
  ) then
    raise exception using
      errcode = 'NX089',
      message = 'Only staff accounts can be school administrators.';
  end if;

  insert into public.school_memberships (school_id, user_id, role, status)
  values (
    p_school_id,
    p_user_id,
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
    'school_memberships', p_user_id::text,
    jsonb_build_object('role', 'school_admin', 'user_id', p_user_id),
    'assign_first_school_admin'
  );

  return nano_internal.managed_school_row(p_school_id);
end;
$$;

revoke all on function public.assign_first_school_admin(uuid, uuid)
  from public, anon;
grant execute on function public.assign_first_school_admin(uuid, uuid)
  to authenticated, service_role;
