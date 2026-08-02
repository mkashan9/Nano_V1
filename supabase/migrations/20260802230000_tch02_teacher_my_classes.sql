-- TCH-02: teacher My Classes list + assignment-scoped roster (server-guarded).

create or replace function public.teacher_my_classes()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_school_id uuid;
  v_teacher_id uuid := auth.uid();
  v_assignments jsonb;
begin
  v_school_id := nano_internal.require_teacher_school_id();

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

  return jsonb_build_object(
    'school_id', v_school_id,
    'teacher_id', v_teacher_id,
    'assignments', v_assignments,
    'generated_at', timezone('utc', now())
  );
end;
$fn$;

revoke all on function public.teacher_my_classes() from public, anon;
grant execute on function public.teacher_my_classes()
  to authenticated, service_role;

create or replace function public.teacher_class_roster(p_assignment_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_school_id uuid;
  v_teacher_id uuid := auth.uid();
  v_assignment public.teacher_assignments%rowtype;
  v_class_id uuid;
  v_class_label text;
  v_section_name text := '';
  v_subject_code text;
  v_subject_name text;
  v_roster jsonb;
  v_count int := 0;
begin
  if p_assignment_id is null then
    raise exception using errcode = 'NS073', message = 'Assignment id is required.';
  end if;

  v_school_id := nano_internal.require_teacher_school_id();

  select * into v_assignment
  from public.teacher_assignments ta
  where ta.id = p_assignment_id
    and ta.school_id = v_school_id
    and ta.teacher_user_id = v_teacher_id
    and ta.status = 'active'::public.membership_status
    and (ta.ends_on is null or ta.ends_on >= timezone('utc', now())::date)
    and ta.starts_on <= timezone('utc', now())::date;

  if not found then
    raise exception using
      errcode = 'NS074',
      message = 'Assignment is not in your active scope.';
  end if;

  if v_assignment.class_id is not null then
    v_class_id := v_assignment.class_id;
    select c.name into v_class_label from public.classes c where c.id = v_class_id;
  else
    select c.id, c.name into v_class_id, v_class_label
    from public.classes c
    where c.school_id = v_school_id
      and lower(c.name) = lower(v_assignment.class_label)
    order by c.created_at
    limit 1;
  end if;

  v_class_label := coalesce(v_class_label, v_assignment.class_label);

  if v_assignment.section_id is not null then
    select sec.name into v_section_name
    from public.sections sec
    where sec.id = v_assignment.section_id;
  end if;

  if v_assignment.school_subject_id is not null then
    select ss.code, ss.name into v_subject_code, v_subject_name
    from public.school_subjects ss
    where ss.id = v_assignment.school_subject_id;
  end if;
  v_subject_code := coalesce(v_subject_code, v_assignment.subject_code);
  v_subject_name := coalesce(v_subject_name, v_assignment.subject_code);

  if v_class_id is null then
    v_roster := '[]'::jsonb;
  else
    -- Class-scoped roster. Assignment section is display metadata until enrollments use sections.
    select coalesce(jsonb_agg(row_to_json(r)::jsonb order by r.display_name), '[]'::jsonb)
    into v_roster
    from (
      select
        se.student_user_id as id,
        coalesce(p.display_name, '') as display_name,
        se.status::text as enrollment_status,
        se.enrolled_at
      from public.student_enrollments se
      join public.profiles p on p.id = se.student_user_id
      join public.school_memberships sm
        on sm.user_id = se.student_user_id
       and sm.school_id = se.school_id
       and sm.role = 'student'::public.membership_role
       and sm.status = 'active'::public.membership_status
      where se.school_id = v_school_id
        and se.class_id = v_class_id
        and se.status = 'active'::public.membership_status
    ) r;
  end if;

  v_count := coalesce(jsonb_array_length(v_roster), 0);

  return jsonb_build_object(
    'assignment_id', v_assignment.id,
    'school_id', v_school_id,
    'class_id', v_class_id,
    'section_id', v_assignment.section_id,
    'class_label', v_class_label,
    'section_name', coalesce(v_section_name, ''),
    'subject_code', v_subject_code,
    'subject_name', v_subject_name,
    'student_count', v_count,
    'students', v_roster,
    'generated_at', timezone('utc', now())
  );
end;
$fn$;

revoke all on function public.teacher_class_roster(uuid) from public, anon;
grant execute on function public.teacher_class_roster(uuid)
  to authenticated, service_role;

comment on function public.teacher_my_classes() is
  'TCH-02 list active assignment scopes for the signed-in teacher.';
comment on function public.teacher_class_roster(uuid) is
  'TCH-02 assignment-scoped roster; rejects assignments outside active teacher scope.';
