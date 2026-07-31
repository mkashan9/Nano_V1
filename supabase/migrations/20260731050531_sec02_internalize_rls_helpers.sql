-- SEC-02 follow-up: move SECURITY DEFINER helpers to nano_internal (not in API schema).

create schema if not exists nano_internal;
revoke all on schema nano_internal from public;
grant usage on schema nano_internal to authenticated, service_role;

create or replace function nano_internal.is_platform_admin()
returns boolean language sql stable security definer set search_path = pg_catalog, public, nano_internal
as $$ select exists (select 1 from public.platform_roles pr where pr.user_id = auth.uid() and pr.role = 'superadmin'::public.platform_role_kind and pr.revoked_at is null); $$;

create or replace function nano_internal.is_school_member(p_school_id uuid)
returns boolean language sql stable security definer set search_path = pg_catalog, public, nano_internal
as $$ select exists (select 1 from public.school_memberships sm where sm.school_id = p_school_id and sm.user_id = auth.uid() and sm.status = 'active'::public.membership_status) or nano_internal.is_platform_admin(); $$;

create or replace function nano_internal.has_school_role(p_school_id uuid, p_roles public.membership_role[])
returns boolean language sql stable security definer set search_path = pg_catalog, public, nano_internal
as $$ select exists (select 1 from public.school_memberships sm where sm.school_id = p_school_id and sm.user_id = auth.uid() and sm.status = 'active'::public.membership_status and sm.role = any (p_roles)) or nano_internal.is_platform_admin(); $$;

revoke all on function nano_internal.is_platform_admin() from public, anon;
revoke all on function nano_internal.is_school_member(uuid) from public, anon;
revoke all on function nano_internal.has_school_role(uuid, public.membership_role[]) from public, anon;
grant execute on function nano_internal.is_platform_admin() to authenticated, service_role;
grant execute on function nano_internal.is_school_member(uuid) to authenticated, service_role;
grant execute on function nano_internal.has_school_role(uuid, public.membership_role[]) to authenticated, service_role;

drop policy if exists schools_select_member on public.schools;
create policy schools_select_member on public.schools for select to authenticated using (
  nano_internal.is_platform_admin()
  or exists (
    select 1 from public.school_memberships sm
    where sm.school_id = schools.id
      and sm.user_id = auth.uid()
      and sm.status = 'active'::public.membership_status
  )
);

drop policy if exists profiles_select_self_or_admin on public.profiles;
create policy profiles_select_self_or_admin on public.profiles for select to authenticated using (
  id = auth.uid()
  or nano_internal.is_platform_admin()
  or exists (
    select 1
    from public.school_memberships mine
    join public.school_memberships theirs on theirs.school_id = mine.school_id
    where mine.user_id = auth.uid()
      and mine.status = 'active'::public.membership_status
      and theirs.user_id = profiles.id
      and theirs.status = 'active'::public.membership_status
      and mine.role in ('teacher'::public.membership_role, 'school_admin'::public.membership_role)
  )
);

drop policy if exists memberships_select_scope on public.school_memberships;
create policy memberships_select_scope on public.school_memberships for select to authenticated using (
  user_id = auth.uid()
  or nano_internal.is_platform_admin()
  or nano_internal.has_school_role(school_id, array['teacher'::public.membership_role, 'school_admin'::public.membership_role])
);

drop policy if exists platform_roles_select on public.platform_roles;
create policy platform_roles_select on public.platform_roles for select to authenticated using (
  user_id = auth.uid() or nano_internal.is_platform_admin()
);

drop policy if exists teacher_assignments_select on public.teacher_assignments;
create policy teacher_assignments_select on public.teacher_assignments for select to authenticated using (
  teacher_user_id = auth.uid()
  or nano_internal.is_platform_admin()
  or nano_internal.has_school_role(school_id, array['school_admin'::public.membership_role])
);

drop function if exists public.is_platform_admin();
drop function if exists public.is_school_member(uuid);
drop function if exists public.has_school_role(uuid, public.membership_role[]);
drop function if exists public.requesting_user_id();
drop function if exists public._sec02_as_user(uuid);

update public.app_health
set notes = 'Tenancy RLS helpers in nano_internal',
    updated_at = timezone('utc', now())
where id = 'default';
