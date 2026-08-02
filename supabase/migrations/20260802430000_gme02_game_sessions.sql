-- GME-02: short-lived game sessions + play tokens for the secure host.
-- Score verification / XP stay with GME-05.

create table if not exists public.game_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  school_id uuid references public.schools (id) on delete set null,
  game_version_id uuid not null references public.game_versions (id),
  status text not null default 'active'
    check (status in ('active', 'completed', 'aborted', 'expired')),
  play_token_hash text not null,
  entry_kind text not null
    check (entry_kind in ('web', 'flutter')),
  entry_ref text not null,
  allowed_origins text[] not null default '{}',
  expires_at timestamptz not null,
  started_at timestamptz not null default timezone('utc', now()),
  ended_at timestamptz,
  client_completed_at timestamptz,
  raw_client_payload jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.game_sessions is
  'GME-02 learner play sessions. Token plaintext is returned once at start; '
  'XP/verify deferred to GME-05.';

create unique index if not exists game_sessions_one_active_idx
  on public.game_sessions (user_id, game_version_id)
  where status = 'active';

create index if not exists game_sessions_user_idx
  on public.game_sessions (user_id, started_at desc);

drop trigger if exists game_sessions_set_updated_at on public.game_sessions;
create trigger game_sessions_set_updated_at
  before update on public.game_sessions
  for each row execute function public.set_updated_at();

alter table public.game_sessions enable row level security;

-- RPC-only; no authenticated table grants.
revoke all on table public.game_sessions from public, anon, authenticated;
grant all on table public.game_sessions to service_role;

create or replace function nano_internal.game_allowed_origins(p_entry_ref text)
returns text[]
language plpgsql
immutable
as $$
declare
  v_ref text := btrim(coalesce(p_entry_ref, ''));
  v_host text;
begin
  if v_ref like 'fixture://%' then
    return array[v_ref];
  end if;
  if v_ref ~* '^https://' then
    v_host := substring(v_ref from '^https://([^/]+)');
    if v_host is null or v_host = '' then
      return '{}'::text[];
    end if;
    return array['https://' || lower(v_host)];
  end if;
  return '{}'::text[];
end;
$$;

revoke all on function nano_internal.game_allowed_origins(text) from public, anon;
grant execute on function nano_internal.game_allowed_origins(text)
  to authenticated, service_role;

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

  if v_version.entry_kind <> 'web' then
    raise exception using
      errcode = 'NS144',
      message = 'Only web games can open in the secure container.';
  end if;

  v_origins := nano_internal.game_allowed_origins(v_version.entry_ref);
  if coalesce(array_length(v_origins, 1), 0) = 0 then
    raise exception using
      errcode = 'NS145',
      message = 'Game entry has no registered origin.';
  end if;

  -- Expire any stale active rows for this learner+version.
  update public.game_sessions
  set status = 'expired',
      ended_at = timezone('utc', now())
  where user_id = v_uid
    and game_version_id = p_version_id
    and status = 'active'
    and expires_at <= timezone('utc', now());

  -- Abort remaining active sessions for this version (one active at a time).
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

revoke all on function public.start_game_session(uuid) from public, anon;
grant execute on function public.start_game_session(uuid)
  to authenticated, service_role;

comment on function public.start_game_session(uuid) is
  'GME-02 start eligible web game session; returns one-time play_token.';

create or replace function public.abort_game_session(p_session_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_uid uuid := auth.uid();
  v_row public.game_sessions%rowtype;
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

  if v_row.status = 'active' then
    update public.game_sessions
    set status = 'aborted',
        ended_at = timezone('utc', now())
    where id = v_row.id
    returning * into v_row;
  end if;

  return jsonb_build_object(
    'session_id', v_row.id,
    'status', v_row.status
  );
end;
$fn$;

revoke all on function public.abort_game_session(uuid) from public, anon;
grant execute on function public.abort_game_session(uuid)
  to authenticated, service_role;

create or replace function public.report_game_client_completed(
  p_session_id uuid,
  p_play_token text,
  p_payload jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal, extensions
as $fn$
declare
  v_uid uuid := auth.uid();
  v_row public.game_sessions%rowtype;
  v_hash text;
  v_payload jsonb := coalesce(p_payload, '{}'::jsonb);
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  if char_length(coalesce(p_play_token, '')) < 16 then
    raise exception using errcode = 'NS147', message = 'Invalid play token.';
  end if;

  if octet_length(v_payload::text) > 8192 then
    raise exception using errcode = 'NS148', message = 'Payload too large.';
  end if;

  select * into v_row
  from public.game_sessions
  where id = p_session_id and user_id = v_uid
  for update;

  if not found then
    raise exception using errcode = 'NS146', message = 'Game session not found.';
  end if;

  if v_row.status <> 'active' then
    return jsonb_build_object(
      'session_id', v_row.id,
      'status', v_row.status,
      'verified', false,
      'message', 'Session already closed.'
    );
  end if;

  if v_row.expires_at <= timezone('utc', now()) then
    update public.game_sessions
    set status = 'expired',
        ended_at = timezone('utc', now())
    where id = v_row.id;
    raise exception using errcode = 'NS149', message = 'Game session expired.';
  end if;

  v_hash := encode(digest(p_play_token, 'sha256'), 'hex');
  if v_hash <> v_row.play_token_hash then
    raise exception using errcode = 'NS147', message = 'Invalid play token.';
  end if;

  update public.game_sessions
  set status = 'completed',
      ended_at = timezone('utc', now()),
      client_completed_at = timezone('utc', now()),
      raw_client_payload = v_payload
  where id = v_row.id
  returning * into v_row;

  -- GME-05 will verify and award XP; host only acknowledges receipt.
  return jsonb_build_object(
    'session_id', v_row.id,
    'status', v_row.status,
    'verified', false,
    'message', 'Result received. Verification comes later.'
  );
end;
$fn$;

revoke all on function public.report_game_client_completed(uuid, text, jsonb)
  from public, anon;
grant execute on function public.report_game_client_completed(uuid, text, jsonb)
  to authenticated, service_role;

comment on function public.report_game_client_completed(uuid, text, jsonb) is
  'GME-02 store unverified client completion; no XP.';
