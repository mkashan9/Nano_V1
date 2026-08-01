-- ADM-01: platform dashboard for superadmins.
--
-- Safe aggregates and school directory search. No email, guardian, marks, or
-- attendance. Privileged writes stay with ADM-02 / ADM-03.

create or replace function public.platform_dashboard(p_query text default '')
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_q text := lower(btrim(coalesce(p_query, '')));
  v_schools jsonb;
  v_audit jsonb;
begin
  if not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NX070',
      message = 'Platform dashboard is limited to platform staff.';
  end if;

  select coalesce(jsonb_agg(row_to_json(s)::jsonb order by s.name), '[]'::jsonb)
  into v_schools
  from (
    select
      sch.id,
      sch.code,
      sch.name,
      sch.status::text as status,
      (
        select count(*)::int
        from public.school_memberships sm
        where sm.school_id = sch.id
          and sm.role = 'student'::public.membership_role
          and sm.status = 'active'::public.membership_status
      ) as learner_count,
      (
        select count(*)::int
        from public.school_memberships sm
        where sm.school_id = sch.id
          and sm.role in (
            'teacher'::public.membership_role,
            'school_admin'::public.membership_role
          )
          and sm.status = 'active'::public.membership_status
      ) as staff_count
    from public.schools sch
    where v_q = ''
       or lower(sch.name) like '%' || v_q || '%'
       or lower(sch.code) like '%' || v_q || '%'
    order by sch.name
    limit 50
  ) s;

  select coalesce(jsonb_agg(row_to_json(a)::jsonb), '[]'::jsonb)
  into v_audit
  from (
    select
      ae.action::text as action,
      ae.target_type,
      ae.created_at,
      sch.code as school_code
    from public.audit_events ae
    left join public.schools sch on sch.id = ae.school_id
    order by ae.created_at desc
    limit 8
  ) a;

  return jsonb_build_object(
    'school_count', (select count(*)::int from public.schools),
    'active_school_count', (
      select count(*)::int
      from public.schools
      where status = 'active'::public.school_status
    ),
    'learner_count', (
      select count(*)::int
      from public.school_memberships
      where role = 'student'::public.membership_role
        and status = 'active'::public.membership_status
    ),
    'staff_count', (
      select count(*)::int
      from public.school_memberships
      where role in (
          'teacher'::public.membership_role,
          'school_admin'::public.membership_role
        )
        and status = 'active'::public.membership_status
    ),
    'suspended_profile_count', (
      select count(*)::int
      from public.profiles
      where status = 'suspended'::public.membership_status
    ),
    'open_incident_count', (
      select count(*)::int
      from public.security_incidents
      where status = 'open'::public.incident_status
    ),
    'schools', v_schools,
    'recent_audit', v_audit
  );
end;
$$;

revoke all on function public.platform_dashboard(text) from public, anon;
grant execute on function public.platform_dashboard(text)
  to authenticated, service_role;

comment on function public.platform_dashboard(text) is
  'ADM-01 superadmin overview: aggregates + safe school search.';
