-- GME-04 presence: game_assets + list RPC.

do $$
begin
  if to_regclass('public.game_assets') is null then
    raise exception 'game_assets missing';
  end if;
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'list_game_assets_for_learner'
  ) then
    raise exception 'list_game_assets_for_learner missing';
  end if;
  if not exists (
    select 1 from public.game_assets
    where game_version_id = '61000000-0000-0000-0000-000000000001'
  ) then
    raise exception 'number_rush assets missing';
  end if;
end $$;
