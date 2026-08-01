-- SCH-05: teacher assignment matrix (class/section/subject + dates + coverage).
-- Extends SEC-02 teacher_assignments stubs with real academic FKs.

alter table public.teacher_assignments
  add column if not exists class_id uuid references public.classes (id),
  add column if not exists section_id uuid references public.sections (id),
  add column if not exists school_subject_id uuid references public.school_subjects (id),
  add column if not exists starts_on date not null default (timezone('utc', now())::date),
  add column if not exists ends_on date;

create index if not exists teacher_assignments_class_idx
  on public.teacher_assignments (class_id);
create index if not exists teacher_assignments_subject_idx
  on public.teacher_assignments (school_subject_id);

-- Best-effort backfill for the SEC-02 seed stub (class_label / subject_code).
update public.teacher_assignments ta
set
  class_id = c.id,
  school_subject_id = ss.id,
  class_label = c.name,
  subject_code = ss.code
from public.classes c
join public.school_subjects ss
  on ss.school_id = c.school_id
where ta.school_id = c.school_id
  and ta.class_id is null
  and lower(c.name) = lower(ta.class_label)
  and lower(ss.code) = lower(ta.subject_code);

create or replace function public.list_teacher_assignment_matrix()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_school_id uuid;
  v_assignments jsonb;
  v_teachers jsonb;
  v_classes jsonb;
  v_sections jsonb;
  v_subjects jsonb;
  v_class_subjects jsonb;
  v_uncovered jsonb;
  v_conflicts jsonb;
  v_workload jsonb;
begin
  v_school_id := nano_internal.require_school_admin_school_id();

  select coalesce(jsonb_agg(row_to_json(a)::jsonb order by a.class_label, a.subject_code), '[]'::jsonb)
  into v_assignments
  from (
    select
      ta.id,
      ta.teacher_user_id,
      p.display_name as teacher_name,
      ta.class_id,
      ta.section_id,
      ta.school_subject_id,
      coalesce(c.name, ta.class_label) as class_label,
      coalesce(sec.name, '') as section_name,
      coalesce(ss.code, ta.subject_code) as subject_code,
      coalesce(ss.name, ta.subject_code) as subject_name,
      ta.status::text as status,
      ta.starts_on,
      ta.ends_on,
      ta.created_at
    from public.teacher_assignments ta
    join public.profiles p on p.id = ta.teacher_user_id
    left join public.classes c on c.id = ta.class_id
    left join public.sections sec on sec.id = ta.section_id
    left join public.school_subjects ss on ss.id = ta.school_subject_id
    where ta.school_id = v_school_id
  ) a;

  select coalesce(jsonb_agg(row_to_json(t)::jsonb order by t.display_name), '[]'::jsonb)
  into v_teachers
  from (
    select p.id, p.display_name
    from public.school_memberships sm
    join public.profiles p on p.id = sm.user_id
    where sm.school_id = v_school_id
      and sm.role = 'teacher'::public.membership_role
      and sm.status = 'active'::public.membership_status
      and p.status = 'active'::public.membership_status
  ) t;

  select coalesce(jsonb_agg(row_to_json(c)::jsonb order by c.name), '[]'::jsonb)
  into v_classes
  from (
    select id, name
    from public.classes
    where school_id = v_school_id and status = 'active'
  ) c;

  select coalesce(jsonb_agg(row_to_json(s)::jsonb order by s.name), '[]'::jsonb)
  into v_sections
  from (
    select id, class_id, name
    from public.sections
    where school_id = v_school_id and status = 'active'
  ) s;

  select coalesce(jsonb_agg(row_to_json(ss)::jsonb order by ss.code), '[]'::jsonb)
  into v_subjects
  from (
    select id, name, code
    from public.school_subjects
    where school_id = v_school_id and status = 'active'
  ) ss;

  select coalesce(jsonb_agg(row_to_json(cs)::jsonb order by cs.class_id), '[]'::jsonb)
  into v_class_subjects
  from (
    select id, class_id, section_id, school_subject_id
    from public.class_subjects
    where school_id = v_school_id and status = 'active'
  ) cs;

  select coalesce(jsonb_agg(row_to_json(u)::jsonb), '[]'::jsonb)
  into v_uncovered
  from (
    select
      cs.class_id,
      c.name as class_name,
      cs.section_id,
      sec.name as section_name,
      cs.school_subject_id,
      ss.code as subject_code,
      ss.name as subject_name
    from public.class_subjects cs
    join public.classes c on c.id = cs.class_id
    join public.school_subjects ss on ss.id = cs.school_subject_id
    left join public.sections sec on sec.id = cs.section_id
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
      )
  ) u;

  select coalesce(jsonb_agg(row_to_json(x)::jsonb), '[]'::jsonb)
  into v_conflicts
  from (
    select
      ta.class_id,
      ta.section_id,
      ta.school_subject_id,
      coalesce(c.name, ta.class_label) as class_label,
      coalesce(ss.code, ta.subject_code) as subject_code,
      count(*)::int as teacher_count,
      string_agg(p.display_name, ', ' order by p.display_name) as teacher_names
    from public.teacher_assignments ta
    join public.profiles p on p.id = ta.teacher_user_id
    left join public.classes c on c.id = ta.class_id
    left join public.school_subjects ss on ss.id = ta.school_subject_id
    where ta.school_id = v_school_id
      and ta.status = 'active'::public.membership_status
      and ta.class_id is not null
      and ta.school_subject_id is not null
      and (ta.ends_on is null or ta.ends_on >= timezone('utc', now())::date)
      and ta.starts_on <= timezone('utc', now())::date
    group by ta.class_id, ta.section_id, ta.school_subject_id,
             coalesce(c.name, ta.class_label), coalesce(ss.code, ta.subject_code)
    having count(*) > 1
  ) x;

  select coalesce(jsonb_agg(row_to_json(w)::jsonb order by w.display_name), '[]'::jsonb)
  into v_workload
  from (
    select
      p.id as teacher_user_id,
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
    'assignments', v_assignments,
    'teachers', v_teachers,
    'classes', v_classes,
    'sections', v_sections,
    'subjects', v_subjects,
    'class_subjects', v_class_subjects,
    'uncovered', v_uncovered,
    'conflicts', v_conflicts,
    'workload', v_workload
  );
end;
$fn$;

revoke all on function public.list_teacher_assignment_matrix() from public, anon;
grant execute on function public.list_teacher_assignment_matrix()
  to authenticated, service_role;

create or replace function public.assign_teacher(
  p_teacher_user_id uuid,
  p_class_id uuid,
  p_school_subject_id uuid,
  p_section_id uuid default null,
  p_starts_on date default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_school_id uuid;
  v_class public.classes%rowtype;
  v_subject public.school_subjects%rowtype;
  v_section public.sections%rowtype;
  v_starts date := coalesce(p_starts_on, timezone('utc', now())::date);
  v_id uuid;
begin
  v_school_id := nano_internal.require_school_admin_school_id();

  if not exists (
    select 1
    from public.school_memberships sm
    where sm.school_id = v_school_id
      and sm.user_id = p_teacher_user_id
      and sm.role = 'teacher'::public.membership_role
      and sm.status = 'active'::public.membership_status
  ) then
    raise exception using errcode = 'NS052', message = 'Teacher not found in this school.';
  end if;

  select * into v_class
  from public.classes
  where id = p_class_id and school_id = v_school_id and status = 'active';
  if not found then
    raise exception using errcode = 'NS053', message = 'Active class required.';
  end if;

  select * into v_subject
  from public.school_subjects
  where id = p_school_subject_id and school_id = v_school_id and status = 'active';
  if not found then
    raise exception using errcode = 'NS054', message = 'Active subject required.';
  end if;

  if p_section_id is not null then
    select * into v_section
    from public.sections
    where id = p_section_id
      and class_id = p_class_id
      and school_id = v_school_id
      and status = 'active';
    if not found then
      raise exception using errcode = 'NS055', message = 'Active section required for this class.';
    end if;
  end if;

  if not exists (
    select 1
    from public.class_subjects cs
    where cs.school_id = v_school_id
      and cs.class_id = p_class_id
      and cs.school_subject_id = p_school_subject_id
      and cs.section_id is not distinct from p_section_id
      and cs.status = 'active'
  ) then
    raise exception using
      errcode = 'NS056',
      message = 'Assign a class-subject map on Classes before assigning a teacher.';
  end if;

  if exists (
    select 1
    from public.teacher_assignments ta
    where ta.school_id = v_school_id
      and ta.teacher_user_id = p_teacher_user_id
      and ta.class_id = p_class_id
      and ta.school_subject_id = p_school_subject_id
      and ta.section_id is not distinct from p_section_id
      and ta.status = 'active'::public.membership_status
      and (ta.ends_on is null or ta.ends_on >= v_starts)
  ) then
    raise exception using
      errcode = 'NS057',
      message = 'Teacher already assigned to this class/subject scope.';
  end if;

  insert into public.teacher_assignments (
    school_id, teacher_user_id, class_id, section_id, school_subject_id,
    class_label, subject_code, status, starts_on
  ) values (
    v_school_id, p_teacher_user_id, p_class_id, p_section_id, p_school_subject_id,
    v_class.name, v_subject.code, 'active'::public.membership_status, v_starts
  )
  returning id into v_id;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'school_admin', v_school_id,
    'create'::public.audit_action_kind, 'teacher_assignment', v_id::text,
    jsonb_build_object(
      'teacher_user_id', p_teacher_user_id,
      'class_id', p_class_id,
      'section_id', p_section_id,
      'school_subject_id', p_school_subject_id,
      'starts_on', v_starts
    )
  );

  return public.list_teacher_assignment_matrix();
end;
$fn$;

revoke all on function public.assign_teacher(uuid, uuid, uuid, uuid, date)
  from public, anon;
grant execute on function public.assign_teacher(uuid, uuid, uuid, uuid, date)
  to authenticated, service_role;

create or replace function public.end_teacher_assignment(
  p_assignment_id uuid,
  p_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_school_id uuid;
  v_reason text := btrim(coalesce(p_reason, ''));
  v_row public.teacher_assignments%rowtype;
begin
  v_school_id := nano_internal.require_school_admin_school_id();
  if v_reason = '' then
    raise exception using errcode = 'NS058', message = 'A reason is required.';
  end if;

  select * into v_row
  from public.teacher_assignments
  where id = p_assignment_id and school_id = v_school_id;
  if not found then
    raise exception using errcode = 'NS059', message = 'Assignment not found in this school.';
  end if;
  if v_row.status <> 'active'::public.membership_status then
    raise exception using errcode = 'NS060', message = 'Assignment is already ended.';
  end if;

  update public.teacher_assignments
  set status = 'left'::public.membership_status,
      ends_on = timezone('utc', now())::date,
      updated_at = timezone('utc', now())
  where id = p_assignment_id;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'school_admin', v_school_id,
    'update'::public.audit_action_kind, 'teacher_assignment', p_assignment_id::text,
    jsonb_build_object('status', 'left', 'reason', v_reason)
  );

  return public.list_teacher_assignment_matrix();
end;
$fn$;

revoke all on function public.end_teacher_assignment(uuid, text) from public, anon;
grant execute on function public.end_teacher_assignment(uuid, text)
  to authenticated, service_role;

create or replace function public.replace_teacher_assignment(
  p_assignment_id uuid,
  p_new_teacher_user_id uuid,
  p_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_school_id uuid;
  v_reason text := btrim(coalesce(p_reason, ''));
  v_row public.teacher_assignments%rowtype;
begin
  v_school_id := nano_internal.require_school_admin_school_id();
  if v_reason = '' then
    raise exception using errcode = 'NS058', message = 'A reason is required.';
  end if;

  select * into v_row
  from public.teacher_assignments
  where id = p_assignment_id and school_id = v_school_id;
  if not found then
    raise exception using errcode = 'NS059', message = 'Assignment not found in this school.';
  end if;
  if v_row.status <> 'active'::public.membership_status then
    raise exception using errcode = 'NS060', message = 'Assignment is already ended.';
  end if;
  if v_row.class_id is null or v_row.school_subject_id is null then
    raise exception using
      errcode = 'NS061',
      message = 'Legacy stub assignment cannot be replaced; end it and create a new one.';
  end if;

  perform public.end_teacher_assignment(p_assignment_id, v_reason);

  return public.assign_teacher(
    p_new_teacher_user_id,
    v_row.class_id,
    v_row.school_subject_id,
    v_row.section_id,
    timezone('utc', now())::date
  );
end;
$fn$;

revoke all on function public.replace_teacher_assignment(uuid, uuid, text)
  from public, anon;
grant execute on function public.replace_teacher_assignment(uuid, uuid, text)
  to authenticated, service_role;

comment on function public.list_teacher_assignment_matrix() is
  'SCH-05 school-admin assignment matrix with coverage and workload.';
comment on function public.assign_teacher(uuid, uuid, uuid, uuid, date) is
  'SCH-05 assign teacher to class/subject(/section) with active dates.';
comment on function public.end_teacher_assignment(uuid, text) is
  'SCH-05 end an active assignment with audited reason.';
comment on function public.replace_teacher_assignment(uuid, uuid, text) is
  'SCH-05 replace teacher on a scope without rewriting history authorship.';
