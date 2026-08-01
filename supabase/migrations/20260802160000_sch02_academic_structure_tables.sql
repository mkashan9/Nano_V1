-- SCH-02: grades, classes, sections, school subjects, class-subject maps.
-- Policies (attendance/grading) stay SCH-06. Terms/years stay label-only until needed.

create type public.academic_structure_status as enum ('active', 'archived');

create table public.grade_levels (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  name text not null,
  sort_order integer not null default 0,
  status public.academic_structure_status not null default 'active',
  archived_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint grade_levels_name_nonempty check (length(btrim(name)) > 0),
  constraint grade_levels_unique_name unique (school_id, name)
);

create table public.classes (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  grade_level_id uuid not null references public.grade_levels (id),
  name text not null,
  status public.academic_structure_status not null default 'active',
  archived_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint classes_name_nonempty check (length(btrim(name)) > 0),
  constraint classes_unique_name unique (school_id, grade_level_id, name)
);

create table public.sections (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  class_id uuid not null references public.classes (id),
  name text not null,
  status public.academic_structure_status not null default 'active',
  archived_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint sections_name_nonempty check (length(btrim(name)) > 0),
  constraint sections_unique_name unique (school_id, class_id, name)
);

create table public.school_subjects (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  name text not null,
  code text not null,
  learning_subject_id uuid references public.learning_subjects (id),
  status public.academic_structure_status not null default 'active',
  archived_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint school_subjects_name_nonempty check (length(btrim(name)) > 0),
  constraint school_subjects_code_nonempty check (length(btrim(code)) > 0),
  constraint school_subjects_unique_code unique (school_id, code)
);

create table public.class_subjects (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  class_id uuid not null references public.classes (id),
  section_id uuid references public.sections (id),
  school_subject_id uuid not null references public.school_subjects (id),
  status public.academic_structure_status not null default 'active',
  archived_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create unique index class_subjects_class_subject_uq
  on public.class_subjects (class_id, school_subject_id)
  where section_id is null and status = 'active';

create unique index class_subjects_section_subject_uq
  on public.class_subjects (class_id, section_id, school_subject_id)
  where section_id is not null and status = 'active';

create index grade_levels_school_idx on public.grade_levels (school_id);
create index classes_school_idx on public.classes (school_id);
create index sections_school_idx on public.sections (school_id);
create index school_subjects_school_idx on public.school_subjects (school_id);
create index class_subjects_school_idx on public.class_subjects (school_id);

alter table public.grade_levels enable row level security;
alter table public.classes enable row level security;
alter table public.sections enable row level security;
alter table public.school_subjects enable row level security;
alter table public.class_subjects enable row level security;

create policy grade_levels_select_member on public.grade_levels
  for select to authenticated
  using (nano_internal.is_school_member(school_id));

create policy classes_select_member on public.classes
  for select to authenticated
  using (nano_internal.is_school_member(school_id));

create policy sections_select_member on public.sections
  for select to authenticated
  using (nano_internal.is_school_member(school_id));

create policy school_subjects_select_member on public.school_subjects
  for select to authenticated
  using (nano_internal.is_school_member(school_id));

create policy class_subjects_select_member on public.class_subjects
  for select to authenticated
  using (nano_internal.is_school_member(school_id));

-- Writes go through SECURITY DEFINER RPCs only.

create or replace function nano_internal.require_school_admin_school_id()
returns uuid
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_school_id uuid;
begin
  if auth.uid() is null then
    raise exception using
      errcode = 'NS010',
      message = 'Sign in required for academic structure.';
  end if;
  v_school_id := nano_internal.caller_school_admin_school_id();
  if v_school_id is null then
    raise exception using
      errcode = 'NS011',
      message = 'Academic structure is limited to school administrators.';
  end if;
  return v_school_id;
end;
$fn$;

revoke all on function nano_internal.require_school_admin_school_id()
  from public, anon;
grant execute on function nano_internal.require_school_admin_school_id()
  to authenticated, service_role;
