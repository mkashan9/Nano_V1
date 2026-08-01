-- ADM-06: platform game catalog bootstrap (draft / publish / disable).
-- Student play, sessions, score verify, and assets stay with GME-*.

create table if not exists public.games (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique
    check (slug ~ '^[a-z][a-z0-9_]{1,62}$'),
  category text not null default 'practice'
    check (category in ('practice', 'challenge', 'world')),
  sort_order integer not null default 100,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.games is
  'ADM-06 stable game identity. Learner catalog and host arrive in GME-01.';

create table if not exists public.game_versions (
  id uuid primary key default gen_random_uuid(),
  game_id uuid not null references public.games (id) on delete cascade,
  version integer not null,
  title_en text not null,
  title_ur text not null default '',
  summary_en text not null default '',
  summary_ur text not null default '',
  min_grade smallint check (min_grade between 1 and 12),
  max_grade smallint check (max_grade between 1 and 12),
  status text not null default 'draft'
    check (status in ('draft', 'published', 'archived')),
  enabled boolean not null default true,
  entry_kind text not null default 'web'
    check (entry_kind in ('web', 'flutter')),
  entry_ref text not null default '',
  published_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (game_id, version)
);

comment on table public.game_versions is
  'ADM-06 versioned catalog row. Disable (enabled=false) is the kill switch '
  'seed for GME-07; archived preserves history.';

create index if not exists game_versions_game_idx on public.game_versions (game_id);
create index if not exists game_versions_status_idx
  on public.game_versions (status, enabled);

drop trigger if exists games_set_updated_at on public.games;
create trigger games_set_updated_at
  before update on public.games
  for each row execute function public.set_updated_at();

drop trigger if exists game_versions_set_updated_at on public.game_versions;
create trigger game_versions_set_updated_at
  before update on public.game_versions
  for each row execute function public.set_updated_at();

alter table public.games enable row level security;
alter table public.game_versions enable row level security;

-- Learners may read published+enabled rows later via GME-01. For now only
-- platform staff select through these policies; admin RPCs are security definer.
drop policy if exists games_select_admin on public.games;
create policy games_select_admin on public.games
  for select to authenticated
  using (nano_internal.is_platform_admin());

drop policy if exists game_versions_select_admin on public.game_versions;
create policy game_versions_select_admin on public.game_versions
  for select to authenticated
  using (nano_internal.is_platform_admin());

revoke all on table public.games from public, anon;
revoke all on table public.game_versions from public, anon;
grant select on table public.games to authenticated, service_role;
grant select on table public.game_versions to authenticated, service_role;

insert into public.games (id, slug, category, sort_order) values
  ('60000000-0000-0000-0000-000000000001', 'number_rush', 'practice', 10),
  ('60000000-0000-0000-0000-000000000002', 'shape_sort', 'world', 20)
on conflict (id) do nothing;

insert into public.game_versions
  (id, game_id, version, title_en, title_ur, summary_en, summary_ur,
   min_grade, max_grade, status, enabled, entry_kind, entry_ref, published_at)
values
  (
    '61000000-0000-0000-0000-000000000001',
    '60000000-0000-0000-0000-000000000001',
    1,
    'Number Rush', 'نمبر رش',
    'Practice counting under a gentle timer.',
    'ہلکے ٹائمر کے ساتھ گنتی کی مشق۔',
    1, 5, 'published', true, 'web', 'fixture://number_rush',
    timezone('utc', now())
  ),
  (
    '61000000-0000-0000-0000-000000000002',
    '60000000-0000-0000-0000-000000000002',
    1,
    'Shape Sort', 'شکلیں چھانٹو',
    'Sort shapes in a junior world.',
    'جونیئر دنیا میں شکلیں چھانٹیں۔',
    1, 3, 'draft', true, 'flutter', 'fixture://shape_sort',
    null
  )
on conflict (id) do nothing;

create or replace function public.list_games_admin()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NG010',
      message = 'Game admin is limited to platform staff.';
  end if;

  return coalesce((
    select jsonb_agg(row_to_json(x)::jsonb order by x.sort_order, x.slug)
    from (
      select
        g.id as game_id,
        g.slug,
        g.category,
        g.sort_order,
        gv.id as game_version_id,
        gv.version,
        gv.title_en,
        gv.title_ur,
        gv.summary_en,
        gv.summary_ur,
        gv.min_grade,
        gv.max_grade,
        gv.status,
        gv.enabled,
        gv.entry_kind,
        gv.entry_ref,
        gv.published_at
      from public.games g
      join lateral (
        select gv2.*
        from public.game_versions gv2
        where gv2.game_id = g.id
        order by
          case gv2.status
            when 'published' then 1
            when 'draft' then 2
            else 3
          end,
          gv2.version desc
        limit 1
      ) gv on true
    ) x
  ), '[]'::jsonb);
end;
$fn$;

revoke all on function public.list_games_admin() from public, anon;
grant execute on function public.list_games_admin()
  to authenticated, service_role;

create or replace function public.create_game_draft(
  p_slug text,
  p_title_en text,
  p_title_ur text default '',
  p_summary_en text default '',
  p_summary_ur text default '',
  p_category text default 'practice',
  p_entry_kind text default 'web',
  p_entry_ref text default 'fixture://pending',
  p_min_grade integer default null,
  p_max_grade integer default null,
  p_game_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_game_id uuid;
  v_version integer;
  v_row public.game_versions%rowtype;
  v_slug text := lower(btrim(coalesce(p_slug, '')));
  v_title text := btrim(coalesce(p_title_en, ''));
  v_category text := lower(btrim(coalesce(p_category, 'practice')));
  v_kind text := lower(btrim(coalesce(p_entry_kind, 'web')));
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NG010',
      message = 'Game admin is limited to platform staff.';
  end if;

  if v_slug !~ '^[a-z][a-z0-9_]{1,62}$' or v_title = '' then
    raise exception using
      errcode = 'NG011',
      message = 'Game slug and English title are required.';
  end if;

  if v_category not in ('practice', 'challenge', 'world') then
    raise exception using errcode = 'NG012', message = 'Unknown game category.';
  end if;

  if v_kind not in ('web', 'flutter') then
    raise exception using errcode = 'NG013', message = 'Unknown entry kind.';
  end if;

  if p_game_id is null then
    insert into public.games (slug, category, sort_order)
    values (
      v_slug,
      v_category,
      coalesce((select max(sort_order) + 10 from public.games), 10)
    )
    returning id into v_game_id;
    v_version := 1;
  else
    if not exists (select 1 from public.games where id = p_game_id) then
      raise exception using errcode = 'NG014', message = 'Unknown game.';
    end if;
    if exists (
      select 1 from public.game_versions
      where game_id = p_game_id and status = 'draft'
    ) then
      raise exception using
        errcode = 'NG015',
        message = 'This game already has a draft. Publish or disable it first.';
    end if;
    v_game_id := p_game_id;
    select coalesce(max(version), 0) + 1 into v_version
    from public.game_versions
    where game_id = v_game_id;
  end if;

  insert into public.game_versions (
    game_id, version, title_en, title_ur, summary_en, summary_ur,
    min_grade, max_grade, status, enabled, entry_kind, entry_ref
  ) values (
    v_game_id, v_version, v_title, coalesce(p_title_ur, ''),
    coalesce(p_summary_en, ''), coalesce(p_summary_ur, ''),
    p_min_grade, p_max_grade, 'draft', true, v_kind,
    coalesce(nullif(btrim(p_entry_ref), ''), 'fixture://pending')
  )
  returning * into v_row;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    auth.uid(),
    'superadmin',
    'create'::public.audit_action_kind,
    'game_version',
    v_row.id::text,
    jsonb_build_object(
      'game_id', v_game_id,
      'slug', v_slug,
      'version', v_version,
      'title_en', v_title
    )
  );

  select slug, category into v_slug, v_category
  from public.games
  where id = v_game_id;

  return jsonb_build_object(
    'game_id', v_game_id,
    'slug', v_slug,
    'category', v_category,
    'game_version_id', v_row.id,
    'version', v_row.version,
    'title_en', v_row.title_en,
    'title_ur', v_row.title_ur,
    'summary_en', v_row.summary_en,
    'summary_ur', v_row.summary_ur,
    'min_grade', v_row.min_grade,
    'max_grade', v_row.max_grade,
    'status', v_row.status,
    'enabled', v_row.enabled,
    'entry_kind', v_row.entry_kind,
    'entry_ref', v_row.entry_ref
  );
end;
$fn$;

revoke all on function public.create_game_draft(
  text, text, text, text, text, text, text, text, integer, integer, uuid
) from public, anon;
grant execute on function public.create_game_draft(
  text, text, text, text, text, text, text, text, integer, integer, uuid
) to authenticated, service_role;

create or replace function public.publish_game_version(p_version_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_row public.game_versions%rowtype;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NG010',
      message = 'Game admin is limited to platform staff.';
  end if;

  select * into v_row from public.game_versions
  where id = p_version_id for update;

  if not found then
    raise exception using errcode = 'NG014', message = 'Unknown game version.';
  end if;

  if v_row.status = 'published' then
    return jsonb_build_object(
      'game_version_id', v_row.id,
      'status', v_row.status,
      'enabled', v_row.enabled
    );
  end if;

  if v_row.status <> 'draft' then
    raise exception using
      errcode = 'NG016',
      message = 'Only drafts can be published.';
  end if;

  if btrim(v_row.title_en) = ''
     or nullif(btrim(v_row.entry_ref), '') is null then
    raise exception using
      errcode = 'NG017',
      message = 'Publish requires a title and entry reference.';
  end if;

  update public.game_versions
  set status = 'archived',
      enabled = false,
      updated_at = timezone('utc', now())
  where game_id = v_row.game_id
    and status = 'published'
    and id <> p_version_id;

  update public.game_versions
  set status = 'published',
      enabled = true,
      published_at = timezone('utc', now()),
      updated_at = timezone('utc', now())
  where id = p_version_id
  returning * into v_row;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    auth.uid(),
    'superadmin',
    'update'::public.audit_action_kind,
    'game_version',
    v_row.id::text,
    jsonb_build_object('status', 'published', 'game_id', v_row.game_id)
  );

  return jsonb_build_object(
    'game_version_id', v_row.id,
    'status', v_row.status,
    'enabled', v_row.enabled,
    'published_at', v_row.published_at
  );
end;
$fn$;

revoke all on function public.publish_game_version(uuid) from public, anon;
grant execute on function public.publish_game_version(uuid)
  to authenticated, service_role;

create or replace function public.disable_game_version(
  p_version_id uuid,
  p_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_row public.game_versions%rowtype;
  v_reason text := btrim(coalesce(p_reason, ''));
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NG010',
      message = 'Game admin is limited to platform staff.';
  end if;

  if v_reason = '' then
    raise exception using
      errcode = 'NG018',
      message = 'A reason is required to disable a game version.';
  end if;

  select * into v_row from public.game_versions
  where id = p_version_id for update;

  if not found then
    raise exception using errcode = 'NG014', message = 'Unknown game version.';
  end if;

  if v_row.status = 'archived' and not v_row.enabled then
    return jsonb_build_object(
      'game_version_id', v_row.id,
      'status', v_row.status,
      'enabled', v_row.enabled
    );
  end if;

  update public.game_versions
  set enabled = false,
      status = case
        when status = 'published' then 'archived'
        else status
      end,
      updated_at = timezone('utc', now())
  where id = p_version_id
  returning * into v_row;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value, reason)
  values (
    auth.uid(),
    'superadmin',
    'revoke'::public.audit_action_kind,
    'game_version',
    v_row.id::text,
    jsonb_build_object(
      'status', v_row.status,
      'enabled', v_row.enabled,
      'game_id', v_row.game_id
    ),
    v_reason
  );

  return jsonb_build_object(
    'game_version_id', v_row.id,
    'status', v_row.status,
    'enabled', v_row.enabled
  );
end;
$fn$;

revoke all on function public.disable_game_version(uuid, text) from public, anon;
grant execute on function public.disable_game_version(uuid, text)
  to authenticated, service_role;
