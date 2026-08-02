-- TCH-01: teacher dashboard read model (assigned scope + pending stubs).
-- Class roster detail stays TCH-02. Attendance/marks/classroom counts stay 0 until those modules.

create or replace function nano_internal.require_teacher_school_id()
returns uuid
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_school_id uuid;
begin
  if auth.uid() is null then
    raise exception using errcode = 'NS071', message = 'Authentication required.';
  end if;

  select sm.school_id into v_school_id
  from public.school_memberships sm
  where sm.user_id = auth.uid()
    and sm.role = 'teacher'::public.membership_role
    and sm.status = 'active'::public.membership_status
  order by sm.created_at
  limit 1;

  if v_school_id is null then
    raise exception using errcode = 'NS072', message = 'Active teacher membership required.';
  end if;

  return v_school_id;
end;
$fn$;

revoke all on function nano_internal.require_teacher_school_id() from public, anon;
grant execute on function nano_internal.require_teacher_school_id()
  to authenticated, service_role;

create or replace function public.teacher_dashboard()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_school_id uuid;
  v_teacher_id uuid := auth.uid();
  v_school public.schools%rowtype;
  v_profile public.profiles%rowtype;
  v_assignments jsonb;
  v_active_count int := 0;
begin
  v_school_id := nano_internal.require_teacher_school_id();

  select * into v_school from public.schools where id = v_school_id;
  select * into v_profile from public.profiles where id = v_teacher_id;

  select coalesce(jsonb_agg(row_to_json(a)::jsonb order by a.class_label, a.subject_code), '[]'::jsonb)
  into v_assignments
  from (
    select
      ta.id,
      ta.class_id,
      ta.section_id,
      ta.school_subject_id,
      coalesce(c.name, ta.class_label) as class_label,
      coalesce(sec.name, '') as section_name,
      coalesce(ss.code, ta.subject_code) as subject_code,
      coalesce(ss.name, ta.subject_code) as subject_name,
      ta.status::text as status,
      ta.starts_on,
      ta.ends_on
    from public.teacher_assignments ta
    left join public.classes c on c.id = ta.class_id
    left join public.sections sec on sec.id = ta.section_id
    left join public.school_subjects ss on ss.id = ta.school_subject_id
    where ta.school_id = v_school_id
      and ta.teacher_user_id = v_teacher_id
      and ta.status = 'active'::public.membership_status
      and (ta.ends_on is null or ta.ends_on >= timezone('utc', now())::date)
      and ta.starts_on <= timezone('utc', now())::date
  ) a;

  v_active_count := coalesce(jsonb_array_length(v_assignments), 0);

  return jsonb_build_object(
    'school_id', v_school_id,
    'school_code', v_school.code,
    'school_name', coalesce(nullif(btrim(v_school.display_name), ''), v_school.name),
    'teacher_id', v_teacher_id,
    'teacher_name', coalesce(v_profile.display_name, ''),
    'active_assignment_count', v_active_count,
    'pending_attendance_count', 0,
    'draft_assessment_count', 0,
    'unpublished_marks_count', 0,
    'recent_classroom_count', 0,
    'assignments', v_assignments,
    'generated_at', timezone('utc', now())
  );
end;
$fn$;

revoke all on function public.teacher_dashboard() from public, anon;
grant execute on function public.teacher_dashboard()
  to authenticated, service_role;

comment on function nano_internal.require_teacher_school_id() is
  'TCH-01 resolve active teacher membership school_id for the caller.';
comment on function public.teacher_dashboard() is
  'TCH-01 teacher dashboard: assigned scopes and pending stubs for the caller only.';
