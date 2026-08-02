-- SOC-03: privacy-safe friends weekly leaderboard (league week XP).

create or replace function public.my_friends_leaderboard(p_limit integer default 25)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_uid uuid := auth.uid();
  v_cycle public.league_cycles%rowtype;
  v_limit integer := greatest(1, least(coalesce(p_limit, 25), 50));
  v_entries jsonb := '[]'::jsonb;
  v_my_rank integer;
  v_my_xp integer := 0;
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  v_cycle := nano_internal.ensure_current_league_cycle();

  with peers as (
    select v_uid as user_id
    union
    select case
      when f.user_low = v_uid then f.user_high
      else f.user_low
    end
    from public.friendships f
    where f.user_low = v_uid or f.user_high = v_uid
  ),
  scored as (
    select
      p.user_id,
      coalesce(lp.week_xp, 0) as week_xp
    from peers p
    left join public.league_participants lp
      on lp.user_id = p.user_id
     and lp.cycle_id = v_cycle.id
  ),
  ranked as (
    select
      s.user_id,
      s.week_xp,
      dense_rank() over (
        order by s.week_xp desc, s.user_id
      ) as rank
    from scored s
  )
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'rank', r.rank,
      'week_xp', r.week_xp,
      'display_label', case
        when r.user_id = v_uid then nano_internal.league_privacy_label(v_uid)
        else nano_internal.league_privacy_label(r.user_id)
      end,
      'is_me', r.user_id = v_uid
    )
    order by r.rank, r.user_id
  ), '[]'::jsonb)
  into v_entries
  from ranked r
  where r.rank <= v_limit
     or r.user_id = v_uid;

  select r.rank, r.week_xp into v_my_rank, v_my_xp
  from (
    with peers as (
      select v_uid as user_id
      union
      select case
        when f.user_low = v_uid then f.user_high
        else f.user_low
      end
      from public.friendships f
      where f.user_low = v_uid or f.user_high = v_uid
    ),
    scored as (
      select
        p.user_id,
        coalesce(lp.week_xp, 0) as week_xp
      from peers p
      left join public.league_participants lp
        on lp.user_id = p.user_id
       and lp.cycle_id = v_cycle.id
    )
    select
      s.user_id,
      s.week_xp,
      dense_rank() over (order by s.week_xp desc, s.user_id) as rank
    from scored s
  ) r
  where r.user_id = v_uid;

  return jsonb_build_object(
    'week_key', v_cycle.week_key,
    'entries', v_entries,
    'my_rank', v_my_rank,
    'my_week_xp', coalesce(v_my_xp, 0),
    'friend_count', (
      select count(*)::integer
      from public.friendships f
      where f.user_low = v_uid or f.user_high = v_uid
    )
  );
end;
$fn$;

revoke all on function public.my_friends_leaderboard(integer) from public, anon;
grant execute on function public.my_friends_leaderboard(integer)
  to authenticated, service_role;

comment on function public.my_friends_leaderboard(integer) is
  'SOC-03 weekly XP ranks among caller + friends. Labels only; no peer user ids.';
