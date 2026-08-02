-- GME-02 presence: sessions table + start/abort/complete RPCs.

do $$
begin
  if to_regclass('public.game_sessions') is null then
    raise exception 'game_sessions missing';
  end if;
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'start_game_session'
  ) then
    raise exception 'start_game_session missing';
  end if;
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'report_game_client_completed'
  ) then
    raise exception 'report_game_client_completed missing';
  end if;
end $$;
