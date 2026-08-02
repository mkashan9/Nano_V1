-- LGE-01: weekly leagues (cycles, divisions, personal participation).
-- Ranking uses verified game_result XP for the open week only.

create table if not exists public.league_cycles (
  id uuid primary key default gen_random_uuid(),
  week_key text not null unique,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status text not null default 'open'
    check (status in ('open', 'closed')),
  created_at timestamptz not null default timezone('utc', now()),
  check (ends_at > starts_at)
);

comment on table public.league_cycles is
  'LGE-01 ISO-week competition windows; server-owned.';

create table if not exists public.league_divisions (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title_en text not null,
  title_ur text not null default '',
  sort_order integer not null default 0,
  created_at timestamptz not null default timezone('utc', now())
);

comment on table public.league_divisions is
  'LGE-01 static division labels (Bronze/Silver/Gold).';

create table if not exists public.league_participants (
  id uuid primary key default gen_random_uuid(),
  cycle_id uuid not null references public.league_cycles (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  division_id uuid not null references public.league_divisions (id),
  school_id uuid references public.schools (id) on delete set null,
  week_xp integer not null default 0 check (week_xp >= 0),
  rank_in_division integer,
  joined_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (cycle_id, user_id)
);

create index if not exists league_participants_cycle_div_idx
  on public.league_participants (cycle_id, division_id, week_xp desc);

comment on table public.league_participants is
  'LGE-01 learners in a weekly cycle; scores/ranks server-written.';

drop trigger if exists league_participants_set_updated_at
  on public.league_participants;
create trigger league_participants_set_updated_at
  before update on public.league_participants
  for each row execute function public.set_updated_at();

alter table public.league_cycles enable row level security;
alter table public.league_divisions enable row level security;
alter table public.league_participants enable row level security;

revoke all on table public.league_cycles from public, anon, authenticated;
revoke all on table public.league_divisions from public, anon, authenticated;
revoke all on table public.league_participants from public, anon, authenticated;
grant select on table public.league_cycles to authenticated;
grant select on table public.league_divisions to authenticated;
grant select on table public.league_participants to authenticated;
grant all on table public.league_cycles to service_role;
grant all on table public.league_divisions to service_role;
grant all on table public.league_participants to service_role;

drop policy if exists league_cycles_select on public.league_cycles;
create policy league_cycles_select on public.league_cycles
  for select to authenticated using (true);

drop policy if exists league_divisions_select on public.league_divisions;
create policy league_divisions_select on public.league_divisions
  for select to authenticated using (true);

drop policy if exists league_participants_select_own on public.league_participants;
create policy league_participants_select_own on public.league_participants
  for select to authenticated
  using (user_id = auth.uid() or nano_internal.is_platform_admin());

insert into public.league_divisions (slug, title_en, title_ur, sort_order)
values
  ('bronze', 'Bronze', 'کانسی', 10),
  ('silver', 'Silver', 'چاندی', 20),
  ('gold', 'Gold', 'سونا', 30)
on conflict (slug) do nothing;

create or replace function nano_internal.ensure_current_league_cycle()
returns public.league_cycles
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_key text := to_char(timezone('utc', now()), 'IYYY-"W"IW');
  v_start timestamptz := date_trunc('week', timezone('utc', now()));
  v_end timestamptz := v_start + interval '7 days';
  v_row public.league_cycles%rowtype;
begin
  select * into v_row from public.league_cycles where week_key = v_key;
  if found then
    return v_row;
  end if;

  -- Close any stray open cycles from prior weeks.
  update public.league_cycles
  set status = 'closed'
  where status = 'open' and week_key <> v_key;

  insert into public.league_cycles (week_key, starts_at, ends_at, status)
  values (v_key, v_start, v_end, 'open')
  on conflict (week_key) do update
    set status = excluded.status
  returning * into v_row;

  return v_row;
end;
$fn$;

create or replace function nano_internal.refresh_league_scores(p_cycle_id uuid)
returns integer
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_cycle public.league_cycles%rowtype;
  v_updated integer := 0;
begin
  select * into v_cycle from public.league_cycles where id = p_cycle_id;
  if not found then
    return 0;
  end if;

  update public.league_participants p
  set week_xp = coalesce((
        select sum(l.amount)::integer
        from public.xp_ledger l
        where l.user_id = p.user_id
          and l.source_kind = 'game_result'
          and l.awarded_at >= v_cycle.starts_at
          and l.awarded_at < v_cycle.ends_at
      ), 0),
      updated_at = timezone('utc', now())
  where p.cycle_id = p_cycle_id;

  get diagnostics v_updated = row_count;

  with ranked as (
    select
      p.id,
      dense_rank() over (
        partition by p.division_id, coalesce(p.school_id::text, 'independent')
        order by p.week_xp desc, p.joined_at asc, p.user_id
      ) as rnk
    from public.league_participants p
    where p.cycle_id = p_cycle_id
  )
  update public.league_participants p
  set rank_in_division = ranked.rnk,
      updated_at = timezone('utc', now())
  from ranked
  where p.id = ranked.id;

  return v_updated;
end;
$fn$;

create or replace function public.my_league_status()
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
  v_peers integer := 0;
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
      'starts_at', v_cycle.starts_at,
      'ends_at', v_cycle.ends_at,
      'status', v_cycle.status,
      'week_xp', 0,
      'rank', null,
      'peer_count', 0,
      'division_slug', null,
      'division_title_en', null,
      'division_title_ur', null
    );
  end if;

  perform nano_internal.refresh_league_scores(v_cycle.id);

  select * into v_part
  from public.league_participants
  where id = v_part.id;

  select * into v_div from public.league_divisions where id = v_part.division_id;

  select count(*)::integer into v_peers
  from public.league_participants p
  where p.cycle_id = v_cycle.id
    and p.division_id = v_part.division_id
    and coalesce(p.school_id::text, 'independent') =
        coalesce(v_part.school_id::text, 'independent');

  return jsonb_build_object(
    'joined', true,
    'week_key', v_cycle.week_key,
    'starts_at', v_cycle.starts_at,
    'ends_at', v_cycle.ends_at,
    'status', v_cycle.status,
    'week_xp', v_part.week_xp,
    'rank', v_part.rank_in_division,
    'peer_count', v_peers,
    'division_slug', v_div.slug,
    'division_title_en', v_div.title_en,
    'division_title_ur', v_div.title_ur
  );
end;
$fn$;

create or replace function public.join_current_league()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_uid uuid := auth.uid();
  v_cycle public.league_cycles%rowtype;
  v_div uuid;
  v_school uuid;
  v_part public.league_participants%rowtype;
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  v_cycle := nano_internal.ensure_current_league_cycle();

  select id into v_div
  from public.league_divisions
  where slug = 'bronze'
  order by sort_order
  limit 1;

  if v_div is null then
    raise exception using errcode = 'NL001', message = 'League divisions are not seeded.';
  end if;

  select sm.school_id into v_school
  from public.school_memberships sm
  where sm.user_id = v_uid
    and sm.status = 'active'::public.membership_status
  order by sm.created_at
  limit 1;

  insert into public.league_participants
    (cycle_id, user_id, division_id, school_id)
  values (v_cycle.id, v_uid, v_div, v_school)
  on conflict (cycle_id, user_id) do update
    set updated_at = timezone('utc', now())
  returning * into v_part;

  perform nano_internal.refresh_league_scores(v_cycle.id);

  return public.my_league_status();
end;
$fn$;

revoke all on function public.join_current_league() from public, anon;
revoke all on function public.my_league_status() from public, anon;
grant execute on function public.join_current_league()
  to authenticated, service_role;
grant execute on function public.my_league_status()
  to authenticated, service_role;

comment on function public.join_current_league() is
  'LGE-01 join current weekly league (idempotent).';
comment on function public.my_league_status() is
  'LGE-01 personal weekly league status card payload.';
