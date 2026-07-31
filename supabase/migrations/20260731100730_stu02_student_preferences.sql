-- STU-02: companion name, language, sound, and accessibility preferences.
-- Personal settings: owner-only, not readable by school staff or platform admins.

create table if not exists public.student_preferences (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  companion_name text not null default 'Nori'
    check (length(btrim(companion_name)) between 1 and 24),
  locale text not null default 'en' check (locale in ('en', 'ur')),
  sound_enabled boolean not null default true,
  haptics_enabled boolean not null default true,
  captions_enabled boolean not null default true,
  reduced_motion boolean not null default false,
  classroom_mode boolean not null default false,
  text_scale numeric(3,2) not null default 1.00
    check (text_scale between 0.85 and 1.60),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.student_preferences is
  'STU-02 personal learner settings. Owner-only; no staff or platform read path.';

alter table public.student_preferences enable row level security;

drop trigger if exists student_preferences_set_updated_at on public.student_preferences;
create trigger student_preferences_set_updated_at
  before update on public.student_preferences
  for each row execute function public.set_updated_at();

drop policy if exists student_preferences_select_self on public.student_preferences;
create policy student_preferences_select_self on public.student_preferences
  for select to authenticated
  using (user_id = auth.uid());

drop policy if exists student_preferences_insert_self on public.student_preferences;
create policy student_preferences_insert_self on public.student_preferences
  for insert to authenticated
  with check (user_id = auth.uid() and nano_internal.is_student());

drop policy if exists student_preferences_update_self on public.student_preferences;
create policy student_preferences_update_self on public.student_preferences
  for update to authenticated
  using (user_id = auth.uid() and nano_internal.is_student())
  with check (user_id = auth.uid() and nano_internal.is_student());

-- STU-02 inserts a setup step into the STU-01 flow.
alter table public.student_onboarding
  drop constraint if exists student_onboarding_current_step_check;
alter table public.student_onboarding
  add constraint student_onboarding_current_step_check
  check (current_step in ('welcome', 'experience', 'preferences', 'context', 'ready'));

update public.app_health
set schema_version = 'STU-02',
    notes = 'Student preferences + onboarding setup step',
    updated_at = timezone('utc', now())
where id = 'default';
