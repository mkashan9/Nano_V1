-- QZ-01: Superadmin question bank.
--
-- Stable question identity plus immutable published versions. Learners have no
-- read path here; QZ-02 attaches published versions to video quizzes, and
-- scoring (QZ-05) is the only place a learner ever meets a question.

create table if not exists public.questions (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  created_by uuid references public.profiles (id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.questions is
  'QZ-01 stable question identity. Content lives on question_versions so '
  'publishing never rewrites history.';

create table if not exists public.question_versions (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.questions (id) on delete cascade,
  version integer not null check (version >= 1),
  status text not null default 'draft'
    check (status in ('draft', 'published', 'retired')),
  kind text not null default 'multiple_choice'
    check (kind in ('multiple_choice', 'true_false')),
  stem text not null check (char_length(btrim(stem)) > 0),
  stem_ur text,
  options jsonb not null default '[]'::jsonb,
  explanation text not null default '',
  explanation_ur text,
  difficulty text not null default 'easy'
    check (difficulty in ('easy', 'medium', 'hard')),
  locale_policy text not null default 'both'
    check (locale_policy in ('en', 'ur', 'both')),
  media jsonb not null default '[]'::jsonb,
  provenance text not null default '',
  stem_hash text not null,
  published_at timestamptz,
  published_by uuid references public.profiles (id),
  retired_at timestamptz,
  retired_by uuid references public.profiles (id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (question_id, version),
  constraint question_versions_options_array
    check (jsonb_typeof(options) = 'array'),
  constraint question_versions_media_array
    check (jsonb_typeof(media) = 'array')
);

comment on table public.question_versions is
  'QZ-01 versioned question content. Drafts are mutable; published and retired '
  'rows are immutable. Correct answers live here for the curator only — there '
  'is no learner read policy on this table.';

create index if not exists question_versions_status_idx
  on public.question_versions (status);
create index if not exists question_versions_stem_hash_idx
  on public.question_versions (stem_hash);
create index if not exists question_versions_question_idx
  on public.question_versions (question_id, version desc);

drop trigger if exists questions_set_updated_at on public.questions;
create trigger questions_set_updated_at
  before update on public.questions
  for each row execute function public.set_updated_at();

drop trigger if exists question_versions_set_updated_at on public.question_versions;
create trigger question_versions_set_updated_at
  before update on public.question_versions
  for each row execute function public.set_updated_at();

-- Normalize a stem for duplicate detection: lower-case, collapse whitespace.
create or replace function nano_internal.normalize_question_stem(p_stem text)
returns text
language sql
immutable
set search_path = pg_catalog, public
as $$
  select lower(regexp_replace(btrim(coalesce(p_stem, '')), '\s+', ' ', 'g'));
$$;

revoke all on function nano_internal.normalize_question_stem(text)
  from public, anon;
grant execute on function nano_internal.normalize_question_stem(text)
  to authenticated, service_role;

create or replace function nano_internal.question_stem_hash(p_stem text)
returns text
language sql
immutable
set search_path = pg_catalog, public, nano_internal, extensions
as $$
  select encode(
    extensions.digest(nano_internal.normalize_question_stem(p_stem), 'sha256'),
    'hex'
  );
$$;

revoke all on function nano_internal.question_stem_hash(text) from public, anon;
grant execute on function nano_internal.question_stem_hash(text)
  to authenticated, service_role;

-- Options must be an array of objects with id, label, and exactly one correct.
create or replace function nano_internal.assert_question_options(
  p_kind text,
  p_options jsonb
)
returns void
language plpgsql
immutable
set search_path = pg_catalog, public
as $$
declare
  v_count integer;
  v_correct integer;
begin
  if jsonb_typeof(p_options) is distinct from 'array' then
    raise exception using
      errcode = 'NQ001',
      message = 'Question options must be a JSON array.';
  end if;

  v_count := jsonb_array_length(p_options);
  if p_kind = 'true_false' and v_count <> 2 then
    raise exception using
      errcode = 'NQ001',
      message = 'True/false questions need exactly two options.';
  end if;
  if p_kind = 'multiple_choice' and v_count < 2 then
    raise exception using
      errcode = 'NQ001',
      message = 'Multiple-choice questions need at least two options.';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_options) opt
    where coalesce(opt->>'id', '') = ''
       or coalesce(btrim(opt->>'label'), '') = ''
  ) then
    raise exception using
      errcode = 'NQ001',
      message = 'Every option needs an id and a label.';
  end if;

  select count(*) filter (where coalesce((opt->>'is_correct')::boolean, false))
  into v_correct
  from jsonb_array_elements(p_options) opt;

  if v_correct <> 1 then
    raise exception using
      errcode = 'NQ001',
      message = 'Exactly one option must be marked correct.';
  end if;
end;
$$;

revoke all on function nano_internal.assert_question_options(text, jsonb)
  from public, anon;
grant execute on function nano_internal.assert_question_options(text, jsonb)
  to authenticated, service_role;

create or replace function nano_internal.guard_question_version_immutability()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
begin
  if tg_op = 'DELETE' then
    if old.status <> 'draft' then
      raise exception using
        errcode = 'NQ002',
        message = 'Only draft question versions can be deleted.';
    end if;
    return old;
  end if;

  if old.status <> 'draft' then
    -- Retire is the only allowed transition out of published.
    if old.status = 'published'
       and new.status = 'retired'
       and new.stem is not distinct from old.stem
       and new.stem_ur is not distinct from old.stem_ur
       and new.options is not distinct from old.options
       and new.explanation is not distinct from old.explanation
       and new.explanation_ur is not distinct from old.explanation_ur
       and new.difficulty is not distinct from old.difficulty
       and new.locale_policy is not distinct from old.locale_policy
       and new.media is not distinct from old.media
       and new.kind is not distinct from old.kind
       and new.provenance is not distinct from old.provenance
       and new.stem_hash is not distinct from old.stem_hash
       and new.version is not distinct from old.version
       and new.question_id is not distinct from old.question_id
       and new.published_at is not distinct from old.published_at
       and new.published_by is not distinct from old.published_by
    then
      return new;
    end if;

    raise exception using
      errcode = 'NQ002',
      message = 'Published and retired question versions are immutable.';
  end if;

  if new.status = 'published' and old.status = 'draft' then
    return new;
  end if;

  if new.status <> 'draft' and old.status = 'draft' and new.status <> 'published' then
    raise exception using
      errcode = 'NQ002',
      message = 'Drafts publish; they do not jump straight to retired.';
  end if;

  return new;
end;
$$;

drop trigger if exists question_versions_immutability
  on public.question_versions;
create trigger question_versions_immutability
  before update or delete on public.question_versions
  for each row execute function nano_internal.guard_question_version_immutability();

alter table public.questions enable row level security;
alter table public.question_versions enable row level security;

drop policy if exists questions_platform_all on public.questions;
create policy questions_platform_all on public.questions
  for all to authenticated
  using (nano_internal.is_platform_admin())
  with check (nano_internal.is_platform_admin());

drop policy if exists question_versions_platform_all on public.question_versions;
create policy question_versions_platform_all on public.question_versions
  for all to authenticated
  using (nano_internal.is_platform_admin())
  with check (nano_internal.is_platform_admin());

-- Curator read model: one row per question, latest version first among equals.
create or replace view public.question_bank
with (security_invoker = true)
as
select
  q.id as question_id,
  q.slug,
  qv.id as question_version_id,
  qv.version,
  qv.status,
  qv.kind,
  qv.stem,
  qv.stem_ur,
  qv.options,
  qv.explanation,
  qv.explanation_ur,
  qv.difficulty,
  qv.locale_policy,
  qv.media,
  qv.provenance,
  qv.stem_hash,
  qv.published_at,
  qv.published_by,
  qv.retired_at,
  qv.retired_by,
  qv.created_at,
  qv.updated_at,
  q.created_at as question_created_at
from public.questions q
join lateral (
  select *
  from public.question_versions qv2
  where qv2.question_id = q.id
  order by
    case qv2.status
      when 'published' then 1
      when 'draft' then 2
      else 3
    end,
    qv2.version desc
  limit 1
) qv on true;

comment on view public.question_bank is
  'QZ-01 curator catalog: latest useful version per question. Platform-admin '
  'only through security_invoker RLS on the underlying tables.';

grant select on public.question_bank to authenticated, service_role;

-- Create a draft. Returns the new version row plus any duplicate matches.
create or replace function public.create_question_draft(
  p_slug text,
  p_stem text,
  p_options jsonb,
  p_kind text default 'multiple_choice',
  p_stem_ur text default null,
  p_explanation text default '',
  p_explanation_ur text default null,
  p_difficulty text default 'easy',
  p_locale_policy text default 'both',
  p_media jsonb default '[]'::jsonb,
  p_provenance text default '',
  p_question_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_question_id uuid;
  v_version integer;
  v_hash text;
  v_row public.question_versions%rowtype;
  v_duplicates jsonb;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NQ003',
      message = 'Only platform admins can author questions.';
  end if;

  perform nano_internal.assert_question_options(p_kind, p_options);
  v_hash := nano_internal.question_stem_hash(p_stem);

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'question_id', q.id,
        'question_version_id', qv.id,
        'slug', q.slug,
        'stem', qv.stem,
        'status', qv.status,
        'version', qv.version
      )
      order by qv.updated_at desc
    ),
    '[]'::jsonb
  )
  into v_duplicates
  from public.question_versions qv
  join public.questions q on q.id = qv.question_id
  where qv.stem_hash = v_hash
    and (p_question_id is null or qv.question_id <> p_question_id);

  if p_question_id is null then
    insert into public.questions (slug, created_by)
    values (lower(btrim(p_slug)), auth.uid())
    returning id into v_question_id;
    v_version := 1;
  else
    if not exists (
      select 1 from public.questions q where q.id = p_question_id
    ) then
      raise exception using
        errcode = 'NQ004',
        message = 'Unknown question.';
    end if;
    if exists (
      select 1 from public.question_versions qv
      where qv.question_id = p_question_id and qv.status = 'draft'
    ) then
      raise exception using
        errcode = 'NQ005',
        message = 'This question already has a draft. Edit or publish it first.';
    end if;
    v_question_id := p_question_id;
    select coalesce(max(version), 0) + 1
    into v_version
    from public.question_versions
    where question_id = v_question_id;
  end if;

  insert into public.question_versions (
    question_id, version, status, kind, stem, stem_ur, options,
    explanation, explanation_ur, difficulty, locale_policy, media,
    provenance, stem_hash
  )
  values (
    v_question_id, v_version, 'draft', p_kind, btrim(p_stem), p_stem_ur,
    p_options, coalesce(p_explanation, ''), p_explanation_ur, p_difficulty,
    p_locale_policy, coalesce(p_media, '[]'::jsonb),
    coalesce(p_provenance, ''), v_hash
  )
  returning * into v_row;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'superadmin', 'create', 'question_version', v_row.id::text,
    jsonb_build_object(
      'question_id', v_question_id,
      'version', v_version,
      'slug', lower(btrim(p_slug)),
      'stem_hash', v_hash
    )
  );

  return jsonb_build_object(
    'question_id', v_question_id,
    'question_version_id', v_row.id,
    'version', v_row.version,
    'status', v_row.status,
    'stem', v_row.stem,
    'stem_ur', v_row.stem_ur,
    'kind', v_row.kind,
    'options', v_row.options,
    'explanation', v_row.explanation,
    'explanation_ur', v_row.explanation_ur,
    'difficulty', v_row.difficulty,
    'locale_policy', v_row.locale_policy,
    'media', v_row.media,
    'provenance', v_row.provenance,
    'stem_hash', v_row.stem_hash,
    'duplicates', v_duplicates
  );
end;
$$;

comment on function public.create_question_draft is
  'QZ-01 creates a draft question version. Platform-admin only. Returns any '
  'existing versions that share the same normalized stem hash so the curator '
  'can see a duplicate warning without inventing client-side matching.';

revoke all on function public.create_question_draft(
  text, text, jsonb, text, text, text, text, text, text, jsonb, text, uuid
) from public, anon;
grant execute on function public.create_question_draft(
  text, text, jsonb, text, text, text, text, text, text, jsonb, text, uuid
) to authenticated, service_role;

create or replace function public.publish_question_version(p_version_id uuid)
returns public.question_versions
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_row public.question_versions%rowtype;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NQ003',
      message = 'Only platform admins can publish questions.';
  end if;

  select * into v_row
  from public.question_versions
  where id = p_version_id
  for update;

  if not found then
    raise exception using
      errcode = 'NQ004',
      message = 'Unknown question version.';
  end if;

  if v_row.status = 'published' then
    return v_row;
  end if;

  if v_row.status <> 'draft' then
    raise exception using
      errcode = 'NQ002',
      message = 'Only drafts can be published.';
  end if;

  perform nano_internal.assert_question_options(v_row.kind, v_row.options);

  -- A question may have at most one published version; retire the previous.
  update public.question_versions
  set status = 'retired',
      retired_at = timezone('utc', now()),
      retired_by = auth.uid()
  where question_id = v_row.question_id
    and status = 'published'
    and id <> p_version_id;

  update public.question_versions
  set status = 'published',
      published_at = timezone('utc', now()),
      published_by = auth.uid()
  where id = p_version_id
  returning * into v_row;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'superadmin', 'update', 'question_version', v_row.id::text,
    jsonb_build_object(
      'status', 'published',
      'question_id', v_row.question_id,
      'version', v_row.version,
      'published_at', v_row.published_at
    )
  );

  return v_row;
end;
$$;

comment on function public.publish_question_version(uuid) is
  'QZ-01 publishes a draft. Records the actor and timestamp. Prior published '
  'versions of the same question are retired so history stays intact.';

revoke all on function public.publish_question_version(uuid) from public, anon;
grant execute on function public.publish_question_version(uuid)
  to authenticated, service_role;

create or replace function public.retire_question_version(p_version_id uuid)
returns public.question_versions
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_row public.question_versions%rowtype;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NQ003',
      message = 'Only platform admins can retire questions.';
  end if;

  select * into v_row
  from public.question_versions
  where id = p_version_id
  for update;

  if not found then
    raise exception using
      errcode = 'NQ004',
      message = 'Unknown question version.';
  end if;

  if v_row.status = 'retired' then
    return v_row;
  end if;

  if v_row.status <> 'published' then
    raise exception using
      errcode = 'NQ002',
      message = 'Only published versions can be retired.';
  end if;

  update public.question_versions
  set status = 'retired',
      retired_at = timezone('utc', now()),
      retired_by = auth.uid()
  where id = p_version_id
  returning * into v_row;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'superadmin', 'update', 'question_version', v_row.id::text,
    jsonb_build_object(
      'status', 'retired',
      'question_id', v_row.question_id,
      'version', v_row.version,
      'retired_at', v_row.retired_at
    )
  );

  return v_row;
end;
$$;

comment on function public.retire_question_version(uuid) is
  'QZ-01 retires a published version without deleting it. Historical attempts '
  '(QZ-05) keep their reference.';

revoke all on function public.retire_question_version(uuid) from public, anon;
grant execute on function public.retire_question_version(uuid)
  to authenticated, service_role;

-- Allow trusted backend / migration seeds without an auth context.
create or replace function nano_internal.seed_question(
  p_id uuid,
  p_slug text,
  p_version_id uuid,
  p_stem text,
  p_stem_ur text,
  p_options jsonb,
  p_explanation text,
  p_explanation_ur text,
  p_difficulty text,
  p_kind text default 'multiple_choice',
  p_provenance text default 'seed'
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
begin
  insert into public.questions (id, slug, created_by)
  values (p_id, p_slug, null)
  on conflict (id) do nothing;

  insert into public.question_versions (
    id, question_id, version, status, kind, stem, stem_ur, options,
    explanation, explanation_ur, difficulty, locale_policy, media,
    provenance, stem_hash, published_at
  )
  values (
    p_version_id, p_id, 1, 'published', p_kind, p_stem, p_stem_ur, p_options,
    p_explanation, p_explanation_ur, p_difficulty, 'both', '[]'::jsonb,
    p_provenance, nano_internal.question_stem_hash(p_stem),
    timezone('utc', now())
  )
  on conflict (id) do nothing;
end;
$$;

revoke all on function nano_internal.seed_question(
  uuid, text, uuid, text, text, jsonb, text, text, text, text, text
) from public, anon;

select nano_internal.seed_question(
  '50000000-0000-0000-0000-000000000001',
  'counting-how-many',
  '51000000-0000-0000-0000-000000000001',
  'How many apples are in the basket if you count to five?',
  'اگر آپ پانچ تک گنتی کریں تو ٹوکری میں کتنے سیب ہیں؟',
  '[
    {"id":"a","label":"Three","label_ur":"تین","is_correct":false},
    {"id":"b","label":"Five","label_ur":"پانچ","is_correct":true},
    {"id":"c","label":"Ten","label_ur":"دس","is_correct":false}
  ]'::jsonb,
  'Counting to five means there are five.',
  'پانچ تک گنتی کا مطلب ہے پانچ۔',
  'easy',
  'multiple_choice',
  'seed: counting to 20'
);

select nano_internal.seed_question(
  '50000000-0000-0000-0000-000000000002',
  'addition-two-plus-three',
  '51000000-0000-0000-0000-000000000002',
  'What is 2 + 3?',
  '2 + 3 کیا ہے؟',
  '[
    {"id":"a","label":"4","label_ur":"4","is_correct":false},
    {"id":"b","label":"5","label_ur":"5","is_correct":true},
    {"id":"c","label":"6","label_ur":"6","is_correct":false}
  ]'::jsonb,
  'Two plus three is five.',
  'دو جمع تین پانچ ہوتا ہے۔',
  'easy',
  'multiple_choice',
  'seed: adding small numbers'
);

select nano_internal.seed_question(
  '50000000-0000-0000-0000-000000000003',
  'living-things-breathe',
  '51000000-0000-0000-0000-000000000003',
  'Do living things need air?',
  'کیا جانداروں کو ہوا کی ضرورت ہوتی ہے؟',
  '[
    {"id":"yes","label":"Yes","label_ur":"ہاں","is_correct":true},
    {"id":"no","label":"No","label_ur":"نہیں","is_correct":false}
  ]'::jsonb,
  'Living things need air to breathe.',
  'جانداروں کو سانس لینے کے لیے ہوا چاہیے۔',
  'easy',
  'true_false',
  'seed: living things'
);

update public.app_health
set schema_version = 'QZ-01',
    notes = 'Platform-admin question bank with immutable published versions',
    updated_at = timezone('utc', now())
where id = 'default';
