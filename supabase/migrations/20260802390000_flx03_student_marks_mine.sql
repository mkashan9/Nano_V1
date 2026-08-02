-- FLX-03: student read-only view of own published/corrected marks.
-- Draft assessments remain teacher-only.

create or replace function public.student_marks_mine(
  p_from date,
  p_to date
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_from date := coalesce(p_from, (timezone('utc', now()))::date - 90);
  v_to date := coalesce(p_to, (timezone('utc', now()))::date);
  v_results jsonb;
  v_scored integer := 0;
  v_absent integer := 0;
  v_exempt integer := 0;
  v_not_submitted integer := 0;
begin
  if auth.uid() is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  if v_to < v_from then
    raise exception using
      errcode = 'NS134',
      message = 'Marks range end must be on or after the start.';
  end if;

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
      'results', '[]'::jsonb,
      'scored_count', 0,
      'absent_count', 0,
      'exempt_count', 0,
      'not_submitted_count', 0,
      'generated_at', timezone('utc', now())
    );
  end if;

  select coalesce(jsonb_agg(row_to_json(r)::jsonb order by r.assessment_date desc), '[]'::jsonb)
  into v_results
  from (
    select
      a.id as assessment_id,
      e.id as entry_id,
      a.name,
      a.category as category,
      a.assessment_date,
      a.status::text as assessment_status,
      e.status::text as status,
      a.total_marks,
      e.obtained_marks,
      coalesce(e.remarks, '') as remarks,
      a.revision,
      a.published_at,
      coalesce(
        (select ss.code from public.school_subjects ss where ss.id = ta.school_subject_id),
        ta.subject_code
      ) as subject_code,
      coalesce(
        (select c.name from public.classes c where c.id = ta.class_id),
        ta.class_label
      ) as class_label,
      (
        select count(*)::integer
        from public.marks_corrections mc
        where mc.entry_id = e.id
      ) as correction_count,
      (
        select max(mc.corrected_at)
        from public.marks_corrections mc
        where mc.entry_id = e.id
      ) as last_corrected_at
    from public.marks_entries e
    join public.assessments a on a.id = e.assessment_id
    join public.teacher_assignments ta on ta.id = a.teacher_assignment_id
    where e.student_user_id = auth.uid()
      and a.status in (
        'published'::public.assessment_status,
        'corrected'::public.assessment_status
      )
      and a.assessment_date >= v_from
      and a.assessment_date <= v_to
  ) r;

  select
    count(*) filter (where e.status = 'scored'::public.marks_entry_status),
    count(*) filter (where e.status = 'absent'::public.marks_entry_status),
    count(*) filter (where e.status = 'exempt'::public.marks_entry_status),
    count(*) filter (where e.status = 'not_submitted'::public.marks_entry_status)
  into v_scored, v_absent, v_exempt, v_not_submitted
  from public.marks_entries e
  join public.assessments a on a.id = e.assessment_id
  where e.student_user_id = auth.uid()
    and a.status in (
      'published'::public.assessment_status,
      'corrected'::public.assessment_status
    )
    and a.assessment_date >= v_from
    and a.assessment_date <= v_to;

  return jsonb_build_object(
    'from', v_from,
    'to', v_to,
    'results', v_results,
    'scored_count', coalesce(v_scored, 0),
    'absent_count', coalesce(v_absent, 0),
    'exempt_count', coalesce(v_exempt, 0),
    'not_submitted_count', coalesce(v_not_submitted, 0),
    'generated_at', timezone('utc', now())
  );
end;
$fn$;

revoke all on function public.student_marks_mine(date, date)
  from public, anon;
grant execute on function public.student_marks_mine(date, date)
  to authenticated, service_role;

comment on function public.student_marks_mine(date, date) is
  'FLX-03 student self-only published/corrected marks for a date range.';
