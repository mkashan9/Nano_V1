-- SCH-02 RPCs + Overview class_count.

create or replace function public.list_academic_structure()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_school_id uuid;
  v_issues jsonb := '[]'::jsonb;
begin
  v_school_id := nano_internal.require_school_admin_school_id();

  -- Active classes with zero active subject maps.
  select coalesce(jsonb_agg(jsonb_build_object(
    'kind', 'missing_subjects',
    'class_id', c.id,
    'class_name', c.name
  )), '[]'::jsonb)
  into v_issues
  from public.classes c
  where c.school_id = v_school_id
    and c.status = 'active'
    and not exists (
      select 1
      from public.class_subjects cs
      where cs.class_id = c.id
        and cs.status = 'active'
    );

  return jsonb_build_object(
    'school_id', v_school_id,
    'grade_levels', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', g.id,
        'name', g.name,
        'sort_order', g.sort_order,
        'status', g.status::text
      ) order by g.sort_order, g.name)
      from public.grade_levels g
      where g.school_id = v_school_id
    ), '[]'::jsonb),
    'classes', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', c.id,
        'grade_level_id', c.grade_level_id,
        'name', c.name,
        'status', c.status::text
      ) order by c.name)
      from public.classes c
      where c.school_id = v_school_id
    ), '[]'::jsonb),
    'sections', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', s.id,
        'class_id', s.class_id,
        'name', s.name,
        'status', s.status::text
      ) order by s.name)
      from public.sections s
      where s.school_id = v_school_id
    ), '[]'::jsonb),
    'subjects', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', sub.id,
        'name', sub.name,
        'code', sub.code,
        'learning_subject_id', sub.learning_subject_id,
        'status', sub.status::text
      ) order by sub.name)
      from public.school_subjects sub
      where sub.school_id = v_school_id
    ), '[]'::jsonb),
    'class_subjects', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', cs.id,
        'class_id', cs.class_id,
        'section_id', cs.section_id,
        'school_subject_id', cs.school_subject_id,
        'status', cs.status::text
      ) order by cs.created_at)
      from public.class_subjects cs
      where cs.school_id = v_school_id
    ), '[]'::jsonb),
    'mapping_issues', v_issues
  );
end;
$fn$;

revoke all on function public.list_academic_structure() from public, anon;
grant execute on function public.list_academic_structure()
  to authenticated, service_role;

create or replace function public.create_grade_level(
  p_name text,
  p_sort_order integer default 0
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_school_id uuid;
  v_row public.grade_levels%rowtype;
begin
  v_school_id := nano_internal.require_school_admin_school_id();
  if coalesce(nullif(btrim(p_name), ''), '') = '' then
    raise exception using errcode = 'NS020', message = 'Grade name is required.';
  end if;

  insert into public.grade_levels (school_id, name, sort_order)
  values (v_school_id, btrim(p_name), coalesce(p_sort_order, 0))
  returning * into v_row;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'school_admin', v_school_id,
    'create'::public.audit_action_kind, 'grade_level', v_row.id::text,
    jsonb_build_object('name', v_row.name, 'sort_order', v_row.sort_order)
  );

  return public.list_academic_structure();
end;
$fn$;

revoke all on function public.create_grade_level(text, integer) from public, anon;
grant execute on function public.create_grade_level(text, integer)
  to authenticated, service_role;

create or replace function public.create_class(
  p_grade_level_id uuid,
  p_name text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_school_id uuid;
  v_grade public.grade_levels%rowtype;
  v_row public.classes%rowtype;
begin
  v_school_id := nano_internal.require_school_admin_school_id();
  if coalesce(nullif(btrim(p_name), ''), '') = '' then
    raise exception using errcode = 'NS021', message = 'Class name is required.';
  end if;

  select * into v_grade
  from public.grade_levels
  where id = p_grade_level_id and school_id = v_school_id;
  if not found then
    raise exception using errcode = 'NS022', message = 'Unknown grade level.';
  end if;
  if v_grade.status <> 'active' then
    raise exception using
      errcode = 'NS023',
      message = 'Cannot add a class under an archived grade.';
  end if;

  insert into public.classes (school_id, grade_level_id, name)
  values (v_school_id, p_grade_level_id, btrim(p_name))
  returning * into v_row;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'school_admin', v_school_id,
    'create'::public.audit_action_kind, 'class', v_row.id::text,
    jsonb_build_object(
      'name', v_row.name,
      'grade_level_id', v_row.grade_level_id
    )
  );

  return public.list_academic_structure();
end;
$fn$;

revoke all on function public.create_class(uuid, text) from public, anon;
grant execute on function public.create_class(uuid, text)
  to authenticated, service_role;

create or replace function public.create_section(
  p_class_id uuid,
  p_name text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_school_id uuid;
  v_class public.classes%rowtype;
  v_row public.sections%rowtype;
begin
  v_school_id := nano_internal.require_school_admin_school_id();
  if coalesce(nullif(btrim(p_name), ''), '') = '' then
    raise exception using errcode = 'NS024', message = 'Section name is required.';
  end if;

  select * into v_class
  from public.classes
  where id = p_class_id and school_id = v_school_id;
  if not found then
    raise exception using errcode = 'NS025', message = 'Unknown class.';
  end if;
  if v_class.status <> 'active' then
    raise exception using
      errcode = 'NS026',
      message = 'Cannot add a section under an archived class.';
  end if;

  insert into public.sections (school_id, class_id, name)
  values (v_school_id, p_class_id, btrim(p_name))
  returning * into v_row;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'school_admin', v_school_id,
    'create'::public.audit_action_kind, 'section', v_row.id::text,
    jsonb_build_object('name', v_row.name, 'class_id', v_row.class_id)
  );

  return public.list_academic_structure();
end;
$fn$;

revoke all on function public.create_section(uuid, text) from public, anon;
grant execute on function public.create_section(uuid, text)
  to authenticated, service_role;

create or replace function public.create_school_subject(
  p_name text,
  p_code text,
  p_learning_subject_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_school_id uuid;
  v_row public.school_subjects%rowtype;
begin
  v_school_id := nano_internal.require_school_admin_school_id();
  if coalesce(nullif(btrim(p_name), ''), '') = '' then
    raise exception using errcode = 'NS027', message = 'Subject name is required.';
  end if;
  if coalesce(nullif(btrim(p_code), ''), '') = '' then
    raise exception using errcode = 'NS028', message = 'Subject code is required.';
  end if;

  if p_learning_subject_id is not null
     and not exists (
       select 1 from public.learning_subjects ls where ls.id = p_learning_subject_id
     ) then
    raise exception using
      errcode = 'NS029',
      message = 'Unknown platform learning subject.';
  end if;

  insert into public.school_subjects
    (school_id, name, code, learning_subject_id)
  values (
    v_school_id,
    btrim(p_name),
    upper(btrim(p_code)),
    p_learning_subject_id
  )
  returning * into v_row;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'school_admin', v_school_id,
    'create'::public.audit_action_kind, 'school_subject', v_row.id::text,
    jsonb_build_object('name', v_row.name, 'code', v_row.code)
  );

  return public.list_academic_structure();
end;
$fn$;

revoke all on function public.create_school_subject(text, text, uuid)
  from public, anon;
grant execute on function public.create_school_subject(text, text, uuid)
  to authenticated, service_role;

create or replace function public.assign_class_subject(
  p_class_id uuid,
  p_school_subject_id uuid,
  p_section_id uuid default null
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
  v_row public.class_subjects%rowtype;
begin
  v_school_id := nano_internal.require_school_admin_school_id();

  select * into v_class
  from public.classes
  where id = p_class_id and school_id = v_school_id;
  if not found or v_class.status <> 'active' then
    raise exception using
      errcode = 'NS030',
      message = 'Subject maps require an active class.';
  end if;

  select * into v_subject
  from public.school_subjects
  where id = p_school_subject_id and school_id = v_school_id;
  if not found or v_subject.status <> 'active' then
    raise exception using
      errcode = 'NS031',
      message = 'Subject maps require an active school subject.';
  end if;

  if p_section_id is not null then
    select * into v_section
    from public.sections
    where id = p_section_id
      and class_id = p_class_id
      and school_id = v_school_id;
    if not found or v_section.status <> 'active' then
      raise exception using
        errcode = 'NS032',
        message = 'Section must belong to the class and be active.';
    end if;
  end if;

  insert into public.class_subjects
    (school_id, class_id, section_id, school_subject_id)
  values (v_school_id, p_class_id, p_section_id, p_school_subject_id)
  returning * into v_row;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'school_admin', v_school_id,
    'create'::public.audit_action_kind, 'class_subject', v_row.id::text,
    jsonb_build_object(
      'class_id', v_row.class_id,
      'section_id', v_row.section_id,
      'school_subject_id', v_row.school_subject_id
    )
  );

  return public.list_academic_structure();
end;
$fn$;

revoke all on function public.assign_class_subject(uuid, uuid, uuid)
  from public, anon;
grant execute on function public.assign_class_subject(uuid, uuid, uuid)
  to authenticated, service_role;

create or replace function public.archive_academic_structure(
  p_kind text,
  p_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_school_id uuid;
  v_kind text := lower(btrim(p_kind));
  v_found boolean := false;
begin
  v_school_id := nano_internal.require_school_admin_school_id();

  if v_kind = 'grade_level' then
    update public.grade_levels
    set status = 'archived',
        archived_at = timezone('utc', now()),
        updated_at = timezone('utc', now())
    where id = p_id and school_id = v_school_id and status = 'active';
    v_found := found;
  elsif v_kind = 'class' then
    update public.classes
    set status = 'archived',
        archived_at = timezone('utc', now()),
        updated_at = timezone('utc', now())
    where id = p_id and school_id = v_school_id and status = 'active';
    v_found := found;
  elsif v_kind = 'section' then
    update public.sections
    set status = 'archived',
        archived_at = timezone('utc', now()),
        updated_at = timezone('utc', now())
    where id = p_id and school_id = v_school_id and status = 'active';
    v_found := found;
  elsif v_kind = 'school_subject' then
    update public.school_subjects
    set status = 'archived',
        archived_at = timezone('utc', now()),
        updated_at = timezone('utc', now())
    where id = p_id and school_id = v_school_id and status = 'active';
    v_found := found;
  elsif v_kind = 'class_subject' then
    update public.class_subjects
    set status = 'archived',
        archived_at = timezone('utc', now()),
        updated_at = timezone('utc', now())
    where id = p_id and school_id = v_school_id and status = 'active';
    v_found := found;
  else
    raise exception using
      errcode = 'NS033',
      message = 'Unknown academic structure kind.';
  end if;

  if not v_found then
    raise exception using
      errcode = 'NS034',
      message = 'Structure not found or already archived.';
  end if;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'school_admin', v_school_id,
    'update'::public.audit_action_kind, v_kind, p_id::text,
    jsonb_build_object('status', 'archived')
  );

  return public.list_academic_structure();
end;
$fn$;

revoke all on function public.archive_academic_structure(text, uuid)
  from public, anon;
grant execute on function public.archive_academic_structure(text, uuid)
  to authenticated, service_role;

-- SCH-01 Overview: real active class count.
create or replace function public.school_dashboard()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_school_id uuid;
  v_school public.schools%rowtype;
  v_has_admin boolean;
  v_branding_ready boolean;
  v_contact_ready boolean;
begin
  if auth.uid() is null then
    raise exception using
      errcode = 'NS010',
      message = 'Sign in required for the school dashboard.';
  end if;

  v_school_id := nano_internal.caller_school_admin_school_id();
  if v_school_id is null then
    raise exception using
      errcode = 'NS011',
      message = 'School dashboard is limited to school administrators.';
  end if;

  select * into v_school from public.schools where id = v_school_id;
  if not found then
    raise exception using errcode = 'NS012', message = 'Unknown school.';
  end if;

  select exists (
    select 1
    from public.school_memberships sm
    where sm.school_id = v_school_id
      and sm.role = 'school_admin'::public.membership_role
      and sm.status = 'active'::public.membership_status
  ) into v_has_admin;

  v_branding_ready :=
    coalesce(nullif(btrim(v_school.primary_color), ''), '') <> ''
    and coalesce(nullif(btrim(coalesce(v_school.display_name, v_school.name)), ''), '')
      <> '';

  v_contact_ready :=
    coalesce(nullif(btrim(v_school.contact_email), ''), '') <> ''
    or coalesce(nullif(btrim(v_school.address_line), ''), '') <> '';

  return jsonb_build_object(
    'school_id', v_school.id,
    'code', v_school.code,
    'name', v_school.name,
    'display_name', coalesce(nullif(v_school.display_name, ''), v_school.name),
    'status', v_school.status::text,
    'logo_url', v_school.logo_url,
    'banner_url', v_school.banner_url,
    'address_line', v_school.address_line,
    'contact_email', v_school.contact_email,
    'contact_phone', v_school.contact_phone,
    'primary_color', v_school.primary_color,
    'secondary_color', v_school.secondary_color,
    'academic_year_label', v_school.academic_year_label,
    'learner_count', (
      select count(*)::int
      from public.school_memberships sm
      where sm.school_id = v_school_id
        and sm.role = 'student'::public.membership_role
        and sm.status = 'active'::public.membership_status
    ),
    'staff_count', (
      select count(*)::int
      from public.school_memberships sm
      where sm.school_id = v_school_id
        and sm.role in (
          'teacher'::public.membership_role,
          'school_admin'::public.membership_role
        )
        and sm.status = 'active'::public.membership_status
    ),
    'teacher_count', (
      select count(*)::int
      from public.school_memberships sm
      where sm.school_id = v_school_id
        and sm.role = 'teacher'::public.membership_role
        and sm.status = 'active'::public.membership_status
    ),
    'class_count', (
      select count(*)::int
      from public.classes c
      where c.school_id = v_school_id
        and c.status = 'active'
    ),
    'setup', jsonb_build_object(
      'has_admin', v_has_admin,
      'branding_ready', v_branding_ready,
      'contact_ready', v_contact_ready,
      'academic_year_ready',
        coalesce(nullif(btrim(v_school.academic_year_label), ''), '') <> '',
      'setup_completed', v_school.setup_completed_at is not null
    )
  );
end;
$fn$;

comment on table public.grade_levels is
  'SCH-02 school grade bands. Archive instead of delete.';
comment on table public.classes is
  'SCH-02 school classes under a grade. Overview class_count reads active rows.';
comment on table public.sections is
  'SCH-02 optional sections under a class.';
comment on table public.school_subjects is
  'SCH-02 school-owned subjects; optional map to platform learning_subjects.';
comment on table public.class_subjects is
  'SCH-02 subject assignment to a class (and optional section).';
