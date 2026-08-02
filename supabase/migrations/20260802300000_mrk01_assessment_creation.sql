-- MRK-01: teacher assessment creation (draft). Marks entry → MRK-02. Publish → MRK-04.

do $$
begin
  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'assessment_status'
  ) then
    create type public.assessment_status as enum (
      'draft', 'published', 'corrected', 'closed'
    );
  end if;
end $$;

create table if not exists public.assessments (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id),
  teacher_assignment_id uuid not null references public.teacher_assignments (id),
  teacher_user_id uuid not null references public.profiles (id),
  category text not null,
  name text not null,
  assessment_date date not null,
  total_marks numeric(10,2) not null,
  weight numeric(8,2),
  description text not null default '',
  status public.assessment_status not null default 'draft',
  result_period_id uuid references public.result_periods (id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint assessments_category_nonempty check (btrim(category) <> ''),
  constraint assessments_name_nonempty check (btrim(name) <> ''),
  constraint assessments_total_marks_positive check (total_marks > 0),
  constraint assessments_weight_nonnegative check (weight is null or weight >= 0)
);

create index if not exists assessments_assignment_idx
  on public.assessments (teacher_assignment_id, assessment_date desc);

create index if not exists assessments_school_status_idx
  on public.assessments (school_id, status);

create index if not exists assessments_teacher_draft_idx
  on public.assessments (teacher_user_id, status)
  where status = 'draft'::public.assessment_status;

alter table public.assessments enable row level security;

revoke all on table public.assessments from public, anon, authenticated;
grant select, insert, update, delete on table public.assessments to service_role;

drop trigger if exists assessments_set_updated_at on public.assessments;
create trigger assessments_set_updated_at
  before update on public.assessments
  for each row execute function public.set_updated_at();

create or replace function public.teacher_assessments_list(
  p_assignment_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_assignment public.teacher_assignments%rowtype;
  v_items jsonb;
begin
  v_assignment := nano_internal.require_active_teacher_assignment(p_assignment_id);

  select coalesce(jsonb_agg(jsonb_build_object(
    'id', a.id,
    'school_id', a.school_id,
    'teacher_assignment_id', a.teacher_assignment_id,
    'category', a.category,
    'name', a.name,
    'assessment_date', a.assessment_date,
    'total_marks', a.total_marks,
    'weight', a.weight,
    'description', a.description,
    'status', a.status::text,
    'result_period_id', a.result_period_id,
    'created_at', a.created_at,
    'updated_at', a.updated_at
  ) order by a.assessment_date desc, a.created_at desc), '[]'::jsonb)
  into v_items
  from public.assessments a
  where a.teacher_assignment_id = v_assignment.id
    and a.teacher_user_id = auth.uid();

  return jsonb_build_object(
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
    'assessments', v_items,
    'generated_at', timezone('utc', now())
  );
end;
$fn$;

create or replace function public.teacher_assessment_create(
  p_assignment_id uuid,
  p_category text,
  p_name text,
  p_assessment_date date,
  p_total_marks numeric,
  p_weight numeric default null,
  p_description text default '',
  p_result_period_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_assignment public.teacher_assignments%rowtype;
  v_category text := btrim(coalesce(p_category, ''));
  v_name text := btrim(coalesce(p_name, ''));
  v_description text := coalesce(p_description, '');
  v_row public.assessments%rowtype;
begin
  if v_category = '' then
    raise exception using errcode = 'NS090', message = 'Category is required.';
  end if;
  if v_name = '' then
    raise exception using errcode = 'NS091', message = 'Assessment name is required.';
  end if;
  if p_assessment_date is null then
    raise exception using errcode = 'NS092', message = 'Assessment date is required.';
  end if;
  if p_total_marks is null or p_total_marks <= 0 then
    raise exception using errcode = 'NS093', message = 'Total marks must be greater than zero.';
  end if;
  if p_weight is not null and p_weight < 0 then
    raise exception using errcode = 'NS094', message = 'Weight cannot be negative.';
  end if;

  v_assignment := nano_internal.require_active_teacher_assignment(p_assignment_id);

  if p_result_period_id is not null then
    if not exists (
      select 1 from public.result_periods rp
      where rp.id = p_result_period_id
        and rp.school_id = v_assignment.school_id
        and rp.status = 'open'
    ) then
      raise exception using
        errcode = 'NS095',
        message = 'Result period is not open for this school.';
    end if;
  end if;

  insert into public.assessments (
    school_id, teacher_assignment_id, teacher_user_id,
    category, name, assessment_date, total_marks, weight,
    description, status, result_period_id
  ) values (
    v_assignment.school_id, v_assignment.id, auth.uid(),
    v_category, v_name, p_assessment_date, p_total_marks, p_weight,
    v_description, 'draft'::public.assessment_status, p_result_period_id
  )
  returning * into v_row;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'teacher', v_assignment.school_id,
    'create'::public.audit_action_kind, 'assessment', v_row.id::text,
    jsonb_build_object(
      'assignment_id', v_assignment.id,
      'category', v_category,
      'name', v_name,
      'assessment_date', p_assessment_date,
      'total_marks', p_total_marks,
      'status', 'draft'
    )
  );

  return public.teacher_assessments_list(v_assignment.id);
end;
$fn$;

create or replace function public.teacher_assessment_update(
  p_assessment_id uuid,
  p_category text,
  p_name text,
  p_assessment_date date,
  p_total_marks numeric,
  p_weight numeric default null,
  p_description text default '',
  p_result_period_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_row public.assessments%rowtype;
  v_assignment public.teacher_assignments%rowtype;
  v_category text := btrim(coalesce(p_category, ''));
  v_name text := btrim(coalesce(p_name, ''));
  v_description text := coalesce(p_description, '');
begin
  if p_assessment_id is null then
    raise exception using errcode = 'NS096', message = 'Assessment id is required.';
  end if;
  if v_category = '' then
    raise exception using errcode = 'NS090', message = 'Category is required.';
  end if;
  if v_name = '' then
    raise exception using errcode = 'NS091', message = 'Assessment name is required.';
  end if;
  if p_assessment_date is null then
    raise exception using errcode = 'NS092', message = 'Assessment date is required.';
  end if;
  if p_total_marks is null or p_total_marks <= 0 then
    raise exception using errcode = 'NS093', message = 'Total marks must be greater than zero.';
  end if;
  if p_weight is not null and p_weight < 0 then
    raise exception using errcode = 'NS094', message = 'Weight cannot be negative.';
  end if;

  select * into v_row
  from public.assessments a
  where a.id = p_assessment_id
  for update;

  if not found then
    raise exception using errcode = 'NS097', message = 'Assessment not found.';
  end if;

  if v_row.teacher_user_id is distinct from auth.uid() then
    raise exception using errcode = 'NS098', message = 'Assessment is not in your scope.';
  end if;

  if v_row.status is distinct from 'draft'::public.assessment_status then
    raise exception using
      errcode = 'NS099',
      message = 'Only draft assessments can be edited.';
  end if;

  v_assignment := nano_internal.require_active_teacher_assignment(v_row.teacher_assignment_id);

  if p_result_period_id is not null then
    if not exists (
      select 1 from public.result_periods rp
      where rp.id = p_result_period_id
        and rp.school_id = v_assignment.school_id
        and rp.status = 'open'
    ) then
      raise exception using
        errcode = 'NS095',
        message = 'Result period is not open for this school.';
    end if;
  end if;

  update public.assessments a
  set category = v_category,
      name = v_name,
      assessment_date = p_assessment_date,
      total_marks = p_total_marks,
      weight = p_weight,
      description = v_description,
      result_period_id = p_result_period_id,
      updated_at = timezone('utc', now())
  where a.id = v_row.id;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'teacher', v_assignment.school_id,
    'update'::public.audit_action_kind, 'assessment', v_row.id::text,
    jsonb_build_object(
      'category', v_category,
      'name', v_name,
      'assessment_date', p_assessment_date,
      'total_marks', p_total_marks,
      'status', 'draft'
    )
  );

  return public.teacher_assessments_list(v_assignment.id);
end;
$fn$;

revoke all on function public.teacher_assessments_list(uuid) from public, anon;
grant execute on function public.teacher_assessments_list(uuid)
  to authenticated, service_role;

revoke all on function public.teacher_assessment_create(uuid, text, text, date, numeric, numeric, text, uuid)
  from public, anon;
grant execute on function public.teacher_assessment_create(uuid, text, text, date, numeric, numeric, text, uuid)
  to authenticated, service_role;

revoke all on function public.teacher_assessment_update(uuid, text, text, date, numeric, numeric, text, uuid)
  from public, anon;
grant execute on function public.teacher_assessment_update(uuid, text, text, date, numeric, numeric, text, uuid)
  to authenticated, service_role;

-- Refresh TCH-01 draft assessment count from real drafts.
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
  v_pending_attendance int := 0;
  v_draft_assessments int := 0;
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

  select count(*)::int into v_pending_attendance
  from public.teacher_assignments ta
  where ta.school_id = v_school_id
    and ta.teacher_user_id = v_teacher_id
    and ta.status = 'active'::public.membership_status
    and (ta.ends_on is null or ta.ends_on >= timezone('utc', now())::date)
    and ta.starts_on <= timezone('utc', now())::date
    and not exists (
      select 1
      from public.attendance_sessions s
      where s.teacher_assignment_id = ta.id
        and s.session_date = timezone('utc', now())::date
        and s.period_key = 'daily'
        and s.status = 'submitted'::public.attendance_session_status
    );

  select count(*)::int into v_draft_assessments
  from public.assessments a
  where a.school_id = v_school_id
    and a.teacher_user_id = v_teacher_id
    and a.status = 'draft'::public.assessment_status;

  return jsonb_build_object(
    'school_id', v_school_id,
    'school_code', v_school.code,
    'school_name', coalesce(nullif(btrim(v_school.display_name), ''), v_school.name),
    'teacher_id', v_teacher_id,
    'teacher_name', coalesce(v_profile.display_name, ''),
    'active_assignment_count', v_active_count,
    'pending_attendance_count', coalesce(v_pending_attendance, 0),
    'draft_assessment_count', coalesce(v_draft_assessments, 0),
    'unpublished_marks_count', 0,
    'recent_classroom_count', 0,
    'assignments', v_assignments,
    'generated_at', timezone('utc', now())
  );
end;
$fn$;

comment on table public.assessments is
  'MRK-01 teacher assessments (draft creation). Marks/publish deferred.';
comment on function public.teacher_assessments_list(uuid) is
  'MRK-01 list assessments for an active teacher assignment.';
comment on function public.teacher_assessment_create(uuid, text, text, date, numeric, numeric, text, uuid) is
  'MRK-01 create a draft assessment in assignment scope.';
comment on function public.teacher_assessment_update(uuid, text, text, date, numeric, numeric, text, uuid) is
  'MRK-01 update a draft assessment owned by the caller.';
