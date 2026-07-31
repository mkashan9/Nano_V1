-- SEC-02: Multi-school tenancy core tables + RLS helpers
-- Profiles use UUID PKs that AUTH modules will bind to auth.users.

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
do $$ begin
  create type public.school_status as enum ('active', 'suspended', 'archived');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.membership_role as enum (
    'student',
    'teacher',
    'school_admin'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.membership_status as enum ('active', 'suspended', 'left');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.account_kind as enum (
    'school_student',
    'independent_student',
    'teacher',
    'school_staff',
    'platform'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.platform_role_kind as enum (
    'superadmin',
    'content_ops',
    'support'
  );
exception when duplicate_object then null;
end $$;

-- ---------------------------------------------------------------------------
-- Tables first
-- ---------------------------------------------------------------------------
create table if not exists public.schools (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  name text not null,
  status public.school_status not null default 'active',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint schools_code_format check (code ~ '^[A-Z0-9]{3,16}$'),
  constraint schools_code_unique unique (code)
);

create table if not exists public.profiles (
  id uuid primary key,
  display_name text not null default '',
  account_kind public.account_kind not null,
  status public.membership_status not null default 'active',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.school_memberships (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id),
  user_id uuid not null references public.profiles (id),
  role public.membership_role not null,
  status public.membership_status not null default 'active',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint school_memberships_unique unique (school_id, user_id, role)
);

create table if not exists public.platform_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id),
  role public.platform_role_kind not null,
  granted_at timestamptz not null default timezone('utc', now()),
  revoked_at timestamptz,
  constraint platform_roles_unique unique (user_id, role)
);

create table if not exists public.teacher_assignments (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id),
  teacher_user_id uuid not null references public.profiles (id),
  class_label text not null default '',
  subject_code text not null default '',
  status public.membership_status not null default 'active',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists school_memberships_user_idx
  on public.school_memberships (user_id);
create index if not exists school_memberships_school_idx
  on public.school_memberships (school_id);
create index if not exists teacher_assignments_teacher_idx
  on public.teacher_assignments (teacher_user_id);
create index if not exists teacher_assignments_school_idx
  on public.teacher_assignments (school_id);

drop trigger if exists schools_set_updated_at on public.schools;
create trigger schools_set_updated_at
  before update on public.schools
  for each row execute function public.set_updated_at();

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

drop trigger if exists school_memberships_set_updated_at on public.school_memberships;
create trigger school_memberships_set_updated_at
  before update on public.school_memberships
  for each row execute function public.set_updated_at();

drop trigger if exists teacher_assignments_set_updated_at on public.teacher_assignments;
create trigger teacher_assignments_set_updated_at
  before update on public.teacher_assignments
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Helper functions (after tables; locked search_path)
-- ---------------------------------------------------------------------------
create or replace function public.requesting_user_id()
returns uuid
language sql
stable
set search_path = pg_catalog, public
as $$
  select auth.uid();
$$;

create or replace function public.is_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.platform_roles pr
    where pr.user_id = auth.uid()
      and pr.role = 'superadmin'::public.platform_role_kind
      and pr.revoked_at is null
  );
$$;

create or replace function public.is_school_member(p_school_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.school_memberships sm
    where sm.school_id = p_school_id
      and sm.user_id = auth.uid()
      and sm.status = 'active'::public.membership_status
  )
  or public.is_platform_admin();
$$;

create or replace function public.has_school_role(
  p_school_id uuid,
  p_roles public.membership_role[]
)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.school_memberships sm
    where sm.school_id = p_school_id
      and sm.user_id = auth.uid()
      and sm.status = 'active'::public.membership_status
      and sm.role = any (p_roles)
  )
  or public.is_platform_admin();
$$;

revoke all on function public.is_platform_admin() from public;
revoke all on function public.is_school_member(uuid) from public;
revoke all on function public.has_school_role(uuid, public.membership_role[]) from public;
grant execute on function public.is_platform_admin() to authenticated;
grant execute on function public.is_school_member(uuid) to authenticated;
grant execute on function public.has_school_role(uuid, public.membership_role[]) to authenticated;
grant execute on function public.requesting_user_id() to authenticated;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.schools enable row level security;
alter table public.profiles enable row level security;
alter table public.school_memberships enable row level security;
alter table public.platform_roles enable row level security;
alter table public.teacher_assignments enable row level security;

drop policy if exists schools_select_member on public.schools;
create policy schools_select_member
  on public.schools for select to authenticated
  using (
    public.is_platform_admin()
    or exists (
      select 1 from public.school_memberships sm
      where sm.school_id = schools.id
        and sm.user_id = auth.uid()
        and sm.status = 'active'::public.membership_status
    )
  );

drop policy if exists profiles_select_self_or_admin on public.profiles;
create policy profiles_select_self_or_admin
  on public.profiles for select to authenticated
  using (
    id = auth.uid()
    or public.is_platform_admin()
    or exists (
      select 1
      from public.school_memberships mine
      join public.school_memberships theirs
        on theirs.school_id = mine.school_id
      where mine.user_id = auth.uid()
        and mine.status = 'active'::public.membership_status
        and theirs.user_id = profiles.id
        and theirs.status = 'active'::public.membership_status
        and mine.role in (
          'teacher'::public.membership_role,
          'school_admin'::public.membership_role
        )
    )
  );

drop policy if exists profiles_update_self on public.profiles;
create policy profiles_update_self
  on public.profiles for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

drop policy if exists memberships_select_scope on public.school_memberships;
create policy memberships_select_scope
  on public.school_memberships for select to authenticated
  using (
    user_id = auth.uid()
    or public.is_platform_admin()
    or public.has_school_role(
      school_id,
      array[
        'teacher'::public.membership_role,
        'school_admin'::public.membership_role
      ]
    )
  );

drop policy if exists platform_roles_select on public.platform_roles;
create policy platform_roles_select
  on public.platform_roles for select to authenticated
  using (
    user_id = auth.uid()
    or public.is_platform_admin()
  );

drop policy if exists teacher_assignments_select on public.teacher_assignments;
create policy teacher_assignments_select
  on public.teacher_assignments for select to authenticated
  using (
    teacher_user_id = auth.uid()
    or public.is_platform_admin()
    or public.has_school_role(
      school_id,
      array['school_admin'::public.membership_role]
    )
  );

-- ---------------------------------------------------------------------------
-- Fixture schools for adversarial SQL tests (AUTH binds later)
-- ---------------------------------------------------------------------------
insert into public.schools (id, code, name, status)
values
  ('11111111-1111-1111-1111-111111111111', 'ALPHA01', 'Alpha Academy', 'active'),
  ('22222222-2222-2222-2222-222222222222', 'BETA02', 'Beta School', 'active')
on conflict (id) do nothing;

insert into public.profiles (id, display_name, account_kind, status)
values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Ali Alpha', 'school_student', 'active'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Bina Beta', 'school_student', 'active'),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Ms Khan', 'teacher', 'active'),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Platform Admin', 'platform', 'active'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Indie Ali', 'independent_student', 'active')
on conflict (id) do nothing;

insert into public.school_memberships (school_id, user_id, role, status)
values
  ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'student', 'active'),
  ('22222222-2222-2222-2222-222222222222', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'student', 'active'),
  ('11111111-1111-1111-1111-111111111111', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'teacher', 'active')
on conflict (school_id, user_id, role) do nothing;

insert into public.platform_roles (user_id, role)
values ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'superadmin')
on conflict (user_id, role) do nothing;

insert into public.teacher_assignments (
  school_id, teacher_user_id, class_label, subject_code, status
)
values (
  '11111111-1111-1111-1111-111111111111',
  'cccccccc-cccc-cccc-cccc-cccccccccccc',
  '5-A',
  'MATH',
  'active'
);

update public.app_health
set schema_version = 'SEC-02',
    notes = 'Tenancy tables + RLS helpers',
    updated_at = timezone('utc', now())
where id = 'default';
