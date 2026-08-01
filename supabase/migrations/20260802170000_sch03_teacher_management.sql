-- SCH-03: school-admin teacher list, create, status, CSV import commit.
-- Students stay SCH-04. Assignment matrix stays SCH-05.

create or replace function nano_internal.create_email_auth_user(
  p_email text,
  p_display_name text,
  p_password text,
  p_account_kind text
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public, auth, extensions, nano_internal
as $fn$
declare
  v_id uuid := gen_random_uuid();
  v_email text := lower(btrim(p_email));
  v_name text := btrim(p_display_name);
  v_password text := coalesce(nullif(p_password, ''), '');
begin
  if v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception using errcode = 'NS040', message = 'A valid email is required.';
  end if;
  if v_name = '' then
    raise exception using errcode = 'NS041', message = 'Display name is required.';
  end if;
  if length(v_password) < 8 then
    raise exception using
      errcode = 'NS042',
      message = 'Temporary password must be at least 8 characters.';
  end if;
  if exists (select 1 from auth.users u where lower(u.email) = v_email) then
    raise exception using errcode = 'NS043', message = 'Email already registered.';
  end if;

  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    is_sso_user, is_anonymous
  ) values (
    '00000000-0000-0000-0000-000000000000',
    v_id,
    'authenticated',
    'authenticated',
    v_email,
    crypt(v_password, gen_salt('bf')),
    timezone('utc', now()),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object(
      'display_name', v_name,
      'account_kind', p_account_kind
    ),
    timezone('utc', now()),
    timezone('utc', now()),
    '', '', '', '',
    false,
    false
  );

  insert into auth.identities (
    id, user_id, identity_data, provider, provider_id,
    last_sign_in_at, created_at, updated_at
  ) values (
    gen_random_uuid(),
    v_id,
    jsonb_build_object(
      'sub', v_id::text,
      'email', v_email,
      'email_verified', true
    ),
    'email',
    v_id::text,
    timezone('utc', now()),
    timezone('utc', now()),
    timezone('utc', now())
  );

  return v_id;
end;
$fn$;

revoke all on function nano_internal.create_email_auth_user(text, text, text, text)
  from public, anon;
grant execute on function nano_internal.create_email_auth_user(text, text, text, text)
  to service_role;

create or replace function public.list_school_teachers(p_query text default '')
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
        sm.created_at
      from public.school_memberships sm
      join public.profiles p on p.id = sm.user_id
      join auth.users u on u.id = p.id
      where sm.school_id = v_school_id
        and sm.role = 'teacher'::public.membership_role
        and (
          v_q = ''
          or lower(p.display_name) like '%' || v_q || '%'
          or lower(u.email) like '%' || v_q || '%'
        )
    ) t
  ), '[]'::jsonb);
end;
$fn$;

revoke all on function public.list_school_teachers(text) from public, anon;
grant execute on function public.list_school_teachers(text)
  to authenticated, service_role;

create or replace function public.create_school_teacher(
  p_display_name text,
  p_email text,
  p_temp_password text default null
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
begin
  v_school_id := nano_internal.require_school_admin_school_id();
  v_password := coalesce(
    nullif(btrim(p_temp_password), ''),
    'NanoTeach' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 8) || '!'
  );

  v_user_id := nano_internal.create_email_auth_user(
    p_email,
    p_display_name,
    v_password,
    'teacher'
  );

  insert into public.profiles (id, display_name, account_kind, status)
  values (
    v_user_id,
    btrim(p_display_name),
    'teacher'::public.account_kind,
    'active'::public.membership_status
  );

  insert into public.school_memberships (school_id, user_id, role, status)
  values (
    v_school_id,
    v_user_id,
    'teacher'::public.membership_role,
    'active'::public.membership_status
  );

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'school_admin', v_school_id,
    'create'::public.audit_action_kind, 'teacher', v_user_id::text,
    jsonb_build_object(
      'display_name', btrim(p_display_name),
      'email', lower(btrim(p_email))
    )
  );

  return jsonb_build_object(
    'teacher', jsonb_build_object(
      'id', v_user_id,
      'display_name', btrim(p_display_name),
      'email', lower(btrim(p_email)),
      'profile_status', 'active',
      'membership_status', 'active'
    ),
    'temp_password', v_password,
    'teachers', public.list_school_teachers('')
  );
end;
$fn$;

revoke all on function public.create_school_teacher(text, text, text)
  from public, anon;
grant execute on function public.create_school_teacher(text, text, text)
  to authenticated, service_role;

create or replace function public.set_school_teacher_status(
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
    and sm.role = 'teacher'::public.membership_role
  for update;
  if not found then
    raise exception using errcode = 'NS046', message = 'Teacher not found in this school.';
  end if;

  v_prev := v_membership.status;

  update public.school_memberships
  set status = v_status, updated_at = timezone('utc', now())
  where id = v_membership.id;

  update public.profiles
  set status = v_status, updated_at = timezone('utc', now())
  where id = p_user_id
    and account_kind = 'teacher'::public.account_kind;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id,
     previous_value, new_value)
  values (
    auth.uid(), 'school_admin', v_school_id,
    case when v_status = 'suspended'
      then 'suspend'::public.audit_action_kind
      else 'restore'::public.audit_action_kind
    end,
    'teacher',
    p_user_id::text,
    jsonb_build_object('status', v_prev::text),
    jsonb_build_object('status', v_status::text, 'reason', btrim(p_reason))
  );

  return public.list_school_teachers('');
end;
$fn$;

revoke all on function public.set_school_teacher_status(uuid, text, text)
  from public, anon;
grant execute on function public.set_school_teacher_status(uuid, text, text)
  to authenticated, service_role;

create or replace function public.preview_teacher_import(p_rows jsonb)
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

    v_seen := array_append(v_seen, v_email);
    v_ok := v_ok || jsonb_build_array(jsonb_build_object(
      'row', v_index,
      'display_name', v_name,
      'email', v_email
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

revoke all on function public.preview_teacher_import(jsonb) from public, anon;
grant execute on function public.preview_teacher_import(jsonb)
  to authenticated, service_role;

create or replace function public.commit_teacher_import(p_rows jsonb)
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
begin
  v_school_id := nano_internal.require_school_admin_school_id();
  v_preview := public.preview_teacher_import(p_rows);

  if (v_preview ->> 'fail_count')::int > 0 then
    return jsonb_build_object(
      'committed', false,
      'message', 'Fix failed rows before commit. Nothing was written.',
      'preview', v_preview,
      'created', '[]'::jsonb,
      'teachers', public.list_school_teachers('')
    );
  end if;

  for v_row in select value from jsonb_array_elements(v_preview -> 'ok_rows')
  loop
    v_password := 'NanoTeach' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 8) || '!';
    v_result := public.create_school_teacher(
      v_row ->> 'display_name',
      v_row ->> 'email',
      v_password
    );
    v_created := v_created || jsonb_build_array(jsonb_build_object(
      'email', v_row ->> 'email',
      'display_name', v_row ->> 'display_name',
      'id', v_result -> 'teacher' ->> 'id',
      'temp_password', v_password
    ));
  end loop;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'school_admin', v_school_id,
    'create'::public.audit_action_kind, 'teacher_import', v_school_id::text,
    jsonb_build_object('created_count', jsonb_array_length(v_created))
  );

  return jsonb_build_object(
    'committed', true,
    'message', 'Import committed.',
    'preview', v_preview,
    'created', v_created,
    'teachers', public.list_school_teachers('')
  );
end;
$fn$;

revoke all on function public.commit_teacher_import(jsonb) from public, anon;
grant execute on function public.commit_teacher_import(jsonb)
  to authenticated, service_role;

comment on function public.list_school_teachers(text) is
  'SCH-03 school-admin teacher directory for the caller school.';
comment on function public.create_school_teacher(text, text, text) is
  'SCH-03 creates auth user + teacher profile + membership.';
comment on function public.set_school_teacher_status(uuid, text, text) is
  'SCH-03 suspend/restore teacher in the caller school.';
comment on function public.preview_teacher_import(jsonb) is
  'SCH-03 validates teacher CSV rows without writing.';
comment on function public.commit_teacher_import(jsonb) is
  'SCH-03 commits only when every row passes preview.';
