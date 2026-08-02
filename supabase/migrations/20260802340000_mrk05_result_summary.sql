-- MRK-05: teacher result / class performance summary for published assessments.

create or replace function public.teacher_marks_result_summary(p_assessment_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_assessment public.assessments%rowtype;
  v_assignment public.teacher_assignments%rowtype;
  v_passing numeric := 40;
  v_format text := 'both';
  v_bands jsonb := '[
    {"min":90,"label":"A+"},{"min":80,"label":"A"},{"min":70,"label":"B"},
    {"min":60,"label":"C"},{"min":50,"label":"D"},{"min":0,"label":"F"}
  ]'::jsonb;
  v_period_name text := null;
  v_roster_count integer := 0;
  v_students jsonb := '[]'::jsonb;
  v_grades jsonb := '[]'::jsonb;
  v_scored integer := 0;
  v_absent integer := 0;
  v_exempt integer := 0;
  v_not_submitted integer := 0;
  v_pass integer := 0;
  v_fail integer := 0;
  v_avg numeric := null;
  v_median numeric := null;
  v_high numeric := null;
  v_low numeric := null;
  v_percents numeric[] := '{}'::numeric[];
  v_row record;
  v_percent numeric;
  v_grade text;
  v_passed boolean;
  v_status text;
  v_n integer;
begin
  if p_assessment_id is null then
    raise exception using errcode = 'NS096', message = 'Assessment id is required.';
  end if;

  select * into v_assessment
  from public.assessments a
  where a.id = p_assessment_id;

  if not found then
    raise exception using errcode = 'NS097', message = 'Assessment not found.';
  end if;

  if v_assessment.teacher_user_id is distinct from auth.uid() then
    raise exception using errcode = 'NS098', message = 'Assessment is not in your scope.';
  end if;

  if v_assessment.status not in (
    'published'::public.assessment_status,
    'corrected'::public.assessment_status
  ) then
    raise exception using
      errcode = 'NS115',
      message = 'Result summary is only available for published assessments.';
  end if;

  v_assignment := nano_internal.require_active_teacher_assignment(
    v_assessment.teacher_assignment_id
  );

  select
    coalesce(smp.passing_percent, 40),
    coalesce(smp.report_card_format, 'both'),
    coalesce(smp.grade_bands, v_bands)
  into v_passing, v_format, v_bands
  from public.school_marks_policies smp
  where smp.school_id = v_assignment.school_id;

  if v_assessment.result_period_id is not null then
    select rp.name into v_period_name
    from public.result_periods rp
    where rp.id = v_assessment.result_period_id;
  end if;

  select count(*) into v_roster_count
  from nano_internal.attendance_roster_for_assignment(v_assignment) r;

  for v_row in
    select
      r.student_user_id,
      coalesce(r.display_name, '') as display_name,
      e.status,
      e.obtained_marks
    from nano_internal.attendance_roster_for_assignment(v_assignment) r
    left join public.marks_entries e
      on e.assessment_id = v_assessment.id
     and e.student_user_id = r.student_user_id
    order by coalesce(r.display_name, '')
  loop
    v_status := coalesce(v_row.status::text, 'not_submitted');
    v_percent := null;
    v_grade := null;
    v_passed := null;

    if v_status = 'scored' then
      v_scored := v_scored + 1;
      if v_row.obtained_marks is not null and v_assessment.total_marks > 0 then
        v_percent := round(
          (v_row.obtained_marks / v_assessment.total_marks) * 100.0, 2
        );
        select b->>'label' into v_grade
        from jsonb_array_elements(v_bands) b
        where v_percent >= (b->>'min')::numeric
        order by (b->>'min')::numeric desc
        limit 1;
        v_passed := v_percent >= v_passing;
        if v_passed then
          v_pass := v_pass + 1;
        else
          v_fail := v_fail + 1;
        end if;
        v_percents := array_append(v_percents, v_percent);
      end if;
    elsif v_status = 'absent' then
      v_absent := v_absent + 1;
    elsif v_status = 'exempt' then
      v_exempt := v_exempt + 1;
    else
      v_not_submitted := v_not_submitted + 1;
    end if;

    v_students := v_students || jsonb_build_array(jsonb_build_object(
      'student_user_id', v_row.student_user_id,
      'display_name', v_row.display_name,
      'status', v_status,
      'obtained_marks', v_row.obtained_marks,
      'percent', v_percent,
      'passed', v_passed,
      'grade_label', v_grade
    ));
  end loop;

  v_n := coalesce(array_length(v_percents, 1), 0);
  if v_n > 0 then
    select avg(p), max(p), min(p)
    into v_avg, v_high, v_low
    from unnest(v_percents) p;
    v_percents := (select array_agg(p order by p) from unnest(v_percents) p);
    if v_n % 2 = 1 then
      v_median := v_percents[(v_n + 1) / 2];
    else
      v_median := round((v_percents[v_n / 2] + v_percents[v_n / 2 + 1]) / 2.0, 2);
    end if;
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'label', b->>'label',
    'count', (
      select count(*)
      from jsonb_array_elements(v_students) s
      where s->>'grade_label' = b->>'label'
    )
  ) order by (b->>'min')::numeric desc), '[]'::jsonb)
  into v_grades
  from jsonb_array_elements(v_bands) b;

  return jsonb_build_object(
    'assessment_id', v_assessment.id,
    'assignment_id', v_assignment.id,
    'school_id', v_assignment.school_id,
    'class_label', coalesce(
      (select c.name from public.classes c where c.id = v_assignment.class_id),
      v_assignment.class_label
    ),
    'subject_code', coalesce(
      (select ss.code from public.school_subjects ss where ss.id = v_assignment.school_subject_id),
      v_assignment.subject_code
    ),
    'assessment_name', v_assessment.name,
    'assessment_status', v_assessment.status::text,
    'total_marks', v_assessment.total_marks,
    'result_period_id', v_assessment.result_period_id,
    'result_period_name', v_period_name,
    'passing_percent', v_passing,
    'report_card_format', v_format,
    'roster_count', v_roster_count,
    'scored_count', v_scored,
    'absent_count', v_absent,
    'exempt_count', v_exempt,
    'not_submitted_count', v_not_submitted,
    'average_percent', round(coalesce(v_avg, 0)::numeric, 2),
    'median_percent', v_median,
    'highest_percent', v_high,
    'lowest_percent', v_low,
    'pass_count', v_pass,
    'fail_count', v_fail,
    'pass_rate_percent', case
      when v_scored = 0 then null
      else round((v_pass::numeric / v_scored) * 100.0, 2)
    end,
    'grade_distribution', v_grades,
    'students', v_students,
    'generated_at', timezone('utc', now())
  );
end;
$fn$;

revoke all on function public.teacher_marks_result_summary(uuid) from public, anon;
grant execute on function public.teacher_marks_result_summary(uuid)
  to authenticated, service_role;

comment on function public.teacher_marks_result_summary(uuid) is
  'MRK-05 privacy-safe class performance summary for a published/corrected assessment.';
