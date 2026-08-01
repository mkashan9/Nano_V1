-- QZ-02: ordered quizzes attached to a specific topic (video) version.
--
-- A quiz version points at one topic_version. Items reference published
-- question_versions in a fixed order. Policies travel with the version so a
-- republish never rewrites what historical attempts will later resolve against.
-- Learners may read a published quiz through public.learner_quiz, which strips
-- correctness; authoring stays platform-admin only.

create table if not exists public.quiz_versions (
  id uuid primary key default gen_random_uuid(),
  topic_version_id uuid not null references public.topic_versions (id) on delete cascade,
  version integer not null check (version >= 1),
  status text not null default 'draft'
    check (status in ('draft', 'published', 'retired')),
  title text not null check (char_length(btrim(title)) > 0),
  title_ur text,
  published_at timestamptz,
  published_by uuid references public.profiles (id),
  retired_at timestamptz,
  retired_by uuid references public.profiles (id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (topic_version_id, version)
);

comment on table public.quiz_versions is
  'QZ-02 quiz identity per topic version. Drafts are mutable; published and '
  'retired rows are immutable. A topic version has at most one published quiz.';

create table if not exists public.quiz_policies (
  quiz_version_id uuid primary key references public.quiz_versions (id) on delete cascade,
  pass_percent numeric(5,2) not null default 70
    check (pass_percent > 0 and pass_percent <= 100),
  timer_seconds integer check (timer_seconds is null or timer_seconds > 0),
  max_retakes integer check (max_retakes is null or max_retakes >= 0),
  expires_at timestamptz,
  option_order_policy text not null default 'fixed'
    check (option_order_policy in ('fixed', 'shuffle')),
  question_order_policy text not null default 'fixed'
    check (question_order_policy in ('fixed', 'shuffle')),
  locale_policy text not null default 'both'
    check (locale_policy in ('en', 'ur', 'both')),
  experience_policy text not null default 'both'
    check (experience_policy in ('junior', 'senior', 'both')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.quiz_policies is
  'QZ-02 policy snapshot for a quiz version. Shuffle flags are explicit; the '
  'default preserves the authored order.';

create table if not exists public.quiz_items (
  id uuid primary key default gen_random_uuid(),
  quiz_version_id uuid not null references public.quiz_versions (id) on delete cascade,
  question_version_id uuid not null references public.question_versions (id),
  sort_order integer not null check (sort_order >= 1),
  created_at timestamptz not null default timezone('utc', now()),
  unique (quiz_version_id, sort_order),
  unique (quiz_version_id, question_version_id)
);

comment on table public.quiz_items is
  'QZ-02 ordered attachment of a published question version to a quiz version.';

create index if not exists quiz_versions_topic_idx
  on public.quiz_versions (topic_version_id, status);
create index if not exists quiz_items_quiz_idx
  on public.quiz_items (quiz_version_id, sort_order);

drop trigger if exists quiz_versions_set_updated_at on public.quiz_versions;
create trigger quiz_versions_set_updated_at
  before update on public.quiz_versions
  for each row execute function public.set_updated_at();

drop trigger if exists quiz_policies_set_updated_at on public.quiz_policies;
create trigger quiz_policies_set_updated_at
  before update on public.quiz_policies
  for each row execute function public.set_updated_at();

-- Immutability: published/retired quiz versions, their policies, and items.
create or replace function nano_internal.guard_quiz_version_immutability()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
begin
  if tg_op = 'DELETE' then
    if old.status <> 'draft' then
      raise exception using
        errcode = 'NQ010',
        message = 'Only draft quiz versions can be deleted.';
    end if;
    return old;
  end if;

  if old.status <> 'draft' then
    if old.status = 'published'
       and new.status = 'retired'
       and new.title is not distinct from old.title
       and new.title_ur is not distinct from old.title_ur
       and new.topic_version_id is not distinct from old.topic_version_id
       and new.version is not distinct from old.version
       and new.published_at is not distinct from old.published_at
       and new.published_by is not distinct from old.published_by
    then
      return new;
    end if;
    raise exception using
      errcode = 'NQ010',
      message = 'Published and retired quiz versions are immutable.';
  end if;

  if new.status = 'published' and old.status = 'draft' then
    return new;
  end if;

  if new.status <> 'draft' and old.status = 'draft' and new.status <> 'published' then
    raise exception using
      errcode = 'NQ010',
      message = 'Drafts publish; they do not jump straight to retired.';
  end if;

  return new;
end;
$$;

drop trigger if exists quiz_versions_immutability on public.quiz_versions;
create trigger quiz_versions_immutability
  before update or delete on public.quiz_versions
  for each row execute function nano_internal.guard_quiz_version_immutability();

create or replace function nano_internal.guard_quiz_policy_immutability()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_status text;
begin
  select status into v_status
  from public.quiz_versions
  where id = coalesce(new.quiz_version_id, old.quiz_version_id);

  if v_status is distinct from 'draft' then
    raise exception using
      errcode = 'NQ010',
      message = 'Policies on published or retired quizzes are immutable.';
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

drop trigger if exists quiz_policies_immutability on public.quiz_policies;
create trigger quiz_policies_immutability
  before update or delete on public.quiz_policies
  for each row execute function nano_internal.guard_quiz_policy_immutability();

create or replace function nano_internal.guard_quiz_item_immutability()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_status text;
  v_qstatus text;
begin
  select status into v_status
  from public.quiz_versions
  where id = coalesce(new.quiz_version_id, old.quiz_version_id);

  if v_status is distinct from 'draft' then
    raise exception using
      errcode = 'NQ010',
      message = 'Items on published or retired quizzes are immutable.';
  end if;

  if tg_op in ('INSERT', 'UPDATE') then
    select status into v_qstatus
    from public.question_versions
    where id = new.question_version_id;
    if v_qstatus is distinct from 'published' then
      raise exception using
        errcode = 'NQ011',
        message = 'Only published question versions can be attached to a quiz.';
    end if;
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

drop trigger if exists quiz_items_immutability on public.quiz_items;
create trigger quiz_items_immutability
  before insert or update or delete on public.quiz_items
  for each row execute function nano_internal.guard_quiz_item_immutability();

alter table public.quiz_versions enable row level security;
alter table public.quiz_policies enable row level security;
alter table public.quiz_items enable row level security;

drop policy if exists quiz_versions_platform_all on public.quiz_versions;
create policy quiz_versions_platform_all on public.quiz_versions
  for all to authenticated
  using (nano_internal.is_platform_admin())
  with check (nano_internal.is_platform_admin());

drop policy if exists quiz_policies_platform_all on public.quiz_policies;
create policy quiz_policies_platform_all on public.quiz_policies
  for all to authenticated
  using (nano_internal.is_platform_admin())
  with check (nano_internal.is_platform_admin());

drop policy if exists quiz_items_platform_all on public.quiz_items;
create policy quiz_items_platform_all on public.quiz_items
  for all to authenticated
  using (nano_internal.is_platform_admin())
  with check (nano_internal.is_platform_admin());

-- Learners may read published quizzes only (no correctness).
drop policy if exists quiz_versions_learner_read on public.quiz_versions;
create policy quiz_versions_learner_read on public.quiz_versions
  for select to authenticated
  using (
    status = 'published'
    and not nano_internal.is_platform_admin()
    and exists (
      select 1 from public.learning_catalog lc
      where lc.topic_version_id = quiz_versions.topic_version_id
    )
  );

drop policy if exists quiz_policies_learner_read on public.quiz_policies;
create policy quiz_policies_learner_read on public.quiz_policies
  for select to authenticated
  using (
    not nano_internal.is_platform_admin()
    and exists (
      select 1 from public.quiz_versions qv
      where qv.id = quiz_policies.quiz_version_id
        and qv.status = 'published'
        and exists (
          select 1 from public.learning_catalog lc
          where lc.topic_version_id = qv.topic_version_id
        )
    )
  );

drop policy if exists quiz_items_learner_read on public.quiz_items;
create policy quiz_items_learner_read on public.quiz_items
  for select to authenticated
  using (
    not nano_internal.is_platform_admin()
    and exists (
      select 1 from public.quiz_versions qv
      where qv.id = quiz_items.quiz_version_id
        and qv.status = 'published'
        and exists (
          select 1 from public.learning_catalog lc
          where lc.topic_version_id = qv.topic_version_id
        )
    )
  );

-- Curator read model (includes correctness via question options).
create or replace view public.quiz_authoring
with (security_invoker = true)
as
select
  qv.id as quiz_version_id,
  qv.topic_version_id,
  t.slug as topic_slug,
  tv.title as topic_title,
  qv.version,
  qv.status,
  qv.title,
  qv.title_ur,
  qv.published_at,
  qv.published_by,
  qv.retired_at,
  qp.pass_percent,
  qp.timer_seconds,
  qp.max_retakes,
  qp.expires_at,
  qp.option_order_policy,
  qp.question_order_policy,
  qp.locale_policy,
  qp.experience_policy,
  coalesce((
    select jsonb_agg(
      jsonb_build_object(
        'quiz_item_id', qi.id,
        'sort_order', qi.sort_order,
        'question_version_id', qn.id,
        'question_id', qn.question_id,
        'stem', qn.stem,
        'stem_ur', qn.stem_ur,
        'kind', qn.kind,
        'difficulty', qn.difficulty,
        'options', qn.options,
        'explanation', qn.explanation,
        'explanation_ur', qn.explanation_ur
      )
      order by qi.sort_order
    )
    from public.quiz_items qi
    join public.question_versions qn on qn.id = qi.question_version_id
    where qi.quiz_version_id = qv.id
  ), '[]'::jsonb) as items,
  qv.created_at,
  qv.updated_at
from public.quiz_versions qv
join public.topic_versions tv on tv.id = qv.topic_version_id
join public.topics t on t.id = tv.topic_id
join public.quiz_policies qp on qp.quiz_version_id = qv.id;

comment on view public.quiz_authoring is
  'QZ-02 curator quiz catalog with ordered items and full options. '
  'Platform-admin only through security_invoker RLS.';

grant select on public.quiz_authoring to authenticated, service_role;

-- Learner projection: options without is_correct.
-- Runs as the view owner so it can read question stems without opening a
-- learner path to question_versions (which still carry is_correct).
create or replace view public.learner_quiz
with (security_invoker = false)
as
select
  qv.id as quiz_version_id,
  qv.topic_version_id,
  qv.version,
  qv.title,
  qv.title_ur,
  qp.pass_percent,
  qp.timer_seconds,
  qp.max_retakes,
  qp.expires_at,
  qp.option_order_policy,
  qp.question_order_policy,
  qp.locale_policy,
  qp.experience_policy,
  coalesce((
    select jsonb_agg(
      jsonb_build_object(
        'sort_order', qi.sort_order,
        'question_version_id', qn.id,
        'stem', qn.stem,
        'stem_ur', qn.stem_ur,
        'kind', qn.kind,
        'options', (
          select coalesce(jsonb_agg(
            jsonb_build_object(
              'id', opt->>'id',
              'label', opt->>'label',
              'label_ur', opt->>'label_ur'
            )
            order by ord
          ), '[]'::jsonb)
          from jsonb_array_elements(qn.options) with ordinality as t(opt, ord)
        )
      )
      order by qi.sort_order
    )
    from public.quiz_items qi
    join public.question_versions qn on qn.id = qi.question_version_id
    where qi.quiz_version_id = qv.id
  ), '[]'::jsonb) as items
from public.quiz_versions qv
join public.quiz_policies qp on qp.quiz_version_id = qv.id
where qv.status = 'published'
  and (
    nano_internal.is_platform_admin()
    or exists (
      select 1 from public.learning_catalog lc
      where lc.topic_version_id = qv.topic_version_id
    )
  );

comment on view public.learner_quiz is
  'QZ-02 learner-safe published quiz. Options never include is_correct. '
  'Definer view; filters to catalog-visible topics for non-admins.';

grant select on public.learner_quiz to authenticated, service_role;

create or replace function public.create_quiz_draft(
  p_topic_version_id uuid,
  p_title text,
  p_items jsonb,
  p_title_ur text default null,
  p_pass_percent numeric default 70,
  p_timer_seconds integer default null,
  p_max_retakes integer default null,
  p_option_order_policy text default 'fixed',
  p_question_order_policy text default 'fixed',
  p_locale_policy text default 'both',
  p_experience_policy text default 'both'
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_quiz_id uuid;
  v_version integer;
  v_item jsonb;
  v_ord integer := 0;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NQ003',
      message = 'Only platform admins can author quizzes.';
  end if;

  if not exists (
    select 1 from public.topic_versions where id = p_topic_version_id
  ) then
    raise exception using
      errcode = 'NQ012',
      message = 'Unknown topic version.';
  end if;

  if jsonb_typeof(p_items) is distinct from 'array'
     or jsonb_array_length(p_items) < 1 then
    raise exception using
      errcode = 'NQ013',
      message = 'A quiz needs at least one question.';
  end if;

  if exists (
    select 1 from public.quiz_versions
    where topic_version_id = p_topic_version_id and status = 'draft'
  ) then
    raise exception using
      errcode = 'NQ014',
      message = 'This topic already has a draft quiz.';
  end if;

  select coalesce(max(version), 0) + 1 into v_version
  from public.quiz_versions
  where topic_version_id = p_topic_version_id;

  insert into public.quiz_versions
    (topic_version_id, version, status, title, title_ur)
  values
    (p_topic_version_id, v_version, 'draft', btrim(p_title), p_title_ur)
  returning id into v_quiz_id;

  insert into public.quiz_policies (
    quiz_version_id, pass_percent, timer_seconds, max_retakes,
    option_order_policy, question_order_policy, locale_policy, experience_policy
  ) values (
    v_quiz_id, p_pass_percent, p_timer_seconds, p_max_retakes,
    p_option_order_policy, p_question_order_policy,
    p_locale_policy, p_experience_policy
  );

  for v_item in select * from jsonb_array_elements(p_items)
  loop
    v_ord := v_ord + 1;
    insert into public.quiz_items
      (quiz_version_id, question_version_id, sort_order)
    values (
      v_quiz_id,
      (v_item->>'question_version_id')::uuid,
      coalesce((v_item->>'sort_order')::integer, v_ord)
    );
  end loop;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'superadmin', 'create', 'quiz_version', v_quiz_id::text,
    jsonb_build_object(
      'topic_version_id', p_topic_version_id,
      'version', v_version,
      'item_count', v_ord
    )
  );

  return jsonb_build_object(
    'quiz_version_id', v_quiz_id,
    'topic_version_id', p_topic_version_id,
    'version', v_version,
    'status', 'draft',
    'title', btrim(p_title),
    'item_count', v_ord
  );
end;
$$;

comment on function public.create_quiz_draft is
  'QZ-02 creates a draft quiz for a topic version with ordered items and policies.';

revoke all on function public.create_quiz_draft(
  uuid, text, jsonb, text, numeric, integer, integer, text, text, text, text
) from public, anon;
grant execute on function public.create_quiz_draft(
  uuid, text, jsonb, text, numeric, integer, integer, text, text, text, text
) to authenticated, service_role;

create or replace function public.replace_quiz_items(
  p_quiz_version_id uuid,
  p_items jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_status text;
  v_item jsonb;
  v_ord integer := 0;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NQ003',
      message = 'Only platform admins can author quizzes.';
  end if;

  select status into v_status
  from public.quiz_versions
  where id = p_quiz_version_id;

  if v_status is null then
    raise exception using
      errcode = 'NQ012',
      message = 'Unknown quiz version.';
  end if;
  if v_status <> 'draft' then
    raise exception using
      errcode = 'NQ010',
      message = 'Only draft quizzes can change items.';
  end if;
  if jsonb_typeof(p_items) is distinct from 'array'
     or jsonb_array_length(p_items) < 1 then
    raise exception using
      errcode = 'NQ013',
      message = 'A quiz needs at least one question.';
  end if;

  delete from public.quiz_items where quiz_version_id = p_quiz_version_id;

  for v_item in select * from jsonb_array_elements(p_items)
  loop
    v_ord := v_ord + 1;
    insert into public.quiz_items
      (quiz_version_id, question_version_id, sort_order)
    values (
      p_quiz_version_id,
      (v_item->>'question_version_id')::uuid,
      coalesce((v_item->>'sort_order')::integer, v_ord)
    );
  end loop;

  return jsonb_build_object(
    'quiz_version_id', p_quiz_version_id,
    'item_count', v_ord
  );
end;
$$;

revoke all on function public.replace_quiz_items(uuid, jsonb) from public, anon;
grant execute on function public.replace_quiz_items(uuid, jsonb)
  to authenticated, service_role;

create or replace function public.publish_quiz_version(p_quiz_version_id uuid)
returns public.quiz_versions
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_row public.quiz_versions%rowtype;
  v_count integer;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NQ003',
      message = 'Only platform admins can publish quizzes.';
  end if;

  select * into v_row
  from public.quiz_versions
  where id = p_quiz_version_id
  for update;

  if not found then
    raise exception using
      errcode = 'NQ012',
      message = 'Unknown quiz version.';
  end if;
  if v_row.status = 'published' then
    return v_row;
  end if;
  if v_row.status <> 'draft' then
    raise exception using
      errcode = 'NQ010',
      message = 'Only drafts can be published.';
  end if;

  select count(*) into v_count
  from public.quiz_items
  where quiz_version_id = p_quiz_version_id;
  if v_count < 1 then
    raise exception using
      errcode = 'NQ013',
      message = 'A quiz needs at least one question.';
  end if;

  update public.quiz_versions
  set status = 'retired',
      retired_at = timezone('utc', now()),
      retired_by = auth.uid()
  where topic_version_id = v_row.topic_version_id
    and status = 'published'
    and id <> p_quiz_version_id;

  update public.quiz_versions
  set status = 'published',
      published_at = timezone('utc', now()),
      published_by = auth.uid()
  where id = p_quiz_version_id
  returning * into v_row;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'superadmin', 'update', 'quiz_version', v_row.id::text,
    jsonb_build_object(
      'status', 'published',
      'topic_version_id', v_row.topic_version_id,
      'version', v_row.version,
      'published_at', v_row.published_at
    )
  );

  return v_row;
end;
$$;

comment on function public.publish_quiz_version(uuid) is
  'QZ-02 publishes a draft quiz and retires any prior published quiz for the same topic.';

revoke all on function public.publish_quiz_version(uuid) from public, anon;
grant execute on function public.publish_quiz_version(uuid)
  to authenticated, service_role;

create or replace function public.retire_quiz_version(p_quiz_version_id uuid)
returns public.quiz_versions
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_row public.quiz_versions%rowtype;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NQ003',
      message = 'Only platform admins can retire quizzes.';
  end if;

  select * into v_row
  from public.quiz_versions
  where id = p_quiz_version_id
  for update;

  if not found then
    raise exception using
      errcode = 'NQ012',
      message = 'Unknown quiz version.';
  end if;
  if v_row.status = 'retired' then
    return v_row;
  end if;
  if v_row.status <> 'published' then
    raise exception using
      errcode = 'NQ010',
      message = 'Only published quizzes can be retired.';
  end if;

  update public.quiz_versions
  set status = 'retired',
      retired_at = timezone('utc', now()),
      retired_by = auth.uid()
  where id = p_quiz_version_id
  returning * into v_row;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'superadmin', 'update', 'quiz_version', v_row.id::text,
    jsonb_build_object('status', 'retired', 'version', v_row.version)
  );

  return v_row;
end;
$$;

revoke all on function public.retire_quiz_version(uuid) from public, anon;
grant execute on function public.retire_quiz_version(uuid)
  to authenticated, service_role;

create or replace function nano_internal.seed_topic_quiz(
  p_quiz_id uuid,
  p_topic_version_id uuid,
  p_title text,
  p_title_ur text,
  p_question_version_id uuid,
  p_pass_percent numeric default 70
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
begin
  insert into public.quiz_versions
    (id, topic_version_id, version, status, title, title_ur)
  values
    (p_quiz_id, p_topic_version_id, 1, 'draft', p_title, p_title_ur)
  on conflict (id) do nothing;

  insert into public.quiz_policies (quiz_version_id, pass_percent)
  values (p_quiz_id, p_pass_percent)
  on conflict (quiz_version_id) do nothing;

  insert into public.quiz_items
    (quiz_version_id, question_version_id, sort_order)
  values (p_quiz_id, p_question_version_id, 1)
  on conflict (quiz_version_id, question_version_id) do nothing;

  update public.quiz_versions
  set status = 'published',
      published_at = timezone('utc', now())
  where id = p_quiz_id
    and status = 'draft';
end;
$$;

revoke all on function nano_internal.seed_topic_quiz(
  uuid, uuid, text, text, uuid, numeric
) from public, anon;

select nano_internal.seed_topic_quiz(
  '60000000-0000-0000-0000-000000000001',
  '40000000-0000-0000-0000-000000000001',
  'Counting check',
  'گنتی کی جانچ',
  '51000000-0000-0000-0000-000000000001'
);

select nano_internal.seed_topic_quiz(
  '60000000-0000-0000-0000-000000000002',
  '40000000-0000-0000-0000-000000000002',
  'Addition check',
  'جمع کی جانچ',
  '51000000-0000-0000-0000-000000000002'
);

select nano_internal.seed_topic_quiz(
  '60000000-0000-0000-0000-000000000003',
  '40000000-0000-0000-0000-000000000003',
  'Living things check',
  'جانداروں کی جانچ',
  '51000000-0000-0000-0000-000000000003'
);

update public.app_health
set schema_version = 'QZ-02',
    notes = 'Ordered quizzes attached to topic versions with learner-safe projection',
    updated_at = timezone('utc', now())
where id = 'default';
