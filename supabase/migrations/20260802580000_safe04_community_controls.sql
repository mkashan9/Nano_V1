-- SAFE-04: school and global community feature controls.
-- Junior / undecided learners never receive communities; senior need platform
-- AND school opt-in (independent: platform only).

create table if not exists public.platform_community_policy (
  id smallint primary key default 1 check (id = 1),
  communities_enabled boolean not null default false,
  updated_by uuid references public.profiles (id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.platform_community_policy is
  'SAFE-04 singleton: platform-wide communities feature switch (default off).';

insert into public.platform_community_policy (id, communities_enabled)
values (1, false)
on conflict (id) do nothing;

alter table public.platform_community_policy enable row level security;

create table if not exists public.school_community_policies (
  school_id uuid primary key references public.schools (id) on delete cascade,
  communities_enabled boolean not null default false,
  updated_by uuid references public.profiles (id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.school_community_policies is
  'SAFE-04 per-school communities switch. Missing row means disabled (opt-in).';

alter table public.school_community_policies enable row level security;

create or replace function nano_internal.current_user_is_senior_learner()
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
  select exists (
    select 1
    from public.student_onboarding so
    where so.user_id = auth.uid()
      and so.experience_track = 'senior'
  );
$$;

revoke all on function nano_internal.current_user_is_senior_learner() from public, anon;
grant execute on function nano_internal.current_user_is_senior_learner() to authenticated, service_role;

create or replace function nano_internal.current_user_communities_allowed()
returns boolean
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_kind public.account_kind;
  v_school uuid;
  v_platform boolean;
  v_school_enabled boolean;
begin
  if auth.uid() is null then
    return false;
  end if;

  -- Explicit senior track only (junior or undecided stay blocked).
  if not nano_internal.current_user_is_senior_learner() then
    return false;
  end if;

  select p.account_kind
    into v_kind
  from public.profiles p
  where p.id = auth.uid()
    and p.status = 'active'::public.membership_status;

  if not found then
    return false;
  end if;

  if v_kind not in (
    'school_student'::public.account_kind,
    'independent_student'::public.account_kind
  ) then
    return false;
  end if;

  select coalesce(pcp.communities_enabled, false)
    into v_platform
  from public.platform_community_policy pcp
  where pcp.id = 1;

  if not coalesce(v_platform, false) then
    return false;
  end if;

  if v_kind = 'independent_student'::public.account_kind then
    return true;
  end if;

  select sm.school_id
    into v_school
  from public.school_memberships sm
  where sm.user_id = auth.uid()
    and sm.role = 'student'::public.membership_role
    and sm.status = 'active'::public.membership_status
  order by sm.created_at
  limit 1;

  if v_school is null then
    return false;
  end if;

  select coalesce(scp.communities_enabled, false)
    into v_school_enabled
  from public.school_community_policies scp
  where scp.school_id = v_school;

  return coalesce(v_school_enabled, false);
end;
$$;

revoke all on function nano_internal.current_user_communities_allowed() from public, anon;
grant execute on function nano_internal.current_user_communities_allowed() to authenticated, service_role;

create or replace function nano_internal.assert_communities_allowed()
returns void
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
begin
  if not nano_internal.current_user_communities_allowed() then
    raise exception 'COMMUNITIES_DISABLED'
      using errcode = 'P0001',
            hint = 'Communities are disabled for this learner (junior track, platform, or school policy).';
  end if;
end;
$$;

revoke all on function nano_internal.assert_communities_allowed() from public, anon;
grant execute on function nano_internal.assert_communities_allowed() to authenticated, service_role;

create or replace function public.my_community_entitlements()
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_kind public.account_kind;
  v_school uuid;
  v_platform boolean := false;
  v_school_enabled boolean := null;
  v_senior boolean := false;
  v_allowed boolean := false;
  v_reason text := 'ok';
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED' using errcode = 'P0001';
  end if;

  v_senior := nano_internal.current_user_is_senior_learner();

  select p.account_kind
    into v_kind
  from public.profiles p
  where p.id = auth.uid();

  select coalesce(pcp.communities_enabled, false)
    into v_platform
  from public.platform_community_policy pcp
  where pcp.id = 1;
  v_platform := coalesce(v_platform, false);

  if v_kind = 'school_student'::public.account_kind then
    select sm.school_id
      into v_school
    from public.school_memberships sm
    where sm.user_id = auth.uid()
      and sm.role = 'student'::public.membership_role
      and sm.status = 'active'::public.membership_status
    order by sm.created_at
    limit 1;

    if v_school is not null then
      select scp.communities_enabled
        into v_school_enabled
      from public.school_community_policies scp
      where scp.school_id = v_school;
      v_school_enabled := coalesce(v_school_enabled, false);
    else
      v_school_enabled := false;
    end if;
  end if;

  v_allowed := nano_internal.current_user_communities_allowed();

  if not v_senior then
    v_reason := 'junior_blocked';
  elsif not v_platform then
    v_reason := 'platform_disabled';
  elsif v_kind = 'school_student'::public.account_kind and not coalesce(v_school_enabled, false) then
    v_reason := 'school_disabled';
  elsif v_kind not in (
    'school_student'::public.account_kind,
    'independent_student'::public.account_kind
  ) then
    v_reason := 'not_learner';
  end if;

  return jsonb_build_object(
    'communities_enabled', v_allowed,
    'platform_enabled', v_platform,
    'school_enabled', v_school_enabled,
    'junior_blocked', not v_senior,
    'reason', v_reason
  );
end;
$$;

revoke all on function public.my_community_entitlements() from public, anon;
grant execute on function public.my_community_entitlements() to authenticated, service_role;

create or replace function public.get_platform_community_policy()
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_row public.platform_community_policy%rowtype;
begin
  if not nano_internal.is_platform_admin() then
    raise exception 'PLATFORM_ADMIN_REQUIRED' using errcode = 'P0001';
  end if;

  select * into v_row from public.platform_community_policy where id = 1;
  if not found then
    return jsonb_build_object(
      'communities_enabled', false,
      'updated_at', null,
      'updated_by', null
    );
  end if;

  return jsonb_build_object(
    'communities_enabled', v_row.communities_enabled,
    'updated_at', v_row.updated_at,
    'updated_by', v_row.updated_by
  );
end;
$$;

revoke all on function public.get_platform_community_policy() from public, anon;
grant execute on function public.get_platform_community_policy() to authenticated, service_role;

create or replace function public.upsert_platform_community_policy(p_enabled boolean)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_row public.platform_community_policy%rowtype;
begin
  if not nano_internal.is_platform_admin() then
    raise exception 'PLATFORM_ADMIN_REQUIRED' using errcode = 'P0001';
  end if;

  insert into public.platform_community_policy as pcp (id, communities_enabled, updated_by, updated_at)
  values (1, coalesce(p_enabled, false), auth.uid(), timezone('utc', now()))
  on conflict (id) do update
    set communities_enabled = excluded.communities_enabled,
        updated_by = excluded.updated_by,
        updated_at = excluded.updated_at
  returning * into v_row;

  return jsonb_build_object(
    'communities_enabled', v_row.communities_enabled,
    'updated_at', v_row.updated_at,
    'updated_by', v_row.updated_by
  );
end;
$$;

revoke all on function public.upsert_platform_community_policy(boolean) from public, anon;
grant execute on function public.upsert_platform_community_policy(boolean) to authenticated, service_role;

create or replace function public.get_school_community_policy(p_school_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_enabled boolean := false;
  v_updated_at timestamptz;
  v_updated_by uuid;
begin
  if p_school_id is null then
    raise exception 'SCHOOL_REQUIRED' using errcode = 'P0001';
  end if;

  if nano_internal.is_platform_admin() then
    null;
  elsif nano_internal.caller_school_admin_school_id() = p_school_id then
    null;
  else
    raise exception 'SCHOOL_ADMIN_REQUIRED' using errcode = 'P0001';
  end if;

  select scp.communities_enabled, scp.updated_at, scp.updated_by
    into v_enabled, v_updated_at, v_updated_by
  from public.school_community_policies scp
  where scp.school_id = p_school_id;

  return jsonb_build_object(
    'school_id', p_school_id,
    'communities_enabled', coalesce(v_enabled, false),
    'updated_at', v_updated_at,
    'updated_by', v_updated_by
  );
end;
$$;

revoke all on function public.get_school_community_policy(uuid) from public, anon;
grant execute on function public.get_school_community_policy(uuid) to authenticated, service_role;

create or replace function public.upsert_school_community_policy(
  p_school_id uuid,
  p_enabled boolean
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_row public.school_community_policies%rowtype;
begin
  if p_school_id is null then
    raise exception 'SCHOOL_REQUIRED' using errcode = 'P0001';
  end if;

  if nano_internal.is_platform_admin() then
    null;
  elsif nano_internal.caller_school_admin_school_id() = p_school_id then
    null;
  else
    raise exception 'SCHOOL_ADMIN_REQUIRED' using errcode = 'P0001';
  end if;

  insert into public.school_community_policies as scp (
    school_id, communities_enabled, updated_by, updated_at
  )
  values (
    p_school_id,
    coalesce(p_enabled, false),
    auth.uid(),
    timezone('utc', now())
  )
  on conflict (school_id) do update
    set communities_enabled = excluded.communities_enabled,
        updated_by = excluded.updated_by,
        updated_at = excluded.updated_at
  returning * into v_row;

  return jsonb_build_object(
    'school_id', v_row.school_id,
    'communities_enabled', v_row.communities_enabled,
    'updated_at', v_row.updated_at,
    'updated_by', v_row.updated_by
  );
end;
$$;

revoke all on function public.upsert_school_community_policy(uuid, boolean) from public, anon;
grant execute on function public.upsert_school_community_policy(uuid, boolean) to authenticated, service_role;

create or replace function public.list_school_community_policies()
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
begin
  if not nano_internal.is_platform_admin() then
    raise exception 'PLATFORM_ADMIN_REQUIRED' using errcode = 'P0001';
  end if;

  return coalesce((
    select jsonb_agg(
      jsonb_build_object(
        'school_id', s.id,
        'school_name', s.name,
        'communities_enabled', coalesce(scp.communities_enabled, false),
        'updated_at', scp.updated_at
      )
      order by s.name
    )
    from public.schools s
    left join public.school_community_policies scp on scp.school_id = s.id
  ), '[]'::jsonb);
end;
$$;

revoke all on function public.list_school_community_policies() from public, anon;
grant execute on function public.list_school_community_policies() to authenticated, service_role;
