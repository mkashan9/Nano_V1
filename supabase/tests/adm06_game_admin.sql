-- ADM-06: game admin RPCs exist for platform staff.

begin;

do $$
begin
  if to_regclass('public.games') is null then
    raise exception 'games table missing';
  end if;
  if to_regclass('public.game_versions') is null then
    raise exception 'game_versions table missing';
  end if;
  if to_regprocedure('public.list_games_admin()') is null then
    raise exception 'list_games_admin missing';
  end if;
  if to_regprocedure(
    'public.create_game_draft(text, text, text, text, text, text, text, text, integer, integer, uuid)'
  ) is null then
    raise exception 'create_game_draft missing';
  end if;
  if to_regprocedure('public.publish_game_version(uuid)') is null then
    raise exception 'publish_game_version missing';
  end if;
  if to_regprocedure('public.disable_game_version(uuid, text)') is null then
    raise exception 'disable_game_version missing';
  end if;
  if has_function_privilege(
    'anon', 'public.publish_game_version(uuid)', 'execute'
  ) then
    raise exception 'anon must not publish games';
  end if;

  raise notice 'adm06_game_admin: ok';
end;
$$;

rollback;
