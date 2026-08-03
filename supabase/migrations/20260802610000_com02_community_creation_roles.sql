-- COM-02: create open communities; creator becomes owner; role management.

create or replace function nano_internal.slugify_community_name(p_name text)
returns text
language sql
immutable
as $$
  select trim(both '-' from regexp_replace(lower(trim(coalesce(p_name, ''))), '[^a-z0-9]+', '-', 'g'));
$$;

revoke all on function nano_internal.slugify_community_name(text) from public, anon;
grant execute on function nano_internal.slugify_community_name(text) to authenticated, service_role;

create or replace function nano_internal.caller_community_role(p_community_id uuid)
returns text
language sql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
  select m.role
  from public.community_memberships m
  where m.community_id = p_community_id
    and m.user_id = auth.uid()
    and m.status = 'active'
  limit 1;
$$;

revoke all on function nano_internal.caller_community_role(uuid) from public, anon;
grant execute on function nano_internal.caller_community_role(uuid) to authenticated, service_role;

create or replace function public.create_community(
  p_name text,
  p_summary text default '',
  p_rules_text text default '',
  p_visibility text default 'public'
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_name text := trim(coalesce(p_name, ''));
  v_summary text := trim(coalesce(p_summary, ''));
  v_rules text := trim(coalesce(p_rules_text, ''));
  v_visibility text := lower(trim(coalesce(p_visibility, 'public')));
  v_slug_base text;
  v_slug text;
  v_id uuid;
  v_attempt int := 0;
begin
  perform nano_internal.assert_communities_allowed();

  if v_name = '' or char_length(v_name) < 3 then
    raise exception 'COMMUNITY_NAME_REQUIRED'
      using errcode = 'P0001', hint = 'Name must be at least 3 characters.';
  end if;
  if char_length(v_name) > 80 then
    raise exception 'COMMUNITY_NAME_TOO_LONG' using errcode = 'P0001';
  end if;

  if v_visibility not in ('public', 'private') then
    raise exception 'COMMUNITY_VISIBILITY_INVALID' using errcode = 'P0001';
  end if;

  perform nano_internal.assert_text_allowed(v_name);
  perform nano_internal.assert_text_allowed(v_summary);
  perform nano_internal.assert_text_allowed(v_rules);

  v_slug_base := nano_internal.slugify_community_name(v_name);
  if v_slug_base is null or v_slug_base = '' then
    v_slug_base := 'community';
  end if;

  loop
    v_attempt := v_attempt + 1;
    if v_attempt = 1 then
      v_slug := v_slug_base;
    else
      v_slug := v_slug_base || '-' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 8);
    end if;

    begin
      insert into public.communities as c (
        slug, name, summary, rules_text, visibility, created_by, updated_at
      )
      values (
        v_slug, v_name, v_summary, v_rules, v_visibility, auth.uid(), timezone('utc', now())
      )
      returning c.id into v_id;
      exit;
    exception
      when unique_violation then
        if v_attempt >= 8 then
          raise;
        end if;
    end;
  end loop;

  insert into public.community_memberships (
    community_id, user_id, role, status
  )
  values (
    v_id, auth.uid(), 'owner', 'active'
  );

  return public.get_community_detail(v_id);
end;
$$;

revoke all on function public.create_community(text, text, text, text) from public, anon;
grant execute on function public.create_community(text, text, text, text) to authenticated, service_role;

create or replace function public.list_community_members(p_community_id uuid)
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

  if p_community_id is null then
    raise exception 'COMMUNITY_REQUIRED' using errcode = 'P0001';
  end if;

  v_role := nano_internal.caller_community_role(p_community_id);
  if v_role is null then
    raise exception 'COMMUNITY_MEMBER_REQUIRED' using errcode = 'P0001';
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
      order by
        case m.role
          when 'owner' then 0
          when 'admin' then 1
          when 'moderator' then 2
          else 3
        end,
        p.display_name
    )
    from public.community_memberships m
    join public.profiles p on p.id = m.user_id
    where m.community_id = p_community_id
      and m.status = 'active'
  ), '[]'::jsonb);
end;
$$;

revoke all on function public.list_community_members(uuid) from public, anon;
grant execute on function public.list_community_members(uuid) to authenticated, service_role;

create or replace function public.set_community_member_role(
  p_community_id uuid,
  p_user_id uuid,
  p_role text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_caller_role text;
  v_target_role text;
  v_new_role text := lower(trim(coalesce(p_role, '')));
  v_owner_count int;
begin
  perform nano_internal.assert_communities_allowed();

  if p_community_id is null or p_user_id is null then
    raise exception 'COMMUNITY_REQUIRED' using errcode = 'P0001';
  end if;

  if v_new_role not in ('owner', 'admin', 'moderator', 'member') then
    raise exception 'COMMUNITY_ROLE_INVALID' using errcode = 'P0001';
  end if;

  v_caller_role := nano_internal.caller_community_role(p_community_id);
  if v_caller_role is null or v_caller_role not in ('owner', 'admin') then
    raise exception 'COMMUNITY_ADMIN_REQUIRED' using errcode = 'P0001';
  end if;

  -- Admins may only set moderator/member; owners may set any role.
  if v_caller_role = 'admin' and v_new_role in ('owner', 'admin') then
    raise exception 'COMMUNITY_ROLE_FORBIDDEN' using errcode = 'P0001';
  end if;

  select m.role into v_target_role
  from public.community_memberships m
  where m.community_id = p_community_id
    and m.user_id = p_user_id
    and m.status = 'active';

  if not found then
    raise exception 'COMMUNITY_MEMBER_NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_caller_role = 'admin' and v_target_role in ('owner', 'admin') then
    raise exception 'COMMUNITY_ROLE_FORBIDDEN' using errcode = 'P0001';
  end if;

  if v_target_role = 'owner' and v_new_role <> 'owner' then
    select count(*)::int into v_owner_count
    from public.community_memberships m
    where m.community_id = p_community_id
      and m.status = 'active'
      and m.role = 'owner';
    if v_owner_count <= 1 then
      raise exception 'COMMUNITY_LAST_OWNER'
        using errcode = 'P0001',
              hint = 'Promote another owner before demoting the last owner.';
    end if;
  end if;

  update public.community_memberships
  set role = v_new_role
  where community_id = p_community_id
    and user_id = p_user_id
    and status = 'active';

  return public.list_community_members(p_community_id);
end;
$$;

revoke all on function public.set_community_member_role(uuid, uuid, text) from public, anon;
grant execute on function public.set_community_member_role(uuid, uuid, text) to authenticated, service_role;
