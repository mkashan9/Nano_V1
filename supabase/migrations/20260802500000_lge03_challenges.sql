-- LGE-03: board-peer challenges + rematches (no friend graph).

create table if not exists public.challenge_rules (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title_en text not null,
  title_ur text not null default '',
  game_version_id uuid not null references public.game_versions (id),
  default_expiry_hours integer not null default 24 check (default_expiry_hours > 0),
  compare_metric text not null default 'verified_score'
    check (compare_metric = 'verified_score'),
  active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now())
);

comment on table public.challenge_rules is
  'LGE-03 challenge templates; pin a published game version.';

create table if not exists public.challenges (
  id uuid primary key default gen_random_uuid(),
  rule_id uuid not null references public.challenge_rules (id),
  challenger_id uuid not null references public.profiles (id),
  opponent_id uuid not null references public.profiles (id),
  game_version_id uuid not null references public.game_versions (id),
  status text not null default 'pending'
    check (status in (
      'pending', 'accepted', 'declined', 'expired',
      'completed', 'cancelled'
    )),
  pool_key text not null,
  expires_at timestamptz not null,
  rematch_of uuid references public.challenges (id) on delete set null,
  challenger_score integer,
  opponent_score integer,
  accepted_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check (challenger_id <> opponent_id)
);

create index if not exists challenges_parties_idx
  on public.challenges (challenger_id, opponent_id, status);

comment on table public.challenges is
  'LGE-03 peer challenges from league board; RPC-only.';

create table if not exists public.challenge_results (
  challenge_id uuid primary key references public.challenges (id) on delete cascade,
  challenger_score integer not null,
  opponent_score integer not null,
  outcome text not null
    check (outcome in ('challenger_win', 'opponent_win', 'tie')),
  settled_at timestamptz not null default timezone('utc', now())
);

comment on table public.challenge_results is
  'LGE-03 settled outcomes from verified game scores.';

create table if not exists public.challenge_target_tokens (
  token text primary key,
  target_user_id uuid not null references public.profiles (id) on delete cascade,
  cycle_id uuid not null references public.league_cycles (id) on delete cascade,
  pool_key text not null,
  expires_at timestamptz not null,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists challenge_target_tokens_expiry_idx
  on public.challenge_target_tokens (expires_at);

alter table public.challenge_rules enable row level security;
alter table public.challenges enable row level security;
alter table public.challenge_results enable row level security;
alter table public.challenge_target_tokens enable row level security;

revoke all on table public.challenge_rules from public, anon, authenticated;
revoke all on table public.challenges from public, anon, authenticated;
revoke all on table public.challenge_results from public, anon, authenticated;
revoke all on table public.challenge_target_tokens from public, anon, authenticated;
grant select on table public.challenge_rules to authenticated;
grant all on table public.challenge_rules to service_role;
grant all on table public.challenges to service_role;
grant all on table public.challenge_results to service_role;
grant all on table public.challenge_target_tokens to service_role;

drop policy if exists challenge_rules_select on public.challenge_rules;
create policy challenge_rules_select on public.challenge_rules
  for select to authenticated using (active);

drop trigger if exists challenges_set_updated_at on public.challenges;
create trigger challenges_set_updated_at
  before update on public.challenges
  for each row execute function public.set_updated_at();

insert into public.challenge_rules (slug, title_en, title_ur, game_version_id)
select
  'number_rush_duel',
  'Number Rush duel',
  'نمبر رش مقابلہ',
  gv.id
from public.game_versions gv
join public.games g on g.id = gv.game_id
where g.slug = 'number_rush'
  and gv.status = 'published'
  and gv.enabled
order by gv.version desc
limit 1
on conflict (slug) do nothing;

create or replace function nano_internal.issue_challenge_target_token(
  p_target_user_id uuid,
  p_cycle_id uuid,
  p_pool_key text
)
returns text
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal, extensions
as $fn$
declare
  v_token text;
  v_discoverable boolean := true;
begin
  select ps.discoverable into v_discoverable
  from public.privacy_settings ps
  where ps.user_id = p_target_user_id;
  if not found then
    v_discoverable := true;
  end if;
  if not v_discoverable then
    return null;
  end if;

  v_token := encode(gen_random_bytes(24), 'hex');
  insert into public.challenge_target_tokens
    (token, target_user_id, cycle_id, pool_key, expires_at)
  values (
    v_token,
    p_target_user_id,
    p_cycle_id,
    p_pool_key,
    timezone('utc', now()) + interval '2 hours'
  );
  return v_token;
end;
$fn$;

create or replace function public.my_league_leaderboard(p_limit integer default 10)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal, extensions
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

  delete from public.challenge_target_tokens
  where expires_at <= timezone('utc', now());

  select coalesce(jsonb_agg(row_to_json(x)::jsonb order by x.rank), '[]'::jsonb)
  into v_entries
  from (
    select
      s.rank,
      s.week_xp,
      s.display_label,
      (s.user_id = v_uid) as is_me,
      case
        when s.user_id = v_uid then null
        else nano_internal.issue_challenge_target_token(
          s.user_id, v_cycle.id, v_pool
        )
      end as target_token
    from public.leaderboard_snapshots s
    where s.cycle_id = v_cycle.id
      and s.division_id = v_part.division_id
      and s.pool_key = v_pool
      and s.rank <= v_limit
    order by s.rank
  ) x;

  if v_part.rank_in_division is not null
     and v_part.rank_in_division > v_limit then
    v_entries := v_entries || jsonb_build_array(
      jsonb_build_object(
        'rank', v_part.rank_in_division,
        'week_xp', v_part.week_xp,
        'display_label', nano_internal.league_privacy_label(v_uid),
        'is_me', true,
        'target_token', null
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

create or replace function nano_internal.challenge_projection(p_row public.challenges)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_uid uuid := auth.uid();
  v_rule public.challenge_rules%rowtype;
  v_peer uuid;
  v_outcome text;
begin
  select * into v_rule from public.challenge_rules where id = p_row.rule_id;
  v_peer := case
    when p_row.challenger_id = v_uid then p_row.opponent_id
    else p_row.challenger_id
  end;
  select r.outcome into v_outcome
  from public.challenge_results r
  where r.challenge_id = p_row.id;

  return jsonb_build_object(
    'id', p_row.id,
    'status', p_row.status,
    'rule_slug', v_rule.slug,
    'title_en', v_rule.title_en,
    'title_ur', v_rule.title_ur,
    'game_version_id', p_row.game_version_id,
    'expires_at', p_row.expires_at,
    'peer_label', nano_internal.league_privacy_label(v_peer),
    'i_am_challenger', p_row.challenger_id = v_uid,
    'my_score', case
      when p_row.challenger_id = v_uid then p_row.challenger_score
      else p_row.opponent_score
    end,
    'peer_score', case
      when p_row.challenger_id = v_uid then p_row.opponent_score
      else p_row.challenger_score
    end,
    'outcome', v_outcome,
    'rematch_of', p_row.rematch_of
  );
end;
$fn$;

create or replace function public.create_league_challenge(
  p_target_token text,
  p_rule_slug text default 'number_rush_duel'
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_uid uuid := auth.uid();
  v_tok public.challenge_target_tokens%rowtype;
  v_rule public.challenge_rules%rowtype;
  v_cycle public.league_cycles%rowtype;
  v_me public.league_participants%rowtype;
  v_them public.league_participants%rowtype;
  v_row public.challenges%rowtype;
  v_pool text;
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  select * into v_tok
  from public.challenge_target_tokens
  where token = p_target_token
    and expires_at > timezone('utc', now())
  for update;

  if not found then
    raise exception using errcode = 'NL010', message = 'Challenge target expired.';
  end if;

  if v_tok.target_user_id = v_uid then
    raise exception using errcode = 'NL011', message = 'Cannot challenge yourself.';
  end if;

  select * into v_rule
  from public.challenge_rules
  where slug = p_rule_slug and active
  limit 1;
  if not found then
    raise exception using errcode = 'NL012', message = 'Challenge rule unavailable.';
  end if;

  v_cycle := nano_internal.ensure_current_league_cycle();
  if v_tok.cycle_id <> v_cycle.id then
    raise exception using errcode = 'NL010', message = 'Challenge target expired.';
  end if;

  select * into v_me
  from public.league_participants
  where cycle_id = v_cycle.id and user_id = v_uid;
  if not found then
    raise exception using errcode = 'NL013', message = 'Join the weekly league first.';
  end if;

  v_pool := coalesce(v_me.school_id::text, 'independent');
  if v_tok.pool_key <> v_pool then
    raise exception using errcode = 'NL014', message = 'Opponent is outside your league pool.';
  end if;

  select * into v_them
  from public.league_participants
  where cycle_id = v_cycle.id and user_id = v_tok.target_user_id;
  if not found
     or coalesce(v_them.school_id::text, 'independent') <> v_pool
     or v_them.division_id <> v_me.division_id then
    raise exception using errcode = 'NL014', message = 'Opponent is outside your league pool.';
  end if;

  insert into public.challenges (
    rule_id, challenger_id, opponent_id, game_version_id,
    status, pool_key, expires_at
  ) values (
    v_rule.id, v_uid, v_tok.target_user_id, v_rule.game_version_id,
    'pending', v_pool,
    timezone('utc', now()) + make_interval(hours => v_rule.default_expiry_hours)
  )
  returning * into v_row;

  delete from public.challenge_target_tokens where token = p_target_token;

  return nano_internal.challenge_projection(v_row);
end;
$fn$;

create or replace function public.respond_league_challenge(
  p_challenge_id uuid,
  p_accept boolean
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_uid uuid := auth.uid();
  v_row public.challenges%rowtype;
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  select * into v_row
  from public.challenges
  where id = p_challenge_id
  for update;

  if not found then
    raise exception using errcode = 'NL015', message = 'Challenge not found.';
  end if;

  if v_row.opponent_id <> v_uid then
    raise exception using errcode = 'NL016', message = 'Only the opponent can respond.';
  end if;

  if v_row.status <> 'pending' then
    return nano_internal.challenge_projection(v_row);
  end if;

  if v_row.expires_at <= timezone('utc', now()) then
    update public.challenges
    set status = 'expired'
    where id = v_row.id
    returning * into v_row;
    return nano_internal.challenge_projection(v_row);
  end if;

  if p_accept then
    update public.challenges
    set status = 'accepted',
        accepted_at = timezone('utc', now())
    where id = v_row.id
    returning * into v_row;
  else
    update public.challenges
    set status = 'declined'
    where id = v_row.id
    returning * into v_row;
  end if;

  return nano_internal.challenge_projection(v_row);
end;
$fn$;

create or replace function public.my_league_challenges()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_uid uuid := auth.uid();
  v_items jsonb := '[]'::jsonb;
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  update public.challenges
  set status = 'expired'
  where status = 'pending'
    and expires_at <= timezone('utc', now())
    and (challenger_id = v_uid or opponent_id = v_uid);

  select coalesce(jsonb_agg(p.proj order by p.created_at desc), '[]'::jsonb)
  into v_items
  from (
    select c.created_at, nano_internal.challenge_projection(c) as proj
    from public.challenges c
    where c.challenger_id = v_uid or c.opponent_id = v_uid
  ) p;

  return jsonb_build_object('challenges', v_items);
end;
$fn$;

create or replace function public.record_league_challenge_score(p_challenge_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_uid uuid := auth.uid();
  v_row public.challenges%rowtype;
  v_score integer;
  v_c integer;
  v_o integer;
  v_outcome text;
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  select * into v_row
  from public.challenges
  where id = p_challenge_id
  for update;

  if not found then
    raise exception using errcode = 'NL015', message = 'Challenge not found.';
  end if;

  if v_uid not in (v_row.challenger_id, v_row.opponent_id) then
    raise exception using errcode = 'NL016', message = 'Not a party to this challenge.';
  end if;

  if v_row.status = 'pending' and v_row.expires_at <= timezone('utc', now()) then
    update public.challenges set status = 'expired' where id = v_row.id
    returning * into v_row;
  end if;

  if v_row.status <> 'accepted' and v_row.status <> 'completed' then
    raise exception using errcode = 'NL017', message = 'Challenge is not open for scores.';
  end if;

  select max(gr.verified_score) into v_score
  from public.game_results gr
  where gr.user_id = v_uid
    and gr.game_version_id = v_row.game_version_id
    and gr.verified_at >= coalesce(v_row.accepted_at, v_row.created_at);

  if v_score is null then
    raise exception using errcode = 'NL018',
      message = 'Play the challenge game first (verified result required).';
  end if;

  if v_uid = v_row.challenger_id then
    update public.challenges
    set challenger_score = v_score
    where id = v_row.id
    returning * into v_row;
  else
    update public.challenges
    set opponent_score = v_score
    where id = v_row.id
    returning * into v_row;
  end if;

  if v_row.challenger_score is not null and v_row.opponent_score is not null then
    v_c := v_row.challenger_score;
    v_o := v_row.opponent_score;
    v_outcome := case
      when v_c > v_o then 'challenger_win'
      when v_o > v_c then 'opponent_win'
      else 'tie'
    end;
    insert into public.challenge_results (
      challenge_id, challenger_score, opponent_score, outcome
    ) values (v_row.id, v_c, v_o, v_outcome)
    on conflict (challenge_id) do update
      set challenger_score = excluded.challenger_score,
          opponent_score = excluded.opponent_score,
          outcome = excluded.outcome,
          settled_at = timezone('utc', now());
    update public.challenges
    set status = 'completed'
    where id = v_row.id
    returning * into v_row;
  end if;

  return nano_internal.challenge_projection(v_row);
end;
$fn$;

create or replace function public.create_league_rematch(p_challenge_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_uid uuid := auth.uid();
  v_old public.challenges%rowtype;
  v_rule public.challenge_rules%rowtype;
  v_row public.challenges%rowtype;
  v_opponent uuid;
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  select * into v_old from public.challenges where id = p_challenge_id;
  if not found then
    raise exception using errcode = 'NL015', message = 'Challenge not found.';
  end if;

  if v_uid not in (v_old.challenger_id, v_old.opponent_id) then
    raise exception using errcode = 'NL016', message = 'Not a party to this challenge.';
  end if;

  if v_old.status <> 'completed' then
    raise exception using errcode = 'NL019', message = 'Rematch needs a completed challenge.';
  end if;

  select * into v_rule from public.challenge_rules where id = v_old.rule_id;
  v_opponent := case
    when v_uid = v_old.challenger_id then v_old.opponent_id
    else v_old.challenger_id
  end;

  insert into public.challenges (
    rule_id, challenger_id, opponent_id, game_version_id,
    status, pool_key, expires_at, rematch_of
  ) values (
    v_old.rule_id, v_uid, v_opponent, v_rule.game_version_id,
    'pending', v_old.pool_key,
    timezone('utc', now()) + make_interval(hours => v_rule.default_expiry_hours),
    v_old.id
  )
  returning * into v_row;

  return nano_internal.challenge_projection(v_row);
end;
$fn$;

revoke all on function public.create_league_challenge(text, text) from public, anon;
revoke all on function public.respond_league_challenge(uuid, boolean) from public, anon;
revoke all on function public.my_league_challenges() from public, anon;
revoke all on function public.record_league_challenge_score(uuid) from public, anon;
revoke all on function public.create_league_rematch(uuid) from public, anon;

grant execute on function public.create_league_challenge(text, text)
  to authenticated, service_role;
grant execute on function public.respond_league_challenge(uuid, boolean)
  to authenticated, service_role;
grant execute on function public.my_league_challenges()
  to authenticated, service_role;
grant execute on function public.record_league_challenge_score(uuid)
  to authenticated, service_role;
grant execute on function public.create_league_rematch(uuid)
  to authenticated, service_role;
