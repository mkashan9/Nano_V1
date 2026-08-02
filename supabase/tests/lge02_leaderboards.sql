-- LGE-02 presence: snapshots + leaderboard RPC.

do $$
begin
  if to_regclass('public.leaderboard_snapshots') is null then
    raise exception 'leaderboard_snapshots missing';
  end if;
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'my_league_leaderboard'
  ) then
    raise exception 'my_league_leaderboard missing';
  end if;
end $$;
