-- GME-07: kill switch aborts active sessions; learner play-status poll.

create or replace function public.disable_game_version(
  p_version_id uuid,
  p_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_row public.game_versions%rowtype;
  v_reason text := btrim(coalesce(p_reason, ''));
  v_aborted integer := 0;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NG010',
      message = 'Game admin is limited to platform staff.';
  end if;

  if v_reason = '' then
    raise exception using
      errcode = 'NG018',
      message = 'A reason is required to disable a game version.';
  end if;

  select * into v_row from public.game_versions
  where id = p_version_id for update;

  if not found then
    raise exception using errcode = 'NG014', message = 'Unknown game version.';
  end if;

  if v_row.status = 'archived' and not v_row.enabled then
    update public.game_sessions
    set status = 'aborted',
        ended_at = timezone('utc', now())
    where game_version_id = p_version_id
      and status = 'active';
    get diagnostics v_aborted = row_count;

    return jsonb_build_object(
      'game_version_id', v_row.id,
      'status', v_row.status,
      'enabled', v_row.enabled,
      'aborted_sessions', v_aborted
    );
  end if;

  update public.game_versions
  set enabled = false,
      status = case
        when status = 'published' then 'archived'
        else status
      end,
      updated_at = timezone('utc', now())
  where id = p_version_id
  returning * into v_row;

  update public.game_sessions
  set status = 'aborted',
      ended_at = timezone('utc', now())
  where game_version_id = p_version_id
    and status = 'active';
  get diagnostics v_aborted = row_count;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value, reason)
  values (
    auth.uid(),
    'superadmin',
    'revoke'::public.audit_action_kind,
    'game_version',
    v_row.id::text,
    jsonb_build_object(
      'status', v_row.status,
      'enabled', v_row.enabled,
      'game_id', v_row.game_id,
      'aborted_sessions', v_aborted
    ),
    v_reason
  );

  return jsonb_build_object(
    'game_version_id', v_row.id,
    'status', v_row.status,
    'enabled', v_row.enabled,
    'aborted_sessions', v_aborted
  );
end;
$fn$;

comment on function public.disable_game_version(uuid, text) is
  'ADM-06/GME-07: disable version and abort active learner sessions.';

create or replace function public.get_game_session_play_status(p_session_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_uid uuid := auth.uid();
  v_row public.game_sessions%rowtype;
  v_eligible boolean := false;
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  select * into v_row
  from public.game_sessions
  where id = p_session_id and user_id = v_uid
  for update;

  if not found then
    raise exception using errcode = 'NS146', message = 'Game session not found.';
  end if;

  v_eligible := nano_internal.game_version_is_eligible(v_row.game_version_id);

  if v_row.status = 'active' and v_row.expires_at <= timezone('utc', now()) then
    update public.game_sessions
    set status = 'expired',
        ended_at = timezone('utc', now())
    where id = v_row.id
    returning * into v_row;
  end if;

  if v_row.status = 'active' and not v_eligible then
    update public.game_sessions
    set status = 'aborted',
        ended_at = timezone('utc', now())
    where id = v_row.id
    returning * into v_row;
  end if;

  return jsonb_build_object(
    'session_id', v_row.id,
    'status', v_row.status,
    'version_eligible', v_eligible,
    'kill_switch', (v_row.status = 'aborted') or (not v_eligible)
  );
end;
$fn$;

revoke all on function public.get_game_session_play_status(uuid) from public, anon;
grant execute on function public.get_game_session_play_status(uuid)
  to authenticated, service_role;

comment on function public.get_game_session_play_status(uuid) is
  'GME-07 learner poll: session status + kill-switch detection.';
