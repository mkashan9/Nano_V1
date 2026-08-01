-- SCH-04: school-admin student list, create, status, enrollment, CSV import.
-- Teachers stay SCH-03. Assignment matrix stays SCH-05.

create table if not exists public.student_enrollments (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  student_user_id uuid not null references public.profiles (id) on delete cascade,
  class_id uuid not null references public.classes (id),
  section_id uuid references public.sections (id),
  status public.membership_status not null default 'active',
  enrolled_at timestamptz not null default timezone('utc', now()),
  left_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists student_enrollments_active_uq
  on public.student_enrollments (school_id, student_user_id)
  where status = 'active';

create index if not exists student_enrollments_school_idx
  on public.student_enrollments (school_id);

alter table public.student_enrollments enable row level security;

drop policy if exists student_enrollments_select_member on public.student_enrollments;
create policy student_enrollments_select_member on public.student_enrollments
  for select to authenticated
  using (nano_internal.is_school_member(school_id));

create or replace function public.list_school_students(p_query text default '')
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, auth, nano_internal
as $fn$
declare
  v_school_id uuid;
  v_q text := lower(btrim(coalesce(p_query, '')));
begin
  v_school_id := nano_internal.require_school_admin_school_id();

  return coalesce((
    select jsonb_agg(row_to_json(t)::jsonb order by t.display_name)
    from (
      select
        p.id,
        p.display_name,
        u.email,
        p.status::text as profile_status,
        sm.status::text as membership_status,
        e.class_id,
        c.name as class_name,
        e.section_id,
        s.name as section_name,
        sm.created_at
      from public.school_memberships sm
      join public.profiles p on p.id = sm.user_id
      join auth.users u on u.id = p.id
      left join lateral (
        select *
        from public.student_enrollments se
        where se.school_id = v_school_id
          and se.student_user_id = p.id
          and se.status = 'active'
        order by se.enrolled_at desc
        limit 1
      ) e on true
      left join public.classes c on c.id = e.class_id
      left join public.sections s on s.id = e.section_id
      where sm.school_id = v_school_id
        and sm.role = 'student'::public.membership_role
        and (
          v_q = ''
          or lower(p.display_name) like '%' || v_q || '%'
          or lower(u.email) like '%' || v_q || '%'
          or lower(coalesce(c.name, '')) like '%' || v_q || '%'
        )
    ) t
  ), '[]'::jsonb);
end;
$fn$;

revoke all on function public.list_school_students(text) from public, anon;
grant execute on function public.list_school_students(text)
  to authenticated, service_role;

create or replace function public.create_school_student(
  p_display_name text,
  p_email text,
  p_temp_password text default null,
  p_class_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, auth, nano_internal
as $fn$
declare
  v_school_id uuid;
  v_user_id uuid;
  v_password text;
  v_class public.classes%rowtype;
begin
  v_school_id := nano_internal.require_school_admin_school_id();
  v_password := coalesce(
    nullif(btrim(p_temp_password), ''),
    'NanoLearn' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 8) || '!'
  );

  if p_class_id is not null then
    select * into v_class
    from public.classes
    where id = p_class_id
      and school_id = v_school_id
      and status = 'active';
    if not found then
      raise exception using
        errcode = 'NS050',
        message = 'Enrollment requires an active class in this school.';
    end if;
  end if;

  v_user_id := nano_internal.create_email_auth_user(
    p_email,
    p_display_name,
    v_password,
    'school_student'
  );

  insert into public.profiles (id, display_name, account_kind, status)
  values (
    v_user_id,
    btrim(p_display_name),
    'school_student'::public.account_kind,
    'active'::public.membership_status
  );

  insert into public.school_memberships (school_id, user_id, role, status)
  values (
    v_school_id,
    v_user_id,
    'student'::public.membership_role,
    'active'::public.membership_status
  );

  if p_class_id is not null then
    insert into public.student_enrollments
      (school_id, student_user_id, class_id, status)
    values (v_school_id, v_user_id, p_class_id, 'active');
  end if;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'school_admin', v_school_id,
    'create'::public.audit_action_kind, 'student', v_user_id::text,
    jsonb_build_object(
      'display_name', btrim(p_display_name),
      'email', lower(btrim(p_email)),
      'class_id', p_class_id
    )
  );

  return jsonb_build_object(
    'student', jsonb_build_object(
      'id', v_user_id,
      'display_name', btrim(p_display_name),
      'email', lower(btrim(p_email)),
      'profile_status', 'active',
      'membership_status', 'active',
      'class_id', p_class_id,
      'class_name', case when p_class_id is null then null else v_class.name end
    ),
    'temp_password', v_password,
    'students', public.list_school_students('')
  );
end;
$fn$;

revoke all on function public.create_school_student(text, text, text, uuid)
  from public, anon;
grant execute on function public.create_school_student(text, text, text, uuid)
  to authenticated, service_role;

create or replace function public.set_school_student_status(
  p_user_id uuid,
  p_status text,
  p_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_school_id uuid;
  v_status public.membership_status;
  v_prev public.membership_status;
  v_membership public.school_memberships%rowtype;
begin
  v_school_id := nano_internal.require_school_admin_school_id();
  if coalesce(nullif(btrim(p_reason), ''), '') = '' then
    raise exception using errcode = 'NS044', message = 'A reason is required.';
  end if;

  v_status := case lower(btrim(p_status))
    when 'active' then 'active'::public.membership_status
    when 'suspended' then 'suspended'::public.membership_status
    else null
  end;
  if v_status is null then
    raise exception using
      errcode = 'NS045',
      message = 'Only active or suspended is allowed.';
  end if;

  select * into v_membership
  from public.school_memberships sm
  where sm.school_id = v_school_id
    and sm.user_id = p_user_id
    and sm.role = 'student'::public.membership_role
  for update;
  if not found then
    raise exception using errcode = 'NS051', message = 'Student not found in this school.';
  end if;

  v_prev := v_membership.status;

  update public.school_memberships
  set status = v_status, updated_at = timezone('utc', now())
  where id = v_membership.id;

  update public.profiles
  set status = v_status, updated_at = timezone('utc', now())
  where id = p_user_id
    and account_kind = 'school_student'::public.account_kind;

  if v_status = 'suspended' then
    update public.student_enrollments
    set status = 'suspended',
        left_at = timezone('utc', now()),
        updated_at = timezone('utc', now())
    where school_id = v_school_id
      and student_user_id = p_user_id
      and status = 'active';
  end if;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id,
     previous_value, new_value)
  values (
    auth.uid(), 'school_admin', v_school_id,
    case when v_status = 'suspended'
      then 'suspend'::public.audit_action_kind
      else 'restore'::public.audit_action_kind
    end,
    'student',
    p_user_id::text,
    jsonb_build_object('status', v_prev::text),
    jsonb_build_object('status', v_status::text, 'reason', btrim(p_reason))
  );

  return public.list_school_students('');
end;
$fn$;

revoke all on function public.set_school_student_status(uuid, text, text)
  from public, anon;
grant execute on function public.set_school_student_status(uuid, text, text)
  to authenticated, service_role;

create or replace function public.enroll_school_student(
  p_user_id uuid,
  p_class_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_school_id uuid;
  v_class public.classes%rowtype;
begin
  v_school_id := nano_internal.require_school_admin_school_id();

  if not exists (
    select 1
    from public.school_memberships sm
    where sm.school_id = v_school_id
      and sm.user_id = p_user_id
      and sm.role = 'student'::public.membership_role
      and sm.status = 'active'
  ) then
    raise exception using errcode = 'NS051', message = 'Student not found in this school.';
  end if;

  select * into v_class
  from public.classes
  where id = p_class_id and school_id = v_school_id and status = 'active';
  if not found then
    raise exception using
      errcode = 'NS050',
      message = 'Enrollment requires an active class in this school.';
  end if;

  update public.student_enrollments
  set status = 'left',
      left_at = timezone('utc', now()),
      updated_at = timezone('utc', now())
  where school_id = v_school_id
    and student_user_id = p_user_id
    and status = 'active';

  insert into public.student_enrollments
    (school_id, student_user_id, class_id, status)
  values (v_school_id, p_user_id, p_class_id, 'active');

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'school_admin', v_school_id,
    'update'::public.audit_action_kind, 'student_enrollment', p_user_id::text,
    jsonb_build_object('class_id', p_class_id)
  );

  return public.list_school_students('');
end;
$fn$;

revoke all on function public.enroll_school_student(uuid, uuid) from public, anon;
grant execute on function public.enroll_school_student(uuid, uuid)
  to authenticated, service_role;

create or replace function public.preview_student_import(p_rows jsonb)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, auth, nano_internal
as $fn$
declare
  v_school_id uuid;
  v_row jsonb;
  v_index int := 0;
  v_email text;
  v_name text;
  v_class_name text;
  v_class_id uuid;
  v_ok jsonb := '[]'::jsonb;
  v_fail jsonb := '[]'::jsonb;
  v_seen text[] := '{}';
begin
  v_school_id := nano_internal.require_school_admin_school_id();
  if p_rows is null or jsonb_typeof(p_rows) <> 'array' then
    raise exception using errcode = 'NS047', message = 'Import rows must be a JSON array.';
  end if;

  for v_row in select value from jsonb_array_elements(p_rows)
  loop
    v_index := v_index + 1;
    v_name := btrim(coalesce(v_row ->> 'display_name', ''));
    v_email := lower(btrim(coalesce(v_row ->> 'email', '')));
    v_class_name := btrim(coalesce(v_row ->> 'class_name', ''));
    v_class_id := null;

    if v_name = '' or v_email = '' then
      v_fail := v_fail || jsonb_build_array(jsonb_build_object(
        'row', v_index, 'email', v_email, 'error', 'display_name and email are required'
      ));
      continue;
    end if;
    if v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
      v_fail := v_fail || jsonb_build_array(jsonb_build_object(
        'row', v_index, 'email', v_email, 'error', 'invalid email'
      ));
      continue;
    end if;
    if v_email = any (v_seen) then
      v_fail := v_fail || jsonb_build_array(jsonb_build_object(
        'row', v_index, 'email', v_email, 'error', 'duplicate in file'
      ));
      continue;
    end if;
    if exists (select 1 from auth.users u where lower(u.email) = v_email) then
      v_fail := v_fail || jsonb_build_array(jsonb_build_object(
        'row', v_index, 'email', v_email, 'error', 'email already registered'
      ));
      continue;
    end if;
    if v_class_name <> '' then
      select c.id into v_class_id
      from public.classes c
      where c.school_id = v_school_id
        and c.status = 'active'
        and lower(c.name) = lower(v_class_name)
      limit 1;
      if v_class_id is null then
        v_fail := v_fail || jsonb_build_array(jsonb_build_object(
          'row', v_index, 'email', v_email, 'error', 'unknown or archived class_name'
        ));
        continue;
      end if;
    end if;

    v_seen := array_append(v_seen, v_email);
    v_ok := v_ok || jsonb_build_array(jsonb_build_object(
      'row', v_index,
      'display_name', v_name,
      'email', v_email,
      'class_name', nullif(v_class_name, ''),
      'class_id', v_class_id
    ));
  end loop;

  return jsonb_build_object(
    'school_id', v_school_id,
    'ok_count', jsonb_array_length(v_ok),
    'fail_count', jsonb_array_length(v_fail),
    'ok_rows', v_ok,
    'failed_rows', v_fail
  );
end;
$fn$;

revoke all on function public.preview_student_import(jsonb) from public, anon;
grant execute on function public.preview_student_import(jsonb)
  to authenticated, service_role;

create or replace function public.commit_student_import(p_rows jsonb)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, auth, nano_internal
as $fn$
declare
  v_school_id uuid;
  v_preview jsonb;
  v_row jsonb;
  v_created jsonb := '[]'::jsonb;
  v_result jsonb;
  v_password text;
  v_class_id uuid;
begin
  v_school_id := nano_internal.require_school_admin_school_id();
  v_preview := public.preview_student_import(p_rows);

  if (v_preview ->> 'fail_count')::int > 0 then
    return jsonb_build_object(
      'committed', false,
      'message', 'Fix failed rows before commit. Nothing was written.',
      'preview', v_preview,
      'created', '[]'::jsonb,
      'students', public.list_school_students('')
    );
  end if;

  for v_row in select value from jsonb_array_elements(v_preview -> 'ok_rows')
  loop
    v_password := 'NanoLearn' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 8) || '!';
    v_class_id := nullif(v_row ->> 'class_id', '')::uuid;
    v_result := public.create_school_student(
      v_row ->> 'display_name',
      v_row ->> 'email',
      v_password,
      v_class_id
    );
    v_created := v_created || jsonb_build_array(jsonb_build_object(
      'email', v_row ->> 'email',
      'display_name', v_row ->> 'display_name',
      'id', v_result -> 'student' ->> 'id',
      'temp_password', v_password,
      'class_name', v_row ->> 'class_name'
    ));
  end loop;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'school_admin', v_school_id,
    'create'::public.audit_action_kind, 'student_import', v_school_id::text,
    jsonb_build_object('created_count', jsonb_array_length(v_created))
  );

  return jsonb_build_object(
    'committed', true,
    'message', 'Import committed.',
    'preview', v_preview,
    'created', v_created,
    'students', public.list_school_students('')
  );
end;
$fn$;

revoke all on function public.commit_student_import(jsonb) from public, anon;
grant execute on function public.commit_student_import(jsonb)
  to authenticated, service_role;

comment on table public.student_enrollments is
  'SCH-04 active class placement for a school student. Archive prior row on transfer.';
comment on function public.list_school_students(text) is
  'SCH-04 school-admin student directory with optional class.';
comment on function public.create_school_student(text, text, text, uuid) is
  'SCH-04 creates auth user + student profile + membership (+ optional class).';
comment on function public.set_school_student_status(uuid, text, text) is
  'SCH-04 suspend/restore student in the caller school.';
comment on function public.enroll_school_student(uuid, uuid) is
  'SCH-04 place/transfer a student into an active class.';
comment on function public.preview_student_import(jsonb) is
  'SCH-04 validates student CSV rows without writing.';
comment on function public.commit_student_import(jsonb) is
  'SCH-04 commits only when every row passes preview.';
