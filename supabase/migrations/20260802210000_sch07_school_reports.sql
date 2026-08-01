-- SCH-07: school-admin operational reports (privacy-safe aggregates).
-- Marks PDFs / attendance grids stay MRK/ATT. Platform analytics stays ADM-08.

create or replace function public.school_reports_summary()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_school_id uuid;
  v_learners int := 0;
  v_teachers int := 0;
  v_staff int := 0;
  v_classes int := 0;
  v_subjects int := 0;
  v_class_subjects int := 0;
  v_uncovered int := 0;
  v_assignments int := 0;
  v_teachers_assigned int := 0;
  v_enrolled int := 0;
  v_unenrolled int := 0;
  v_open_periods int := 0;
  v_closed_periods int := 0;
  v_policy public.school_marks_policies%rowtype;
  v_workload jsonb;
begin
  v_school_id := nano_internal.require_school_admin_school_id();

  select count(*)::int into v_learners
  from public.school_memberships sm
  where sm.school_id = v_school_id
    and sm.role = 'student'::public.membership_role
    and sm.status = 'active'::public.membership_status;

  select count(*)::int into v_teachers
  from public.school_memberships sm
  where sm.school_id = v_school_id
    and sm.role = 'teacher'::public.membership_role
    and sm.status = 'active'::public.membership_status;

  select count(*)::int into v_staff
  from public.school_memberships sm
  where sm.school_id = v_school_id
    and sm.role = 'school_admin'::public.membership_role
    and sm.status = 'active'::public.membership_status;

  select count(*)::int into v_classes
  from public.classes c
  where c.school_id = v_school_id and c.status = 'active';

  select count(*)::int into v_subjects
  from public.school_subjects ss
  where ss.school_id = v_school_id and ss.status = 'active';

  select count(*)::int into v_class_subjects
  from public.class_subjects cs
  where cs.school_id = v_school_id and cs.status = 'active';

  select count(*)::int into v_uncovered
  from public.class_subjects cs
  where cs.school_id = v_school_id
    and cs.status = 'active'
    and not exists (
      select 1
      from public.teacher_assignments ta
      where ta.school_id = v_school_id
        and ta.status = 'active'::public.membership_status
        and ta.class_id = cs.class_id
        and ta.school_subject_id = cs.school_subject_id
        and ta.section_id is not distinct from cs.section_id
        and (ta.ends_on is null or ta.ends_on >= timezone('utc', now())::date)
        and ta.starts_on <= timezone('utc', now())::date
    );

  select count(*)::int into v_assignments
  from public.teacher_assignments ta
  where ta.school_id = v_school_id
    and ta.status = 'active'::public.membership_status
    and (ta.ends_on is null or ta.ends_on >= timezone('utc', now())::date)
    and ta.starts_on <= timezone('utc', now())::date;

  select count(distinct ta.teacher_user_id)::int into v_teachers_assigned
  from public.teacher_assignments ta
  where ta.school_id = v_school_id
    and ta.status = 'active'::public.membership_status
    and (ta.ends_on is null or ta.ends_on >= timezone('utc', now())::date)
    and ta.starts_on <= timezone('utc', now())::date;

  select count(*)::int into v_enrolled
  from public.school_memberships sm
  where sm.school_id = v_school_id
    and sm.role = 'student'::public.membership_role
    and sm.status = 'active'::public.membership_status
    and exists (
      select 1
      from public.student_enrollments se
      where se.school_id = v_school_id
        and se.student_user_id = sm.user_id
        and se.status = 'active'
    );

  v_unenrolled := greatest(v_learners - v_enrolled, 0);

  select count(*)::int into v_open_periods
  from public.result_periods rp
  where rp.school_id = v_school_id and rp.status = 'open';

  select count(*)::int into v_closed_periods
  from public.result_periods rp
  where rp.school_id = v_school_id and rp.status = 'closed';

  insert into public.school_marks_policies (school_id)
  values (v_school_id)
  on conflict (school_id) do nothing;

  select * into v_policy
  from public.school_marks_policies
  where school_id = v_school_id;

  select coalesce(jsonb_agg(row_to_json(w)::jsonb order by w.active_count desc, w.display_name), '[]'::jsonb)
  into v_workload
  from (
    select
      p.display_name,
      count(ta.id)::int as active_count
    from public.school_memberships sm
    join public.profiles p on p.id = sm.user_id
    left join public.teacher_assignments ta
      on ta.teacher_user_id = p.id
     and ta.school_id = v_school_id
     and ta.status = 'active'::public.membership_status
     and (ta.ends_on is null or ta.ends_on >= timezone('utc', now())::date)
     and ta.starts_on <= timezone('utc', now())::date
    where sm.school_id = v_school_id
      and sm.role = 'teacher'::public.membership_role
      and sm.status = 'active'::public.membership_status
    group by p.id, p.display_name
  ) w;

  return jsonb_build_object(
    'school_id', v_school_id,
    'generated_at', timezone('utc', now()),
    'learner_count', v_learners,
    'teacher_count', v_teachers,
    'staff_count', v_staff,
    'class_count', v_classes,
    'subject_count', v_subjects,
    'class_subject_count', v_class_subjects,
    'uncovered_class_subject_count', v_uncovered,
    'active_assignment_count', v_assignments,
    'teachers_with_assignment_count', v_teachers_assigned,
    'students_with_class_count', v_enrolled,
    'students_without_class_count', v_unenrolled,
    'open_period_count', v_open_periods,
    'closed_period_count', v_closed_periods,
    'passing_percent', v_policy.passing_percent,
    'attendance_mode', v_policy.attendance_mode,
    'report_card_format', v_policy.report_card_format,
    'teacher_workload', v_workload
  );
end;
$fn$;

revoke all on function public.school_reports_summary() from public, anon;
grant execute on function public.school_reports_summary()
  to authenticated, service_role;

comment on function public.school_reports_summary() is
  'SCH-07 school-admin privacy-safe operational report aggregates.';
