-- STU-01: first-run onboarding progress, owned by the learner, readable by platform admins.

create or replace function nano_internal.is_student()
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
      and p.account_kind in (
        'school_student'::public.account_kind,
        'independent_student'::public.account_kind
      )
  );
$$;

revoke all on function nano_internal.is_student() from public, anon;
grant execute on function nano_internal.is_student() to authenticated, service_role;

create table if not exists public.student_onboarding (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  current_step text not null default 'welcome'
    check (current_step in ('welcome', 'experience', 'context', 'ready')),
  self_reported_grade_level smallint
    check (self_reported_grade_level between 1 and 12),
  experience_track text
    check (experience_track in ('junior', 'senior')),
  completed_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.student_onboarding is
  'STU-01 first-run progress. Grade level here is learner self-report and is never authoritative for school records.';

alter table public.student_onboarding enable row level security;

drop trigger if exists student_onboarding_set_updated_at on public.student_onboarding;
create trigger student_onboarding_set_updated_at
  before update on public.student_onboarding
  for each row execute function public.set_updated_at();

drop policy if exists student_onboarding_select on public.student_onboarding;
create policy student_onboarding_select on public.student_onboarding
  for select to authenticated
  using (user_id = auth.uid() or nano_internal.is_platform_admin());

-- Only active students may own a row, and only their own.
drop policy if exists student_onboarding_insert_self on public.student_onboarding;
create policy student_onboarding_insert_self on public.student_onboarding
  for insert to authenticated
  with check (user_id = auth.uid() and nano_internal.is_student());

drop policy if exists student_onboarding_update_self on public.student_onboarding;
create policy student_onboarding_update_self on public.student_onboarding
  for update to authenticated
  using (user_id = auth.uid() and nano_internal.is_student())
  with check (user_id = auth.uid() and nano_internal.is_student());

-- No delete policy: onboarding history disappears only with the account.

update public.app_health
set schema_version = 'STU-01',
    notes = 'Student onboarding progress table',
    updated_at = timezone('utc', now())
where id = 'default';
