-- COM-03: join / leave, pending requests for private, invite codes.

create table if not exists public.community_invites (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references public.communities (id) on delete cascade,
  code text not null,
  created_by uuid not null references public.profiles (id) on delete cascade,
  expires_at timestamptz,
  max_uses int check (max_uses is null or max_uses > 0),
  use_count int not null default 0 check (use_count >= 0),
  revoked_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  constraint community_invites_code_unique unique (code)
);

comment on table public.community_invites is
  'COM-03 invite codes for joining communities (open or private).';

create index if not exists community_invites_community_idx
  on public.community_invites (community_id)
  where revoked_at is null;

alter table public.community_invites enable row level security;

create or replace function public.join_community(p_community_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_c public.communities%rowtype;
  v_existing public.community_memberships%rowtype;
begin
  perform nano_internal.assert_communities_allowed();

  if p_community_id is null then
    raise exception 'COMMUNITY_REQUIRED' using errcode = 'P0001';
  end if;

  select * into v_c from public.communities where id = p_community_id;
  if not found or v_c.status <> 'active' then
    raise exception 'COMMUNITY_NOT_FOUND' using errcode = 'P0001';
  end if;

  select * into v_existing
  from public.community_memberships
  where community_id = p_community_id and user_id = auth.uid();

  if found then
    if v_existing.status = 'active' then
      return public.get_community_detail(p_community_id);
    end if;
    if v_existing.status = 'banned' then
      raise exception 'COMMUNITY_BANNED' using errcode = 'P0001';
    end if;
    if v_existing.status = 'pending' then
      return public.get_community_detail(p_community_id);
    end if;
  end if;

  if v_c.visibility = 'public' then
    insert into public.community_memberships (
      community_id, user_id, role, status
    ) values (
      p_community_id, auth.uid(), 'member', 'active'
    )
    on conflict (community_id, user_id) do update
      set status = 'active',
          role = 'member',
          joined_at = timezone('utc', now());
  else
    insert into public.community_memberships (
      community_id, user_id, role, status
    ) values (
      p_community_id, auth.uid(), 'member', 'pending'
    )
    on conflict (community_id, user_id) do update
      set status = 'pending',
          role = 'member',
          joined_at = timezone('utc', now())
      where public.community_memberships.status is distinct from 'banned';
  end if;

  return public.get_community_detail(p_community_id);
end;
$$;

revoke all on function public.join_community(uuid) from public, anon;
grant execute on function public.join_community(uuid) to authenticated, service_role;

create or replace function public.leave_community(p_community_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_role text;
  v_owner_count int;
begin
  perform nano_internal.assert_communities_allowed();

  if p_community_id is null then
    raise exception 'COMMUNITY_REQUIRED' using errcode = 'P0001';
  end if;

  select m.role into v_role
  from public.community_memberships m
  where m.community_id = p_community_id
    and m.user_id = auth.uid()
    and m.status in ('active', 'pending');

  if not found then
    raise exception 'COMMUNITY_MEMBER_NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_role = 'owner' then
    select count(*)::int into v_owner_count
    from public.community_memberships m
    where m.community_id = p_community_id
      and m.status = 'active'
      and m.role = 'owner';
    if v_owner_count <= 1 then
      raise exception 'COMMUNITY_LAST_OWNER'
        using errcode = 'P0001',
              hint = 'Promote another owner before leaving.';
    end if;
  end if;

  update public.community_memberships
  set status = 'left'
  where community_id = p_community_id
    and user_id = auth.uid();

  return jsonb_build_object('left', true, 'community_id', p_community_id);
end;
$$;

revoke all on function public.leave_community(uuid) from public, anon;
grant execute on function public.leave_community(uuid) to authenticated, service_role;

create or replace function public.list_join_requests(p_community_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_role text;
begin
  perform nano_internal.assert_communities_allowed();

  v_role := nano_internal.caller_community_role(p_community_id);
  if v_role is null or v_role not in ('owner', 'admin') then
    raise exception 'COMMUNITY_ADMIN_REQUIRED' using errcode = 'P0001';
  end if;

  return coalesce((
    select jsonb_agg(
      jsonb_build_object(
        'user_id', m.user_id,
        'display_name', coalesce(nullif(trim(p.display_name), ''), 'Member'),
        'role', m.role,
        'status', m.status,
        'joined_at', m.joined_at,
        'is_self', m.user_id = auth.uid()
      )
      order by m.joined_at
    )
    from public.community_memberships m
    join public.profiles p on p.id = m.user_id
    where m.community_id = p_community_id
      and m.status = 'pending'
  ), '[]'::jsonb);
end;
$$;

revoke all on function public.list_join_requests(uuid) from public, anon;
grant execute on function public.list_join_requests(uuid) to authenticated, service_role;

create or replace function public.respond_join_request(
  p_community_id uuid,
  p_user_id uuid,
  p_accept boolean
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_role text;
begin
  perform nano_internal.assert_communities_allowed();

  v_role := nano_internal.caller_community_role(p_community_id);
  if v_role is null or v_role not in ('owner', 'admin') then
    raise exception 'COMMUNITY_ADMIN_REQUIRED' using errcode = 'P0001';
  end if;

  if not exists (
    select 1 from public.community_memberships m
    where m.community_id = p_community_id
      and m.user_id = p_user_id
      and m.status = 'pending'
  ) then
    raise exception 'COMMUNITY_REQUEST_NOT_FOUND' using errcode = 'P0001';
  end if;

  if coalesce(p_accept, false) then
    update public.community_memberships
    set status = 'active',
        role = 'member',
        joined_at = timezone('utc', now())
    where community_id = p_community_id
      and user_id = p_user_id
      and status = 'pending';
  else
    update public.community_memberships
    set status = 'left'
    where community_id = p_community_id
      and user_id = p_user_id
      and status = 'pending';
  end if;

  return public.list_join_requests(p_community_id);
end;
$$;

revoke all on function public.respond_join_request(uuid, uuid, boolean) from public, anon;
grant execute on function public.respond_join_request(uuid, uuid, boolean) to authenticated, service_role;

create or replace function public.create_community_invite(
  p_community_id uuid,
  p_max_uses int default null,
  p_expires_hours int default 168
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_role text;
  v_code text;
  v_row public.community_invites%rowtype;
  v_hours int := coalesce(p_expires_hours, 168);
begin
  perform nano_internal.assert_communities_allowed();

  v_role := nano_internal.caller_community_role(p_community_id);
  if v_role is null or v_role not in ('owner', 'admin') then
    raise exception 'COMMUNITY_ADMIN_REQUIRED' using errcode = 'P0001';
  end if;

  if v_hours < 1 or v_hours > 8760 then
    raise exception 'COMMUNITY_INVITE_TTL_INVALID' using errcode = 'P0001';
  end if;

  v_code := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10));

  insert into public.community_invites (
    community_id, code, created_by, expires_at, max_uses
  )
  values (
    p_community_id,
    v_code,
    auth.uid(),
    timezone('utc', now()) + make_interval(hours => v_hours),
    p_max_uses
  )
  returning * into v_row;

  return jsonb_build_object(
    'id', v_row.id,
    'community_id', v_row.community_id,
    'code', v_row.code,
    'expires_at', v_row.expires_at,
    'max_uses', v_row.max_uses,
    'use_count', v_row.use_count
  );
end;
$$;

revoke all on function public.create_community_invite(uuid, int, int) from public, anon;
grant execute on function public.create_community_invite(uuid, int, int) to authenticated, service_role;

create or replace function public.redeem_community_invite(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_code text := upper(trim(coalesce(p_code, '')));
  v_inv public.community_invites%rowtype;
  v_existing public.community_memberships%rowtype;
begin
  perform nano_internal.assert_communities_allowed();

  if v_code = '' then
    raise exception 'COMMUNITY_INVITE_REQUIRED' using errcode = 'P0001';
  end if;

  select * into v_inv
  from public.community_invites
  where code = v_code
    and revoked_at is null
  for update;

  if not found then
    raise exception 'COMMUNITY_INVITE_INVALID' using errcode = 'P0001';
  end if;

  if v_inv.expires_at is not null and v_inv.expires_at < timezone('utc', now()) then
    raise exception 'COMMUNITY_INVITE_EXPIRED' using errcode = 'P0001';
  end if;

  if v_inv.max_uses is not null and v_inv.use_count >= v_inv.max_uses then
    raise exception 'COMMUNITY_INVITE_EXHAUSTED' using errcode = 'P0001';
  end if;

  if not exists (
    select 1 from public.communities c
    where c.id = v_inv.community_id and c.status = 'active'
  ) then
    raise exception 'COMMUNITY_NOT_FOUND' using errcode = 'P0001';
  end if;

  select * into v_existing
  from public.community_memberships
  where community_id = v_inv.community_id and user_id = auth.uid();

  if found and v_existing.status = 'banned' then
    raise exception 'COMMUNITY_BANNED' using errcode = 'P0001';
  end if;

  if found and v_existing.status = 'active' then
    return public.get_community_detail(v_inv.community_id);
  end if;

  insert into public.community_memberships (
    community_id, user_id, role, status
  ) values (
    v_inv.community_id, auth.uid(), 'member', 'active'
  )
  on conflict (community_id, user_id) do update
    set status = 'active',
        role = 'member',
        joined_at = timezone('utc', now());

  update public.community_invites
  set use_count = use_count + 1
  where id = v_inv.id;

  return public.get_community_detail(v_inv.community_id);
end;
$$;

revoke all on function public.redeem_community_invite(text) from public, anon;
grant execute on function public.redeem_community_invite(text) to authenticated, service_role;
