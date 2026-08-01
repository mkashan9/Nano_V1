-- SCH-01: school dashboard + branding for school admins.
-- Platform create/status/first-admin stay ADM-02. Classes arrive in SCH-02.

alter table public.schools
  add column if not exists display_name text,
  add column if not exists logo_url text not null default '',
  add column if not exists banner_url text not null default '',
  add column if not exists address_line text not null default '',
  add column if not exists contact_email text not null default '',
  add column if not exists contact_phone text not null default '',
  add column if not exists primary_color text not null default '#2F7BFF'
    check (primary_color ~ '^#[0-9A-Fa-f]{6}$'),
  add column if not exists secondary_color text not null default '#1B4F9C'
    check (secondary_color ~ '^#[0-9A-Fa-f]{6}$'),
  add column if not exists academic_year_label text not null default '',
  add column if not exists setup_completed_at timestamptz;

comment on column public.schools.primary_color is
  'SCH-01 approved brand slot. Safety colors stay in the client design system.';
comment on column public.schools.secondary_color is
  'SCH-01 approved brand slot. Safety colors stay in the client design system.';

update public.schools
set display_name = name
where display_name is null;

create or replace function nano_internal.caller_school_admin_school_id()
returns uuid
language sql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
  select sm.school_id
  from public.school_memberships sm
  where sm.user_id = auth.uid()
    and sm.role = 'school_admin'::public.membership_role
    and sm.status = 'active'::public.membership_status
  order by sm.created_at
  limit 1;
$fn$;

revoke all on function nano_internal.caller_school_admin_school_id()
  from public, anon;
grant execute on function nano_internal.caller_school_admin_school_id()
  to authenticated, service_role;

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
    'class_count', 0,
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

revoke all on function public.school_dashboard() from public, anon;
grant execute on function public.school_dashboard()
  to authenticated, service_role;

comment on function public.school_dashboard() is
  'SCH-01 school-admin overview: safe tenant metrics and branding snapshot.';

create or replace function public.update_school_branding(
  p_display_name text default null,
  p_logo_url text default null,
  p_banner_url text default null,
  p_address_line text default null,
  p_contact_email text default null,
  p_contact_phone text default null,
  p_primary_color text default null,
  p_secondary_color text default null,
  p_academic_year_label text default null,
  p_mark_setup_complete boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_school_id uuid;
  v_prev public.schools%rowtype;
  v_row public.schools%rowtype;
  v_primary text;
  v_secondary text;
begin
  if auth.uid() is null then
    raise exception using
      errcode = 'NS010',
      message = 'Sign in required to update school branding.';
  end if;

  v_school_id := nano_internal.caller_school_admin_school_id();
  if v_school_id is null then
    raise exception using
      errcode = 'NS011',
      message = 'School branding is limited to school administrators.';
  end if;

  select * into v_prev from public.schools where id = v_school_id for update;
  if not found then
    raise exception using errcode = 'NS012', message = 'Unknown school.';
  end if;

  v_primary := coalesce(nullif(btrim(p_primary_color), ''), v_prev.primary_color);
  v_secondary := coalesce(
    nullif(btrim(p_secondary_color), ''),
    v_prev.secondary_color
  );

  if v_primary !~ '^#[0-9A-Fa-f]{6}$' or v_secondary !~ '^#[0-9A-Fa-f]{6}$' then
    raise exception using
      errcode = 'NS013',
      message = 'Brand colors must be #RRGGBB hex values.';
  end if;

  update public.schools
  set
    display_name = coalesce(
      nullif(btrim(p_display_name), ''),
      display_name,
      name
    ),
    logo_url = coalesce(p_logo_url, logo_url),
    banner_url = coalesce(p_banner_url, banner_url),
    address_line = coalesce(p_address_line, address_line),
    contact_email = coalesce(p_contact_email, contact_email),
    contact_phone = coalesce(p_contact_phone, contact_phone),
    primary_color = v_primary,
    secondary_color = v_secondary,
    academic_year_label = coalesce(
      p_academic_year_label,
      academic_year_label
    ),
    setup_completed_at = case
      when p_mark_setup_complete then timezone('utc', now())
      else setup_completed_at
    end,
    updated_at = timezone('utc', now())
  where id = v_school_id
  returning * into v_row;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id,
     previous_value, new_value)
  values (
    auth.uid(),
    'school_admin',
    v_school_id,
    'update'::public.audit_action_kind,
    'school_branding',
    v_school_id::text,
    jsonb_build_object(
      'display_name', v_prev.display_name,
      'primary_color', v_prev.primary_color,
      'secondary_color', v_prev.secondary_color
    ),
    jsonb_build_object(
      'display_name', v_row.display_name,
      'primary_color', v_row.primary_color,
      'secondary_color', v_row.secondary_color,
      'academic_year_label', v_row.academic_year_label
    )
  );

  return public.school_dashboard();
end;
$fn$;

revoke all on function public.update_school_branding(
  text, text, text, text, text, text, text, text, text, boolean
) from public, anon;
grant execute on function public.update_school_branding(
  text, text, text, text, text, text, text, text, text, boolean
) to authenticated, service_role;

comment on function public.update_school_branding(
  text, text, text, text, text, text, text, text, text, boolean
) is
  'SCH-01 school-admin branding write. Does not change school code or status.';
