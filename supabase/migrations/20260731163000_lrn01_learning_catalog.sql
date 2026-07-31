-- LRN-01: platform-curated learning catalog with a publication model.
-- Unpublished content is invisible to learners, eligibility and prerequisite
-- lock state are decided on the server, and both shells read the same
-- version IDs so junior and senior previews cannot drift.

-- Learner track and grade come from onboarding self-report (STU-01).
create or replace function nano_internal.learner_track()
returns text
language sql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
  select o.experience_track
  from public.student_onboarding o
  where o.user_id = auth.uid();
$$;

revoke all on function nano_internal.learner_track() from public, anon;
grant execute on function nano_internal.learner_track() to authenticated, service_role;

create or replace function nano_internal.learner_grade()
returns smallint
language sql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
  select o.self_reported_grade_level
  from public.student_onboarding o
  where o.user_id = auth.uid();
$$;

revoke all on function nano_internal.learner_grade() from public, anon;
grant execute on function nano_internal.learner_grade() to authenticated, service_role;

create table if not exists public.learning_subjects (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  sort_order smallint not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.learning_subjects is
  'LRN-01 platform-curated subject. School-created subjects are not part of '
  'the Learning Stack.';

create table if not exists public.subject_versions (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid not null references public.learning_subjects (id) on delete cascade,
  version smallint not null,
  title text not null,
  title_ur text,
  summary text not null default '',
  world_color_hex text not null default '#2F7BFF'
    check (world_color_hex ~ '^#[0-9A-Fa-f]{6}$'),
  status text not null default 'draft'
    check (status in ('draft', 'published', 'archived')),
  published_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (subject_id, version)
);

create table if not exists public.topics (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid not null references public.learning_subjects (id) on delete cascade,
  slug text not null,
  sort_order smallint not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  unique (subject_id, slug)
);

create table if not exists public.topic_versions (
  id uuid primary key default gen_random_uuid(),
  topic_id uuid not null references public.topics (id) on delete cascade,
  subject_version_id uuid not null references public.subject_versions (id) on delete cascade,
  version smallint not null,
  title text not null,
  title_ur text,
  objectives text[] not null default '{}',
  estimated_minutes smallint not null default 10
    check (estimated_minutes between 1 and 240),
  resources jsonb not null default '[]'::jsonb,
  status text not null default 'draft'
    check (status in ('draft', 'published', 'archived')),
  published_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (topic_id, version)
);

comment on table public.topic_versions is
  'LRN-01 immutable published unit. Completion records reference the version '
  'they were earned against, so republishing never rewrites history.';

create table if not exists public.topic_prerequisites (
  topic_id uuid not null references public.topics (id) on delete cascade,
  requires_topic_id uuid not null references public.topics (id) on delete cascade,
  primary key (topic_id, requires_topic_id),
  check (topic_id <> requires_topic_id)
);

create table if not exists public.eligibility_rules (
  subject_id uuid primary key references public.learning_subjects (id) on delete cascade,
  track text not null default 'both' check (track in ('junior', 'senior', 'both')),
  min_grade smallint check (min_grade between 1 and 12),
  max_grade smallint check (max_grade between 1 and 12),
  independent_allowed boolean not null default true
);

create table if not exists public.learning_progress (
  user_id uuid not null references public.profiles (id) on delete cascade,
  topic_version_id uuid not null references public.topic_versions (id) on delete cascade,
  status text not null default 'not_started'
    check (status in ('not_started', 'in_progress', 'completed')),
  progress numeric(4,3) not null default 0 check (progress between 0 and 1),
  resume_seconds integer not null default 0 check (resume_seconds >= 0),
  completed_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, topic_version_id)
);

comment on table public.learning_progress is
  'LRN-01 per-learner progress. Owner-only: private academic data never '
  'reaches a social projection (PRF-01).';

create index if not exists topic_versions_subject_version_idx
  on public.topic_versions (subject_version_id);
create index if not exists topics_subject_idx on public.topics (subject_id);
create index if not exists learning_progress_user_idx
  on public.learning_progress (user_id);

drop trigger if exists subject_versions_set_updated_at on public.subject_versions;
create trigger subject_versions_set_updated_at
  before update on public.subject_versions
  for each row execute function public.set_updated_at();

drop trigger if exists topic_versions_set_updated_at on public.topic_versions;
create trigger topic_versions_set_updated_at
  before update on public.topic_versions
  for each row execute function public.set_updated_at();

drop trigger if exists learning_progress_set_updated_at on public.learning_progress;
create trigger learning_progress_set_updated_at
  before update on public.learning_progress
  for each row execute function public.set_updated_at();

-- Eligibility is a server decision, not a client filter.
create or replace function nano_internal.subject_is_eligible(p_subject_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
  select
    nano_internal.is_platform_admin()
    or exists (
      select 1
      from public.eligibility_rules er
      join public.profiles p on p.id = auth.uid()
      where er.subject_id = p_subject_id
        and (
          er.track = 'both'
          or er.track = coalesce(nano_internal.learner_track(), 'junior')
        )
        and (er.min_grade is null
             or coalesce(nano_internal.learner_grade(), er.min_grade) >= er.min_grade)
        and (er.max_grade is null
             or coalesce(nano_internal.learner_grade(), er.max_grade) <= er.max_grade)
        and (
          er.independent_allowed
          or p.account_kind <> 'independent_student'::public.account_kind
        )
    )
    -- A subject with no rule row is open to every learner.
    or not exists (
      select 1 from public.eligibility_rules er2 where er2.subject_id = p_subject_id
    );
$$;

revoke all on function nano_internal.subject_is_eligible(uuid) from public, anon;
grant execute on function nano_internal.subject_is_eligible(uuid) to authenticated, service_role;

create or replace function nano_internal.subject_is_visible(p_subject_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
  select
    nano_internal.is_platform_admin()
    or (
      exists (
        select 1
        from public.subject_versions sv
        where sv.subject_id = p_subject_id and sv.status = 'published'
      )
      and nano_internal.subject_is_eligible(p_subject_id)
    );
$$;

revoke all on function nano_internal.subject_is_visible(uuid) from public, anon;
grant execute on function nano_internal.subject_is_visible(uuid) to authenticated, service_role;

alter table public.learning_subjects enable row level security;
alter table public.subject_versions enable row level security;
alter table public.topics enable row level security;
alter table public.topic_versions enable row level security;
alter table public.topic_prerequisites enable row level security;
alter table public.eligibility_rules enable row level security;
alter table public.learning_progress enable row level security;

-- Reads only. Curation happens through service-role tooling (SEC-01),
-- so there are no client insert/update/delete policies on catalog tables.
drop policy if exists learning_subjects_select on public.learning_subjects;
create policy learning_subjects_select on public.learning_subjects
  for select to authenticated
  using (nano_internal.subject_is_visible(id));

drop policy if exists subject_versions_select on public.subject_versions;
create policy subject_versions_select on public.subject_versions
  for select to authenticated
  using (
    nano_internal.is_platform_admin()
    or (status = 'published' and nano_internal.subject_is_eligible(subject_id))
  );

drop policy if exists topics_select on public.topics;
create policy topics_select on public.topics
  for select to authenticated
  using (nano_internal.subject_is_visible(subject_id));

drop policy if exists topic_versions_select on public.topic_versions;
create policy topic_versions_select on public.topic_versions
  for select to authenticated
  using (
    nano_internal.is_platform_admin()
    or (
      status = 'published'
      and exists (
        select 1
        from public.subject_versions sv
        where sv.id = subject_version_id
          and sv.status = 'published'
          and nano_internal.subject_is_eligible(sv.subject_id)
      )
    )
  );

drop policy if exists topic_prerequisites_select on public.topic_prerequisites;
create policy topic_prerequisites_select on public.topic_prerequisites
  for select to authenticated
  using (
    exists (
      select 1 from public.topics t
      where t.id = topic_id and nano_internal.subject_is_visible(t.subject_id)
    )
  );

drop policy if exists eligibility_rules_select on public.eligibility_rules;
create policy eligibility_rules_select on public.eligibility_rules
  for select to authenticated
  using (nano_internal.subject_is_visible(subject_id));

drop policy if exists learning_progress_select_self on public.learning_progress;
create policy learning_progress_select_self on public.learning_progress
  for select to authenticated
  using (user_id = auth.uid());

drop policy if exists learning_progress_insert_self on public.learning_progress;
create policy learning_progress_insert_self on public.learning_progress
  for insert to authenticated
  with check (user_id = auth.uid() and nano_internal.is_student());

drop policy if exists learning_progress_update_self on public.learning_progress;
create policy learning_progress_update_self on public.learning_progress
  for update to authenticated
  using (user_id = auth.uid() and nano_internal.is_student())
  with check (user_id = auth.uid() and nano_internal.is_student());

-- One read model for both shells: junior and senior render the same rows,
-- so a preview cannot show different version IDs than the live catalog.
-- security_invoker keeps the caller's RLS in force.
drop view if exists public.learning_catalog;
create view public.learning_catalog with (security_invoker = true) as
select
  s.id                as subject_id,
  s.slug              as subject_slug,
  s.sort_order        as subject_order,
  sv.id               as subject_version_id,
  sv.version          as subject_version,
  sv.title            as subject_title,
  sv.title_ur         as subject_title_ur,
  sv.summary          as subject_summary,
  sv.world_color_hex,
  t.id                as topic_id,
  t.slug              as topic_slug,
  t.sort_order        as topic_order,
  tv.id               as topic_version_id,
  tv.version          as topic_version,
  tv.title            as topic_title,
  tv.title_ur         as topic_title_ur,
  tv.objectives,
  tv.estimated_minutes,
  tv.resources,
  coalesce(lp.status, 'not_started') as progress_status,
  coalesce(lp.progress, 0)           as progress,
  coalesce(lp.resume_seconds, 0)     as resume_seconds,
  blocking.titles                    as blocking_titles,
  coalesce(array_length(blocking.titles, 1), 0) > 0 as is_locked
from public.topic_versions tv
join public.topics t on t.id = tv.topic_id
join public.subject_versions sv on sv.id = tv.subject_version_id
join public.learning_subjects s on s.id = t.subject_id
left join public.learning_progress lp
  on lp.topic_version_id = tv.id and lp.user_id = auth.uid()
left join lateral (
  -- Prerequisite topics the learner has not completed yet.
  select array_agg(distinct rtv.title order by rtv.title) as titles
  from public.topic_prerequisites tp
  join public.topic_versions rtv
    on rtv.topic_id = tp.requires_topic_id and rtv.status = 'published'
  where tp.topic_id = t.id
    and not exists (
      select 1
      from public.learning_progress lp2
      join public.topic_versions done on done.id = lp2.topic_version_id
      where done.topic_id = tp.requires_topic_id
        and lp2.user_id = auth.uid()
        and lp2.status = 'completed'
    )
) blocking on true;

comment on view public.learning_catalog is
  'LRN-01 catalog read model. Hides unpublished and ineligible content via '
  'the caller''s RLS and reports server-computed prerequisite lock state.';

grant select on public.learning_catalog to authenticated, service_role;

-- Seed fixtures: one open subject with a prerequisite chain, one senior-only
-- subject, and one draft-only subject that must stay invisible to learners.
insert into public.learning_subjects (id, slug, sort_order) values
  ('10000000-0000-0000-0000-000000000001', 'math', 1),
  ('10000000-0000-0000-0000-000000000002', 'science', 2),
  ('10000000-0000-0000-0000-000000000003', 'coding', 3)
on conflict (id) do nothing;

insert into public.eligibility_rules (subject_id, track, min_grade, max_grade, independent_allowed) values
  ('10000000-0000-0000-0000-000000000001', 'both', null, null, true),
  ('10000000-0000-0000-0000-000000000002', 'senior', 6, 12, true),
  ('10000000-0000-0000-0000-000000000003', 'both', null, null, true)
on conflict (subject_id) do nothing;

insert into public.subject_versions
  (id, subject_id, version, title, title_ur, summary, world_color_hex, status, published_at) values
  ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 1,
   'Math', 'حساب', 'Numbers, counting and addition.', '#2F7BFF', 'published', timezone('utc', now())),
  ('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', 1,
   'Science', 'سائنس', 'Living things and matter.', '#FF8A3D', 'published', timezone('utc', now())),
  ('20000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000003', 1,
   'Coding', 'کوڈنگ', 'Not published yet.', '#2FBF71', 'draft', null)
on conflict (id) do nothing;

insert into public.topics (id, subject_id, slug, sort_order) values
  ('30000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'counting', 1),
  ('30000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', 'addition', 2),
  ('30000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000002', 'living-things', 1),
  ('30000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000003', 'first-loop', 1)
on conflict (id) do nothing;

insert into public.topic_versions
  (id, topic_id, subject_version_id, version, title, title_ur, objectives, estimated_minutes, status, published_at) values
  ('40000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001',
   '20000000-0000-0000-0000-000000000001', 1, 'Counting to 20', '20 تک گنتی',
   array['Count objects to 20', 'Recognise number order'], 12, 'published', timezone('utc', now())),
  ('40000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000002',
   '20000000-0000-0000-0000-000000000001', 1, 'Adding small numbers', 'چھوٹے اعداد جمع',
   array['Add within 20', 'Use a number line'], 15, 'published', timezone('utc', now())),
  ('40000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000003',
   '20000000-0000-0000-0000-000000000002', 1, 'Living things', 'جاندار',
   array['Sort living and non-living'], 18, 'published', timezone('utc', now())),
  ('40000000-0000-0000-0000-000000000004', '30000000-0000-0000-0000-000000000004',
   '20000000-0000-0000-0000-000000000003', 1, 'Your first loop', 'پہلا لوپ',
   array['Repeat a block'], 20, 'draft', null)
on conflict (id) do nothing;

-- Addition needs counting first.
insert into public.topic_prerequisites (topic_id, requires_topic_id) values
  ('30000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000001')
on conflict do nothing;

update public.app_health
set schema_version = 'LRN-01',
    notes = 'Learning catalog: versions, eligibility, prerequisites, progress',
    updated_at = timezone('utc', now())
where id = 'default';
