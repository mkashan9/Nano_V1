-- GME-04: game_assets metadata + learner asset list RPC.

create table if not exists public.game_assets (
  id uuid primary key default gen_random_uuid(),
  game_version_id uuid not null references public.game_versions (id) on delete cascade,
  asset_key text not null
    check (asset_key ~ '^[a-z][a-z0-9_]{0,62}$'),
  content_hash text not null
    check (char_length(btrim(content_hash)) between 8 and 128),
  byte_size bigint not null check (byte_size >= 0),
  source_uri text not null default '',
  sort_order integer not null default 100,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (game_version_id, asset_key)
);

comment on table public.game_assets is
  'GME-04 versioned asset descriptors. Learners read via RPC; no direct grants.';

create index if not exists game_assets_version_idx
  on public.game_assets (game_version_id, sort_order);

drop trigger if exists game_assets_set_updated_at on public.game_assets;
create trigger game_assets_set_updated_at
  before update on public.game_assets
  for each row execute function public.set_updated_at();

alter table public.game_assets enable row level security;

revoke all on table public.game_assets from public, anon, authenticated;
grant all on table public.game_assets to service_role;

-- Seed fixture packs for published Number Rush + Shape Sort.
insert into public.game_assets
  (id, game_version_id, asset_key, content_hash, byte_size, source_uri, sort_order)
values
  (
    '62000000-0000-0000-0000-000000000001',
    '61000000-0000-0000-0000-000000000001',
    'pack',
    'sha256:number_rush_v1_fixture',
    245760,
    'fixture://number_rush/pack',
    10
  ),
  (
    '62000000-0000-0000-0000-000000000002',
    '61000000-0000-0000-0000-000000000002',
    'pack',
    'sha256:shape_sort_v1_fixture',
    327680,
    'fixture://shape_sort/pack',
    10
  )
on conflict (id) do nothing;

create or replace function public.list_game_assets_for_learner(p_version_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_uid uuid := auth.uid();
  v_items jsonb;
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  if p_version_id is null
     or not nano_internal.game_version_is_eligible(p_version_id) then
    raise exception using
      errcode = 'NS143',
      message = 'Game version is not eligible.';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'asset_id', a.id,
    'game_version_id', a.game_version_id,
    'asset_key', a.asset_key,
    'content_hash', a.content_hash,
    'byte_size', a.byte_size,
    'source_uri', a.source_uri,
    'sort_order', a.sort_order
  ) order by a.sort_order, a.asset_key), '[]'::jsonb)
  into v_items
  from public.game_assets a
  where a.game_version_id = p_version_id;

  return jsonb_build_object(
    'game_version_id', p_version_id,
    'assets', v_items,
    'total_bytes', coalesce((
      select sum(a.byte_size)::bigint from public.game_assets a
      where a.game_version_id = p_version_id
    ), 0)
  );
end;
$fn$;

revoke all on function public.list_game_assets_for_learner(uuid) from public, anon;
grant execute on function public.list_game_assets_for_learner(uuid)
  to authenticated, service_role;

comment on function public.list_game_assets_for_learner(uuid) is
  'GME-04 learner asset descriptors for an eligible game version.';
