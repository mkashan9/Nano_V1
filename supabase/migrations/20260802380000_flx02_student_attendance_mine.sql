-- FLX-02: student read-only view of own submitted attendance.
-- Draft sessions remain teacher-only. Independents get empty/denied via auth.

create or replace function public.student_attendance_mine(
  p_from date,
  p_to date
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_from date := coalesce(p_from, (timezone('utc', now()))::date - 30);
  v_to date := coalesce(p_to, (timezone('utc', now()))::date);
  v_days jsonb;
  v_present integer := 0;
  v_absent integer := 0;
  v_late integer := 0;
  v_leave integer := 0;
  v_excused integer := 0;
begin
  if auth.uid() is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  if v_to < v_from then
    raise exception using
      errcode = 'NS133',
      message = 'Attendance range end must be on or after the start.';
  end if;

  -- School-linked students only (membership). Independents have no rows.
  if not exists (
    select 1
    from public.school_memberships sm
    where sm.user_id = auth.uid()
      and sm.role = 'student'::public.membership_role
      and sm.status = 'active'::public.membership_status
  ) then
    return jsonb_build_object(
      'from', v_from,
      'to', v_to,
      'days', '[]'::jsonb,
      'present_count', 0,
      'absent_count', 0,
      'late_count', 0,
      'leave_count', 0,
      'excused_count', 0,
      'generated_at', timezone('utc', now())
    );
  end if;

  select coalesce(jsonb_agg(row_to_json(r)::jsonb order by r.session_date desc), '[]'::jsonb)
  into v_days
  from (
    select
      s.session_date,
      e.status::text as status,
      s.period_key,
      coalesce(
        (select ss.code from public.school_subjects ss where ss.id = ta.school_subject_id),
        ta.subject_code
      ) as subject_code,
      coalesce(
        (select c.name from public.classes c where c.id = ta.class_id),
        ta.class_label
      ) as class_label
    from public.attendance_entries e
    join public.attendance_sessions s on s.id = e.session_id
    join public.teacher_assignments ta on ta.id = s.teacher_assignment_id
    where e.student_user_id = auth.uid()
      and s.status = 'submitted'::public.attendance_session_status
      and s.session_date >= v_from
      and s.session_date <= v_to
  ) r;

  select
    count(*) filter (where e.status = 'present'::public.attendance_entry_status),
    count(*) filter (where e.status = 'absent'::public.attendance_entry_status),
    count(*) filter (where e.status = 'late'::public.attendance_entry_status),
    count(*) filter (where e.status = 'leave'::public.attendance_entry_status),
    count(*) filter (where e.status = 'excused'::public.attendance_entry_status)
  into v_present, v_absent, v_late, v_leave, v_excused
  from public.attendance_entries e
  join public.attendance_sessions s on s.id = e.session_id
  where e.student_user_id = auth.uid()
    and s.status = 'submitted'::public.attendance_session_status
    and s.session_date >= v_from
    and s.session_date <= v_to;

  return jsonb_build_object(
    'from', v_from,
    'to', v_to,
    'days', v_days,
    'present_count', coalesce(v_present, 0),
    'absent_count', coalesce(v_absent, 0),
    'late_count', coalesce(v_late, 0),
    'leave_count', coalesce(v_leave, 0),
    'excused_count', coalesce(v_excused, 0),
    'generated_at', timezone('utc', now())
  );
end;
$fn$;

revoke all on function public.student_attendance_mine(date, date)
  from public, anon;
grant execute on function public.student_attendance_mine(date, date)
  to authenticated, service_role;

comment on function public.student_attendance_mine(date, date) is
  'FLX-02 student self-only submitted attendance for a date range.';
