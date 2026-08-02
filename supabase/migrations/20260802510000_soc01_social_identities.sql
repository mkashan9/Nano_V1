-- SOC-01: usernames, friend codes, limited public profiles.
-- Friend requests / blocks / ranking stay SOC-02+ / SAFE-01.

create table if not exists public.social_identities (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  username text,
  username_normalized text,
  friend_code text not null,
  friend_code_rotated_at timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint social_identities_username_format check (
    username is null
    or username ~ '^[a-z][a-z0-9_]{2,19}$'
  ),
  constraint social_identities_friend_code_format check (
    friend_code ~ '^[A-HJ-NP-Z2-9]{8}$'
  )
);

create unique index if not exists social_identities_username_normalized_uidx
  on public.social_identities (username_normalized)
  where username_normalized is not null;

create unique index if not exists social_identities_friend_code_uidx
  on public.social_identities (friend_code);

alter table public.social_identities enable row level security;

drop policy if exists social_identities_owner_select on public.social_identities;
create policy social_identities_owner_select
  on public.social_identities
  for select
  to authenticated
  using (user_id = auth.uid());

revoke all on table public.social_identities from public, anon;
grant select on table public.social_identities to authenticated, service_role;

create or replace function nano_internal.generate_friend_code()
returns text
language plpgsql
volatile
security definer
set search_path = pg_catalog, public, extensions
as $fn$
declare
  v_alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_code text;
  v_i integer;
  v_bytes bytea;
begin
  loop
    v_bytes := gen_random_bytes(8);
    v_code := '';
    for v_i in 0..7 loop
      v_code := v_code || substr(
        v_alphabet,
        (get_byte(v_bytes, v_i) % length(v_alphabet)) + 1,
        1
      );
    end loop;
    exit when not exists (
      select 1 from public.social_identities where friend_code = v_code
    );
  end loop;
  return v_code;
end;
$fn$;

create or replace function nano_internal.is_reserved_username(p_username text)
returns boolean
language sql
immutable
as $fn$
  select lower(p_username) in (
    'admin', 'administrator', 'nano', 'nori', 'support', 'system',
    'teacher', 'student', 'null', 'undefined', 'me', 'root', 'mod',
    'moderator', 'official'
  );
$fn$;

create or replace function nano_internal.ensure_social_identity(p_user_id uuid)
returns public.social_identities
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_row public.social_identities%rowtype;
begin
  select * into v_row from public.social_identities where user_id = p_user_id;
  if found then
    return v_row;
  end if;

  insert into public.social_identities (user_id, friend_code)
  values (p_user_id, nano_internal.generate_friend_code())
  on conflict (user_id) do nothing
  returning * into v_row;

  if not found then
    select * into v_row from public.social_identities where user_id = p_user_id;
  end if;
  return v_row;
end;
$fn$;

create or replace function nano_internal.limited_profile_json(p_user_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_username text;
  v_privacy public.privacy_settings%rowtype;
  v_prefs public.student_preferences%rowtype;
  v_level integer := 1;
  v_achievements jsonb := '[]'::jsonb;
  v_label text;
begin
  select * into v_privacy from public.privacy_settings where user_id = p_user_id;
  if not found then
    v_privacy.discoverable := true;
    v_privacy.show_achievements := true;
    v_privacy.allow_friend_requests := true;
  end if;

  if not coalesce(v_privacy.discoverable, true) then
    return null;
  end if;

  select si.username into v_username
  from public.social_identities si
  where si.user_id = p_user_id;

  v_label := coalesce(
    nullif(v_username, ''),
    nano_internal.league_privacy_label(p_user_id)
  );

  select * into v_prefs from public.student_preferences where user_id = p_user_id;

  select coalesce(xp.level, 1)
  into v_level
  from public.xp_progress xp
  where xp.user_id = p_user_id;
  if not found then
    v_level := 1;
  end if;

  if coalesce(v_privacy.show_achievements, true) then
    select coalesce(
      jsonb_agg(a.title_en order by a.awarded_at desc),
      '[]'::jsonb
    )
    into v_achievements
    from (
      select d.title_en, aw.awarded_at
      from public.achievement_awards aw
      join public.achievement_definitions d on d.id = aw.achievement_id
      where aw.user_id = p_user_id
      order by aw.awarded_at desc
      limit 5
    ) a;
  end if;

  return jsonb_build_object(
    'social_label', v_label,
    'username', v_username,
    'level', v_level,
    'companion_name', coalesce(v_prefs.companion_name, 'Nori'),
    'accepts_friend_requests', coalesce(v_privacy.allow_friend_requests, true),
    'achievements', v_achievements
  );
end;
$fn$;

-- Prefer claimed username on social surfaces (boards / challenges).
create or replace function nano_internal.league_privacy_label(p_user_id uuid)
returns text
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_name text;
  v_username text;
  v_discoverable boolean := true;
  v_first text;
begin
  select ps.discoverable into v_discoverable
  from public.privacy_settings ps
  where ps.user_id = p_user_id;
  if not found then
    v_discoverable := true;
  end if;

  if not v_discoverable then
    return 'Learner';
  end if;

  select si.username into v_username
  from public.social_identities si
  where si.user_id = p_user_id;
  if v_username is not null and v_username <> '' then
    return v_username;
  end if;

  select p.display_name into v_name
  from public.profiles p
  where p.id = p_user_id;

  v_name := btrim(coalesce(v_name, ''));
  if v_name = '' then
    return 'Learner';
  end if;

  v_first := split_part(v_name, ' ', 1);
  if v_first = '' then
    return 'Learner';
  end if;
  return v_first;
end;
$fn$;

create or replace function public.my_social_identity()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_uid uuid := auth.uid();
  v_row public.social_identities%rowtype;
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  v_row := nano_internal.ensure_social_identity(v_uid);
  return jsonb_build_object(
    'username', v_row.username,
    'friend_code', v_row.friend_code,
    'friend_code_rotated_at', v_row.friend_code_rotated_at
  );
end;
$fn$;

create or replace function public.claim_username(p_username text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_uid uuid := auth.uid();
  v_clean text;
  v_row public.social_identities%rowtype;
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  v_clean := lower(btrim(coalesce(p_username, '')));
  if v_clean !~ '^[a-z][a-z0-9_]{2,19}$' then
    raise exception using errcode = 'NS020',
      message = 'Username must be 3–20 chars: start with a letter, then letters, numbers, or _.';
  end if;

  if nano_internal.is_reserved_username(v_clean) then
    raise exception using errcode = 'NS021', message = 'That username is reserved.';
  end if;

  if exists (
    select 1
    from public.social_identities
    where username_normalized = v_clean
      and user_id <> v_uid
  ) then
    raise exception using errcode = 'NS022', message = 'Username is already taken.';
  end if;

  v_row := nano_internal.ensure_social_identity(v_uid);

  update public.social_identities
  set username = v_clean,
      username_normalized = v_clean,
      updated_at = timezone('utc', now())
  where user_id = v_uid
  returning * into v_row;

  return jsonb_build_object(
    'username', v_row.username,
    'friend_code', v_row.friend_code,
    'friend_code_rotated_at', v_row.friend_code_rotated_at
  );
end;
$fn$;

create or replace function public.rotate_friend_code()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_uid uuid := auth.uid();
  v_row public.social_identities%rowtype;
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  v_row := nano_internal.ensure_social_identity(v_uid);

  update public.social_identities
  set friend_code = nano_internal.generate_friend_code(),
      friend_code_rotated_at = timezone('utc', now()),
      updated_at = timezone('utc', now())
  where user_id = v_uid
  returning * into v_row;

  return jsonb_build_object(
    'username', v_row.username,
    'friend_code', v_row.friend_code,
    'friend_code_rotated_at', v_row.friend_code_rotated_at
  );
end;
$fn$;

create or replace function public.lookup_limited_profile(p_query text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_uid uuid := auth.uid();
  v_q text := btrim(coalesce(p_query, ''));
  v_target uuid;
  v_proj jsonb;
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  if v_q = '' then
    raise exception using errcode = 'NS023', message = 'Enter a username or friend code.';
  end if;

  if upper(v_q) ~ '^[A-HJ-NP-Z2-9]{8}$' then
    select si.user_id into v_target
    from public.social_identities si
    where si.friend_code = upper(v_q);
  else
    select si.user_id into v_target
    from public.social_identities si
    where si.username_normalized = lower(v_q);
  end if;

  if v_target is null or v_target = v_uid then
    raise exception using errcode = 'NS024', message = 'No discoverable profile found.';
  end if;

  v_proj := nano_internal.limited_profile_json(v_target);
  if v_proj is null then
    raise exception using errcode = 'NS024', message = 'No discoverable profile found.';
  end if;

  return v_proj;
end;
$fn$;

revoke all on function public.my_social_identity() from public, anon;
revoke all on function public.claim_username(text) from public, anon;
revoke all on function public.rotate_friend_code() from public, anon;
revoke all on function public.lookup_limited_profile(text) from public, anon;

grant execute on function public.my_social_identity()
  to authenticated, service_role;
grant execute on function public.claim_username(text)
  to authenticated, service_role;
grant execute on function public.rotate_friend_code()
  to authenticated, service_role;
grant execute on function public.lookup_limited_profile(text)
  to authenticated, service_role;

comment on table public.social_identities is
  'SOC-01 learner username + rotatable friend code. No peer user_id in client RPCs.';
