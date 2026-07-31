-- SEC-03: audit_events, device_sessions, login_events, security_incidents;
-- tighten tenancy helpers for school/profile suspension; permission helper.

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
do $$ begin
  create type public.audit_action_kind as enum (
    'create',
    'update',
    'delete',
    'revoke',
    'suspend',
    'restore',
    'login',
    'logout',
    'other'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.login_event_kind as enum (
    'success',
    'failure',
    'logout',
    'revoke',
    'blocked_suspended'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.incident_severity as enum (
    'info',
    'low',
    'medium',
    'high',
    'critical'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.incident_status as enum (
    'open',
    'investigating',
    'resolved',
    'dismissed'
  );
exception when duplicate_object then null;
end $$;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------
create table if not exists public.audit_events (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references public.profiles (id),
  actor_role text,
  school_id uuid references public.schools (id),
  action public.audit_action_kind not null default 'other',
  target_type text not null,
  target_id text,
  previous_value jsonb,
  new_value jsonb,
  reason text,
  request_id text,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.device_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id),
  school_id uuid references public.schools (id),
  device_label text not null default '',
  user_agent text,
  last_seen_at timestamptz not null default timezone('utc', now()),
  revoked_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.login_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles (id),
  school_id uuid references public.schools (id),
  event_kind public.login_event_kind not null,
  ip_hint text,
  user_agent text,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.security_incidents (
  id uuid primary key default gen_random_uuid(),
  school_id uuid references public.schools (id),
  severity public.incident_severity not null default 'info',
  title text not null,
  details jsonb,
  status public.incident_status not null default 'open',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists audit_events_school_idx on public.audit_events (school_id, created_at desc);
create index if not exists audit_events_actor_idx on public.audit_events (actor_user_id, created_at desc);
create index if not exists device_sessions_user_idx on public.device_sessions (user_id);
create index if not exists login_events_user_idx on public.login_events (user_id, created_at desc);
create index if not exists security_incidents_school_idx on public.security_incidents (school_id);

drop trigger if exists device_sessions_set_updated_at on public.device_sessions;
create trigger device_sessions_set_updated_at
  before update on public.device_sessions
  for each row execute function public.set_updated_at();

drop trigger if exists security_incidents_set_updated_at on public.security_incidents;
create trigger security_incidents_set_updated_at
  before update on public.security_incidents
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Helpers: suspension-aware access + session validity
-- ---------------------------------------------------------------------------
create or replace function nano_internal.profile_is_active()
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.status = 'active'::public.membership_status
  );
$$;

create or replace function nano_internal.school_is_active(p_school_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
  select exists (
    select 1
    from public.schools s
    where s.id = p_school_id
      and s.status = 'active'::public.school_status
  );
$$;

create or replace function nano_internal.session_is_active(p_session_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
  select exists (
    select 1
    from public.device_sessions ds
    where ds.id = p_session_id
      and ds.user_id = auth.uid()
      and ds.revoked_at is null
  );
$$;

-- Combined permission guard used by policies and future AUTH.
create or replace function nano_internal.can_access_school(p_school_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
  select nano_internal.is_platform_admin()
    or (
      nano_internal.profile_is_active()
      and nano_internal.school_is_active(p_school_id)
      and exists (
        select 1
        from public.school_memberships sm
        where sm.school_id = p_school_id
          and sm.user_id = auth.uid()
          and sm.status = 'active'::public.membership_status
      )
    );
$$;

-- Tighten existing membership helpers for school + profile suspension.
create or replace function nano_internal.is_school_member(p_school_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
  select nano_internal.can_access_school(p_school_id);
$$;

create or replace function nano_internal.has_school_role(
  p_school_id uuid,
  p_roles public.membership_role[]
)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
  select nano_internal.is_platform_admin()
    or (
      nano_internal.profile_is_active()
      and nano_internal.school_is_active(p_school_id)
      and exists (
        select 1
        from public.school_memberships sm
        where sm.school_id = p_school_id
          and sm.user_id = auth.uid()
          and sm.status = 'active'::public.membership_status
          and sm.role = any (p_roles)
      )
    );
$$;

revoke all on function nano_internal.profile_is_active() from public, anon;
revoke all on function nano_internal.school_is_active(uuid) from public, anon;
revoke all on function nano_internal.session_is_active(uuid) from public, anon;
revoke all on function nano_internal.can_access_school(uuid) from public, anon;
grant execute on function nano_internal.profile_is_active() to authenticated, service_role;
grant execute on function nano_internal.school_is_active(uuid) to authenticated, service_role;
grant execute on function nano_internal.session_is_active(uuid) to authenticated, service_role;
grant execute on function nano_internal.can_access_school(uuid) to authenticated, service_role;

-- Re-assert tenancy select policies (helpers now suspension-aware).
drop policy if exists schools_select_member on public.schools;
create policy schools_select_member on public.schools for select to authenticated using (
  nano_internal.is_platform_admin()
  or (
    nano_internal.profile_is_active()
    and status = 'active'::public.school_status
    and exists (
      select 1 from public.school_memberships sm
      where sm.school_id = schools.id
        and sm.user_id = auth.uid()
        and sm.status = 'active'::public.membership_status
    )
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
    join public.schools s on s.id = mine.school_id
    where mine.user_id = auth.uid()
      and mine.status = 'active'::public.membership_status
      and theirs.user_id = profiles.id
      and theirs.status = 'active'::public.membership_status
      and mine.role in ('teacher'::public.membership_role, 'school_admin'::public.membership_role)
      and s.status = 'active'::public.school_status
      and nano_internal.profile_is_active()
  )
);

drop policy if exists memberships_select_scope on public.school_memberships;
create policy memberships_select_scope on public.school_memberships for select to authenticated using (
  user_id = auth.uid()
  or nano_internal.is_platform_admin()
  or nano_internal.has_school_role(
    school_id,
    array['teacher'::public.membership_role, 'school_admin'::public.membership_role]
  )
);

drop policy if exists teacher_assignments_select on public.teacher_assignments;
create policy teacher_assignments_select on public.teacher_assignments for select to authenticated using (
  teacher_user_id = auth.uid()
  or nano_internal.is_platform_admin()
  or nano_internal.has_school_role(
    school_id,
    array['school_admin'::public.membership_role]
  )
);

-- ---------------------------------------------------------------------------
-- RLS on SEC-03 tables (client select; writes via service role / future AUTH)
-- ---------------------------------------------------------------------------
alter table public.audit_events enable row level security;
alter table public.device_sessions enable row level security;
alter table public.login_events enable row level security;
alter table public.security_incidents enable row level security;

drop policy if exists audit_events_select on public.audit_events;
create policy audit_events_select on public.audit_events for select to authenticated using (
  nano_internal.is_platform_admin()
  or (
    school_id is not null
    and nano_internal.has_school_role(
      school_id,
      array['school_admin'::public.membership_role]
    )
  )
);

-- Append-only for ordinary roles: no insert/update/delete policies for authenticated.
-- Service role bypasses RLS for trusted writers.

drop policy if exists device_sessions_select on public.device_sessions;
create policy device_sessions_select on public.device_sessions for select to authenticated using (
  user_id = auth.uid() or nano_internal.is_platform_admin()
);

drop policy if exists login_events_select on public.login_events;
create policy login_events_select on public.login_events for select to authenticated using (
  user_id = auth.uid() or nano_internal.is_platform_admin()
);

drop policy if exists security_incidents_select on public.security_incidents;
create policy security_incidents_select on public.security_incidents for select to authenticated using (
  nano_internal.is_platform_admin()
);

-- ---------------------------------------------------------------------------
-- Seed fixtures (deterministic IDs)
-- ---------------------------------------------------------------------------
insert into public.device_sessions (
  id, user_id, school_id, device_label, user_agent
) values (
  'f1111111-1111-1111-1111-111111111111',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  '11111111-1111-1111-1111-111111111111',
  'Chrome / Windows',
  'sec03-fixture'
) on conflict (id) do nothing;

insert into public.device_sessions (
  id, user_id, school_id, device_label, revoked_at
) values (
  'f2222222-2222-2222-2222-222222222222',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  '11111111-1111-1111-1111-111111111111',
  'Old phone',
  timezone('utc', now())
) on conflict (id) do nothing;

insert into public.login_events (
  id, user_id, school_id, event_kind, user_agent
) values (
  'e1111111-1111-1111-1111-111111111111',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  '11111111-1111-1111-1111-111111111111',
  'success',
  'sec03-fixture'
) on conflict (id) do nothing;

insert into public.audit_events (
  id,
  actor_user_id,
  actor_role,
  school_id,
  action,
  target_type,
  target_id,
  reason,
  request_id
) values (
  'a1111111-1111-1111-1111-111111111111',
  'dddddddd-dddd-dddd-dddd-dddddddddddd',
  'superadmin',
  '11111111-1111-1111-1111-111111111111',
  'other',
  'schools',
  '11111111-1111-1111-1111-111111111111',
  'SEC-03 seed audit row',
  'sec03-seed'
) on conflict (id) do nothing;

insert into public.security_incidents (
  id, school_id, severity, title, details
) values (
  'c1111111-1111-1111-1111-111111111111',
  '11111111-1111-1111-1111-111111111111',
  'info',
  'SEC-03 seed incident',
  '{"source":"sec03"}'::jsonb
) on conflict (id) do nothing;

update public.app_health
set schema_version = 'SEC-03',
    notes = 'Audit/sessions/suspension guards',
    updated_at = timezone('utc', now())
where id = 'default';
