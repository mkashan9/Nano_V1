-- LGE-03 presence: challenges + rematch RPCs.

do $$
begin
  if to_regclass('public.challenges') is null then
    raise exception 'challenges missing';
  end if;
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'create_league_challenge'
  ) then
    raise exception 'create_league_challenge missing';
  end if;
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'create_league_rematch'
  ) then
    raise exception 'create_league_rematch missing';
  end if;
end $$;
