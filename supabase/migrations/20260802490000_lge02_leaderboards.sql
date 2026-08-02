-- LGE-02: privacy-safe weekly leaderboard for caller's division/school pool.

create table if not exists public.leaderboard_snapshots (
  id uuid primary key default gen_random_uuid(),
  cycle_id uuid not null references public.league_cycles (id) on delete cascade,
  division_id uuid not null references public.league_divisions (id),
  pool_key text not null,
  rank integer not null check (rank > 0),
  user_id uuid not null references public.profiles (id) on delete cascade,
  week_xp integer not null default 0 check (week_xp >= 0),
  display_label text not null,
  captured_at timestamptz not null default timezone('utc', now()),
  unique (cycle_id, division_id, pool_key, user_id)
);

create index if not exists leaderboard_snapshots_pool_rank_idx
  on public.leaderboard_snapshots (cycle_id, division_id, pool_key, rank);

comment on table public.leaderboard_snapshots is
  'LGE-02 server-written weekly board rows; clients cannot edit.';

alter table public.leaderboard_snapshots enable row level security;

revoke all on table public.leaderboard_snapshots from public, anon, authenticated;
grant all on table public.leaderboard_snapshots to service_role;

-- No direct client select — read via RPC only.

create or replace function nano_internal.league_privacy_label(p_user_id uuid)
returns text
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_name text;
  v_discoverable boolean := true;
  v_first text;
begin
  select p.display_name into v_name
  from public.profiles p
  where p.id = p_user_id;

  v_discoverable := true;
  select ps.discoverable into v_discoverable
  from public.privacy_settings ps
  where ps.user_id = p_user_id;
  if not found then
    v_discoverable := true;
  end if;

  if not v_discoverable then
    return 'Learner';
  end if;

  v_name := btrim(coalesce(v_name, ''));
  if v_name = '' then
    return 'Learner';
  end if;

  v_first := split_part(v_name, ' ', 1);
  if v_first = '' then
    return 'Learner';
  end if;
  return v_first;
end;
$fn$;

create or replace function nano_internal.refresh_league_snapshots(
  p_cycle_id uuid,
  p_limit integer default 20
)
returns integer
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_limit integer := greatest(1, least(coalesce(p_limit, 20), 50));
  v_count integer := 0;
begin
  perform nano_internal.refresh_league_scores(p_cycle_id);

  delete from public.leaderboard_snapshots
  where cycle_id = p_cycle_id;

  insert into public.leaderboard_snapshots (
    cycle_id, division_id, pool_key, rank, user_id, week_xp, display_label
  )
  select
    p.cycle_id,
    p.division_id,
    coalesce(p.school_id::text, 'independent') as pool_key,
    p.rank_in_division,
    p.user_id,
    p.week_xp,
    nano_internal.league_privacy_label(p.user_id)
  from public.league_participants p
  where p.cycle_id = p_cycle_id
    and p.rank_in_division is not null
    and p.rank_in_division <= v_limit;

  get diagnostics v_count = row_count;
  return v_count;
end;
$fn$;

create or replace function public.my_league_leaderboard(p_limit integer default 10)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_uid uuid := auth.uid();
  v_cycle public.league_cycles%rowtype;
  v_part public.league_participants%rowtype;
  v_div public.league_divisions%rowtype;
  v_pool text;
  v_limit integer := greatest(1, least(coalesce(p_limit, 10), 25));
  v_entries jsonb := '[]'::jsonb;
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  v_cycle := nano_internal.ensure_current_league_cycle();

  select * into v_part
  from public.league_participants
  where cycle_id = v_cycle.id and user_id = v_uid;

  if not found then
    return jsonb_build_object(
      'joined', false,
      'week_key', v_cycle.week_key,
      'entries', '[]'::jsonb,
      'my_rank', null,
      'my_week_xp', 0,
      'division_slug', null,
      'division_title_en', null,
      'division_title_ur', null
    );
  end if;

  perform nano_internal.refresh_league_snapshots(v_cycle.id, 20);

  select * into v_part
  from public.league_participants
  where id = v_part.id;

  select * into v_div from public.league_divisions where id = v_part.division_id;
  v_pool := coalesce(v_part.school_id::text, 'independent');

  select coalesce(jsonb_agg(row_to_json(x)::jsonb order by x.rank), '[]'::jsonb)
  into v_entries
  from (
    select
      s.rank,
      s.week_xp,
      s.display_label,
      (s.user_id = v_uid) as is_me
    from public.leaderboard_snapshots s
    where s.cycle_id = v_cycle.id
      and s.division_id = v_part.division_id
      and s.pool_key = v_pool
      and s.rank <= v_limit
    order by s.rank
  ) x;

  -- Ensure caller appears even if outside top N.
  if v_part.rank_in_division is not null
     and v_part.rank_in_division > v_limit then
    v_entries := v_entries || jsonb_build_array(
      jsonb_build_object(
        'rank', v_part.rank_in_division,
        'week_xp', v_part.week_xp,
        'display_label', nano_internal.league_privacy_label(v_uid),
        'is_me', true
      )
    );
  end if;

  return jsonb_build_object(
    'joined', true,
    'week_key', v_cycle.week_key,
    'entries', v_entries,
    'my_rank', v_part.rank_in_division,
    'my_week_xp', v_part.week_xp,
    'division_slug', v_div.slug,
    'division_title_en', v_div.title_en,
    'division_title_ur', v_div.title_ur
  );
end;
$fn$;

revoke all on function public.my_league_leaderboard(integer) from public, anon;
grant execute on function public.my_league_leaderboard(integer)
  to authenticated, service_role;

comment on function public.my_league_leaderboard(integer) is
  'LGE-02 privacy-safe top ranks for caller division/school pool.';
