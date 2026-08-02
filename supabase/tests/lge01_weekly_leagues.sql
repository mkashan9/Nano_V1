-- LGE-01 presence: weekly league tables + RPCs.

do $$
begin
  if to_regclass('public.league_cycles') is null then
    raise exception 'league_cycles missing';
  end if;
  if to_regclass('public.league_participants') is null then
    raise exception 'league_participants missing';
  end if;
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'join_current_league'
  ) then
    raise exception 'join_current_league missing';
  end if;
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'my_league_status'
  ) then
    raise exception 'my_league_status missing';
  end if;
end $$;
