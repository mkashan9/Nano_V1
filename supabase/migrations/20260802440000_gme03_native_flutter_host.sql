-- GME-03: allow Flutter-native sessions; publish Shape Sort native fixture.

create or replace function public.start_game_session(p_version_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal, extensions
as $fn$
declare
  v_uid uuid := auth.uid();
  v_profile public.profiles%rowtype;
  v_version public.game_versions%rowtype;
  v_game public.games%rowtype;
  v_school_id uuid;
  v_token text;
  v_hash text;
  v_origins text[];
  v_session public.game_sessions%rowtype;
  v_ttl interval := interval '30 minutes';
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  select * into v_profile from public.profiles where id = v_uid;
  if not found or v_profile.account_kind not in (
    'school_student'::public.account_kind,
    'independent_student'::public.account_kind
  ) then
    raise exception using
      errcode = 'NS142',
      message = 'Games are for students only.';
  end if;

  select sm.school_id into v_school_id
  from public.school_memberships sm
  where sm.user_id = v_uid
    and sm.status = 'active'::public.membership_status
  order by sm.created_at
  limit 1;

  if p_version_id is null
     or not nano_internal.game_version_is_eligible(p_version_id) then
    raise exception using
      errcode = 'NS143',
      message = 'Game version is not eligible to play.';
  end if;

  select * into v_version from public.game_versions where id = p_version_id;
  select * into v_game from public.games where id = v_version.game_id;

  if v_version.entry_kind not in ('web', 'flutter') then
    raise exception using
      errcode = 'NS144',
      message = 'Unsupported game entry kind.';
  end if;

  v_origins := nano_internal.game_allowed_origins(v_version.entry_ref);
  if coalesce(array_length(v_origins, 1), 0) = 0 then
    raise exception using
      errcode = 'NS145',
      message = 'Game entry has no registered origin.';
  end if;

  update public.game_sessions
  set status = 'expired',
      ended_at = timezone('utc', now())
  where user_id = v_uid
    and game_version_id = p_version_id
    and status = 'active'
    and expires_at <= timezone('utc', now());

  update public.game_sessions
  set status = 'aborted',
      ended_at = timezone('utc', now())
  where user_id = v_uid
    and game_version_id = p_version_id
    and status = 'active';

  v_token := encode(gen_random_bytes(32), 'hex');
  v_hash := encode(digest(v_token, 'sha256'), 'hex');

  insert into public.game_sessions (
    user_id, school_id, game_version_id, status, play_token_hash,
    entry_kind, entry_ref, allowed_origins, expires_at
  ) values (
    v_uid,
    v_school_id,
    p_version_id,
    'active',
    v_hash,
    v_version.entry_kind,
    v_version.entry_ref,
    v_origins,
    timezone('utc', now()) + v_ttl
  )
  returning * into v_session;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    v_uid,
    'student',
    v_school_id,
    'create'::public.audit_action_kind,
    'game_session',
    v_session.id::text,
    jsonb_build_object(
      'game_version_id', p_version_id,
      'entry_kind', v_version.entry_kind,
      'entry_ref', v_version.entry_ref,
      'expires_at', v_session.expires_at
    )
  );

  return jsonb_build_object(
    'session_id', v_session.id,
    'play_token', v_token,
    'game_version_id', v_version.id,
    'game_id', v_game.id,
    'slug', v_game.slug,
    'version', v_version.version,
    'title_en', v_version.title_en,
    'title_ur', v_version.title_ur,
    'entry_kind', v_version.entry_kind,
    'entry_ref', v_version.entry_ref,
    'allowed_origins', to_jsonb(v_origins),
    'expires_at', v_session.expires_at,
    'locale_hint', 'en'
  );
end;
$fn$;

comment on function public.start_game_session(uuid) is
  'GME-02/03 start eligible web or Flutter game session; one-time play_token.';

-- Publish Shape Sort as the first Flutter-native fixture (grades 1–3).
update public.game_versions
set status = 'published',
    enabled = true,
    independent_allowed = true,
    published_at = coalesce(published_at, timezone('utc', now())),
    updated_at = timezone('utc', now())
where id = '61000000-0000-0000-0000-000000000002'
  and entry_kind = 'flutter';
