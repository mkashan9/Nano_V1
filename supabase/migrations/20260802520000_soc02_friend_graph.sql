-- SOC-02: friend requests, friendships, blocks.
-- Reports stay SAFE-01. Leaderboards stay SOC-03.

create table if not exists public.friend_requests (
  id uuid primary key default gen_random_uuid(),
  from_user_id uuid not null references public.profiles (id) on delete cascade,
  to_user_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined', 'cancelled')),
  created_at timestamptz not null default timezone('utc', now()),
  responded_at timestamptz,
  constraint friend_requests_not_self check (from_user_id <> to_user_id)
);

create unique index if not exists friend_requests_pending_pair_uidx
  on public.friend_requests (from_user_id, to_user_id)
  where status = 'pending';

create index if not exists friend_requests_to_pending_idx
  on public.friend_requests (to_user_id, created_at desc)
  where status = 'pending';

create index if not exists friend_requests_from_pending_idx
  on public.friend_requests (from_user_id, created_at desc)
  where status = 'pending';

create table if not exists public.friendships (
  user_low uuid not null references public.profiles (id) on delete cascade,
  user_high uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (user_low, user_high),
  constraint friendships_ordered check (user_low < user_high)
);

create table if not exists public.blocks (
  blocker_id uuid not null references public.profiles (id) on delete cascade,
  blocked_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (blocker_id, blocked_id),
  constraint blocks_not_self check (blocker_id <> blocked_id)
);

create index if not exists blocks_blocked_idx on public.blocks (blocked_id);

create table if not exists public.friend_peer_tokens (
  token text primary key,
  owner_id uuid not null references public.profiles (id) on delete cascade,
  peer_id uuid not null references public.profiles (id) on delete cascade,
  purpose text not null check (purpose in ('friend', 'block')),
  expires_at timestamptz not null
);

create index if not exists friend_peer_tokens_owner_idx
  on public.friend_peer_tokens (owner_id, expires_at);

alter table public.friend_requests enable row level security;
alter table public.friendships enable row level security;
alter table public.blocks enable row level security;
alter table public.friend_peer_tokens enable row level security;

-- Clients use security-definer RPCs only.
revoke all on table public.friend_requests from public, anon, authenticated;
revoke all on table public.friendships from public, anon, authenticated;
revoke all on table public.blocks from public, anon, authenticated;
revoke all on table public.friend_peer_tokens from public, anon, authenticated;
grant all on table public.friend_requests to service_role;
grant all on table public.friendships to service_role;
grant all on table public.blocks to service_role;
grant all on table public.friend_peer_tokens to service_role;

create or replace function nano_internal.are_blocked(p_a uuid, p_b uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $fn$
  select exists (
    select 1 from public.blocks
    where (blocker_id = p_a and blocked_id = p_b)
       or (blocker_id = p_b and blocked_id = p_a)
  );
$fn$;

create or replace function nano_internal.are_friends(p_a uuid, p_b uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $fn$
  select exists (
    select 1 from public.friendships
    where user_low = least(p_a, p_b)
      and user_high = greatest(p_a, p_b)
  );
$fn$;

create or replace function nano_internal.resolve_social_target(p_query text)
returns uuid
language plpgsql
stable
security definer
set search_path = pg_catalog, public
as $fn$
declare
  v_q text := btrim(coalesce(p_query, ''));
  v_target uuid;
begin
  if v_q = '' then
    return null;
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
  return v_target;
end;
$fn$;

create or replace function nano_internal.issue_friend_peer_token(
  p_owner uuid,
  p_peer uuid,
  p_purpose text
)
returns text
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal, extensions
as $fn$
declare
  v_token text;
begin
  delete from public.friend_peer_tokens
  where owner_id = p_owner
    and peer_id = p_peer
    and purpose = p_purpose;

  v_token := encode(gen_random_bytes(18), 'hex');
  insert into public.friend_peer_tokens (token, owner_id, peer_id, purpose, expires_at)
  values (
    v_token, p_owner, p_peer, p_purpose,
    timezone('utc', now()) + interval '2 hours'
  );
  return v_token;
end;
$fn$;

create or replace function nano_internal.consume_friend_peer_token(
  p_owner uuid,
  p_token text,
  p_purpose text
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $fn$
declare
  v_peer uuid;
begin
  delete from public.friend_peer_tokens
  where expires_at <= timezone('utc', now());

  select peer_id into v_peer
  from public.friend_peer_tokens
  where token = p_token
    and owner_id = p_owner
    and purpose = p_purpose
    and expires_at > timezone('utc', now())
  for update;

  if not found then
    return null;
  end if;

  delete from public.friend_peer_tokens where token = p_token;
  return v_peer;
end;
$fn$;

create or replace function nano_internal.social_label_for(p_user_id uuid)
returns text
language sql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
  select nano_internal.league_privacy_label(p_user_id);
$fn$;

create or replace function nano_internal.friend_request_projection(
  p_row public.friend_requests,
  p_viewer uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_peer uuid;
  v_username text;
begin
  v_peer := case
    when p_row.from_user_id = p_viewer then p_row.to_user_id
    else p_row.from_user_id
  end;
  select si.username into v_username
  from public.social_identities si
  where si.user_id = v_peer;

  return jsonb_build_object(
    'id', p_row.id,
    'status', p_row.status,
    'direction', case
      when p_row.from_user_id = p_viewer then 'outgoing'
      else 'incoming'
    end,
    'peer_label', nano_internal.social_label_for(v_peer),
    'username', v_username,
    'created_at', p_row.created_at
  );
end;
$fn$;

-- Blocked pairs share the same "not found" surface as unknown lookups.
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

  v_target := nano_internal.resolve_social_target(v_q);

  if v_target is null
     or v_target = v_uid
     or nano_internal.are_blocked(v_uid, v_target) then
    raise exception using errcode = 'NS024', message = 'No discoverable profile found.';
  end if;

  v_proj := nano_internal.limited_profile_json(v_target);
  if v_proj is null then
    raise exception using errcode = 'NS024', message = 'No discoverable profile found.';
  end if;

  return v_proj || jsonb_build_object(
    'already_friends', nano_internal.are_friends(v_uid, v_target),
    'pending_outgoing', exists (
      select 1 from public.friend_requests
      where from_user_id = v_uid and to_user_id = v_target and status = 'pending'
    ),
    'pending_incoming', exists (
      select 1 from public.friend_requests
      where from_user_id = v_target and to_user_id = v_uid and status = 'pending'
    )
  );
end;
$fn$;

create or replace function public.send_friend_request(p_query text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_uid uuid := auth.uid();
  v_target uuid;
  v_privacy public.privacy_settings%rowtype;
  v_row public.friend_requests%rowtype;
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  v_target := nano_internal.resolve_social_target(p_query);
  if v_target is null or v_target = v_uid then
    raise exception using errcode = 'NS024', message = 'No discoverable profile found.';
  end if;

  if nano_internal.are_blocked(v_uid, v_target) then
    raise exception using errcode = 'NS024', message = 'No discoverable profile found.';
  end if;

  if nano_internal.are_friends(v_uid, v_target) then
    raise exception using errcode = 'NS030', message = 'Already friends.';
  end if;

  select * into v_privacy from public.privacy_settings where user_id = v_target;
  if found and (
       not coalesce(v_privacy.discoverable, true)
    or not coalesce(v_privacy.allow_friend_requests, true)
  ) then
    raise exception using errcode = 'NS031', message = 'This learner is not accepting requests.';
  end if;

  if exists (
    select 1 from public.friend_requests
    where from_user_id = v_target and to_user_id = v_uid and status = 'pending'
  ) then
    raise exception using errcode = 'NS032',
      message = 'They already sent you a request — open Friends to respond.';
  end if;

  if exists (
    select 1 from public.friend_requests
    where from_user_id = v_uid and to_user_id = v_target and status = 'pending'
  ) then
    select * into v_row
    from public.friend_requests
    where from_user_id = v_uid and to_user_id = v_target and status = 'pending';
    return nano_internal.friend_request_projection(v_row, v_uid);
  end if;

  insert into public.friend_requests (from_user_id, to_user_id, status)
  values (v_uid, v_target, 'pending')
  returning * into v_row;

  return nano_internal.friend_request_projection(v_row, v_uid);
end;
$fn$;

create or replace function public.respond_friend_request(
  p_request_id uuid,
  p_accept boolean
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_uid uuid := auth.uid();
  v_row public.friend_requests%rowtype;
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  select * into v_row
  from public.friend_requests
  where id = p_request_id
  for update;

  if not found then
    raise exception using errcode = 'NS033', message = 'Friend request not found.';
  end if;

  if v_row.to_user_id <> v_uid then
    raise exception using errcode = 'NS034', message = 'Only the recipient can respond.';
  end if;

  if v_row.status <> 'pending' then
    return nano_internal.friend_request_projection(v_row, v_uid);
  end if;

  if nano_internal.are_blocked(v_uid, v_row.from_user_id) then
    update public.friend_requests
    set status = 'cancelled', responded_at = timezone('utc', now())
    where id = v_row.id
    returning * into v_row;
    return nano_internal.friend_request_projection(v_row, v_uid);
  end if;

  if p_accept then
    update public.friend_requests
    set status = 'accepted', responded_at = timezone('utc', now())
    where id = v_row.id
    returning * into v_row;

    insert into public.friendships (user_low, user_high)
    values (least(v_row.from_user_id, v_row.to_user_id),
            greatest(v_row.from_user_id, v_row.to_user_id))
    on conflict do nothing;

    update public.friend_requests
    set status = 'cancelled', responded_at = timezone('utc', now())
    where status = 'pending'
      and (
        (from_user_id = v_row.from_user_id and to_user_id = v_row.to_user_id)
        or (from_user_id = v_row.to_user_id and to_user_id = v_row.from_user_id)
      )
      and id <> v_row.id;
  else
    update public.friend_requests
    set status = 'declined', responded_at = timezone('utc', now())
    where id = v_row.id
    returning * into v_row;
  end if;

  return nano_internal.friend_request_projection(v_row, v_uid);
end;
$fn$;

create or replace function public.cancel_friend_request(p_request_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_uid uuid := auth.uid();
  v_row public.friend_requests%rowtype;
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  select * into v_row
  from public.friend_requests
  where id = p_request_id
  for update;

  if not found then
    raise exception using errcode = 'NS033', message = 'Friend request not found.';
  end if;

  if v_row.from_user_id <> v_uid then
    raise exception using errcode = 'NS035', message = 'Only the sender can cancel.';
  end if;

  if v_row.status = 'pending' then
    update public.friend_requests
    set status = 'cancelled', responded_at = timezone('utc', now())
    where id = v_row.id
    returning * into v_row;
  end if;

  return nano_internal.friend_request_projection(v_row, v_uid);
end;
$fn$;

create or replace function public.my_friend_requests()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_uid uuid := auth.uid();
  v_items jsonb := '[]'::jsonb;
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  select coalesce(jsonb_agg(p.proj order by p.created_at desc), '[]'::jsonb)
  into v_items
  from (
    select r.created_at, nano_internal.friend_request_projection(r, v_uid) as proj
    from public.friend_requests r
    where r.status = 'pending'
      and (r.from_user_id = v_uid or r.to_user_id = v_uid)
  ) p;

  return jsonb_build_object('requests', v_items);
end;
$fn$;

create or replace function public.my_friends()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_uid uuid := auth.uid();
  v_items jsonb := '[]'::jsonb;
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  delete from public.friend_peer_tokens
  where owner_id = v_uid and expires_at <= timezone('utc', now());

  select coalesce(jsonb_agg(x.obj order by x.created_at desc), '[]'::jsonb)
  into v_items
  from (
    select
      f.created_at,
      jsonb_build_object(
        'peer_token', nano_internal.issue_friend_peer_token(
          v_uid,
          case when f.user_low = v_uid then f.user_high else f.user_low end,
          'friend'
        ),
        'peer_label', nano_internal.social_label_for(
          case when f.user_low = v_uid then f.user_high else f.user_low end
        ),
        'username', (
          select si.username from public.social_identities si
          where si.user_id = case
            when f.user_low = v_uid then f.user_high else f.user_low
          end
        ),
        'since', f.created_at
      ) as obj
    from public.friendships f
    where f.user_low = v_uid or f.user_high = v_uid
  ) x;

  return jsonb_build_object('friends', v_items);
end;
$fn$;

create or replace function public.remove_friend(p_peer_token text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_uid uuid := auth.uid();
  v_peer uuid;
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  v_peer := nano_internal.consume_friend_peer_token(v_uid, p_peer_token, 'friend');
  if v_peer is null then
    raise exception using errcode = 'NS036', message = 'Friend action expired. Refresh the list.';
  end if;

  delete from public.friendships
  where user_low = least(v_uid, v_peer)
    and user_high = greatest(v_uid, v_peer);

  return jsonb_build_object('removed', true);
end;
$fn$;

create or replace function public.block_user(p_query text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_uid uuid := auth.uid();
  v_target uuid;
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  v_target := nano_internal.resolve_social_target(p_query);
  if v_target is null or v_target = v_uid then
    raise exception using errcode = 'NS024', message = 'No discoverable profile found.';
  end if;

  insert into public.blocks (blocker_id, blocked_id)
  values (v_uid, v_target)
  on conflict do nothing;

  delete from public.friendships
  where user_low = least(v_uid, v_target)
    and user_high = greatest(v_uid, v_target);

  update public.friend_requests
  set status = 'cancelled', responded_at = timezone('utc', now())
  where status = 'pending'
    and (
      (from_user_id = v_uid and to_user_id = v_target)
      or (from_user_id = v_target and to_user_id = v_uid)
    );

  return jsonb_build_object(
    'blocked', true,
    'peer_label', nano_internal.social_label_for(v_target)
  );
end;
$fn$;

create or replace function public.my_blocks()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_uid uuid := auth.uid();
  v_items jsonb := '[]'::jsonb;
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  select coalesce(jsonb_agg(x.obj order by x.created_at desc), '[]'::jsonb)
  into v_items
  from (
    select
      b.created_at,
      jsonb_build_object(
        'peer_token', nano_internal.issue_friend_peer_token(
          v_uid, b.blocked_id, 'block'
        ),
        'peer_label', nano_internal.social_label_for(b.blocked_id),
        'username', (
          select si.username from public.social_identities si
          where si.user_id = b.blocked_id
        ),
        'since', b.created_at
      ) as obj
    from public.blocks b
    where b.blocker_id = v_uid
  ) x;

  return jsonb_build_object('blocks', v_items);
end;
$fn$;

create or replace function public.unblock_user(p_peer_token text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_uid uuid := auth.uid();
  v_peer uuid;
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  v_peer := nano_internal.consume_friend_peer_token(v_uid, p_peer_token, 'block');
  if v_peer is null then
    raise exception using errcode = 'NS036', message = 'Block action expired. Refresh the list.';
  end if;

  delete from public.blocks
  where blocker_id = v_uid and blocked_id = v_peer;

  return jsonb_build_object('unblocked', true);
end;
$fn$;

revoke all on function public.send_friend_request(text) from public, anon;
revoke all on function public.respond_friend_request(uuid, boolean) from public, anon;
revoke all on function public.cancel_friend_request(uuid) from public, anon;
revoke all on function public.my_friend_requests() from public, anon;
revoke all on function public.my_friends() from public, anon;
revoke all on function public.remove_friend(text) from public, anon;
revoke all on function public.block_user(text) from public, anon;
revoke all on function public.my_blocks() from public, anon;
revoke all on function public.unblock_user(text) from public, anon;

grant execute on function public.send_friend_request(text)
  to authenticated, service_role;
grant execute on function public.respond_friend_request(uuid, boolean)
  to authenticated, service_role;
grant execute on function public.cancel_friend_request(uuid)
  to authenticated, service_role;
grant execute on function public.my_friend_requests()
  to authenticated, service_role;
grant execute on function public.my_friends()
  to authenticated, service_role;
grant execute on function public.remove_friend(text)
  to authenticated, service_role;
grant execute on function public.block_user(text)
  to authenticated, service_role;
grant execute on function public.my_blocks()
  to authenticated, service_role;
grant execute on function public.unblock_user(text)
  to authenticated, service_role;
grant execute on function public.lookup_limited_profile(text)
  to authenticated, service_role;

comment on table public.friend_requests is
  'SOC-02 pending/settled friend requests. Client never sees peer user ids.';
comment on table public.friendships is
  'SOC-02 accepted friendships with ordered user pair keys.';
comment on table public.blocks is
  'SOC-02 one-way blocks. Mutual discovery/request blocked either direction.';
