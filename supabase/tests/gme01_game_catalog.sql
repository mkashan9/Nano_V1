-- GME-01 presence: independent_allowed + learner list RPC.

do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'game_versions'
      and column_name = 'independent_allowed'
  ) then
    raise exception 'independent_allowed missing';
  end if;
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'list_games_for_learner'
  ) then
    raise exception 'list_games_for_learner missing';
  end if;
end $$;
