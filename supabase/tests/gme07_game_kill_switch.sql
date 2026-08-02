-- GME-07 presence: disable aborts sessions + play-status RPC.

do $$
begin
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'disable_game_version'
  ) then
    raise exception 'disable_game_version missing';
  end if;
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'get_game_session_play_status'
  ) then
    raise exception 'get_game_session_play_status missing';
  end if;
end $$;
