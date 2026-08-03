-- COM-06: pins, search, gallery, member archive/mute, admin-only posting.

alter table public.communities
  add column if not exists posting_mode text not null default 'open'
    check (posting_mode in ('open', 'admins_only'));

comment on column public.communities.posting_mode is
  'COM-06: open = any active member; admins_only = owner/admin/moderator.';

alter table public.community_messages
  add column if not exists pinned_at timestamptz,
  add column if not exists pinned_by uuid references public.profiles (id) on delete set null;

create index if not exists community_messages_pinned_idx
  on public.community_messages (community_id, pinned_at desc)
  where pinned_at is not null;

create table if not exists public.community_member_prefs (
  community_id uuid not null references public.communities (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  muted boolean not null default false,
  archived_at timestamptz,
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (community_id, user_id)
);

comment on table public.community_member_prefs is
  'COM-06 per-member mute and archive preferences.';

alter table public.community_member_prefs enable row level security;

create or replace function nano_internal.community_message_json(p_message_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_msg public.community_messages%rowtype;
  v_author_name text;
  v_mentions jsonb;
  v_reactions jsonb;
  v_attachments jsonb;
begin
  select * into v_msg from public.community_messages where id = p_message_id;
  if not found then
    return null;
  end if;

  select coalesce(nullif(trim(p.display_name), ''), 'Member')
  into v_author_name
  from public.profiles p
  where p.id = v_msg.author_id;

  select coalesce(jsonb_agg(m.mentioned_user_id order by m.mentioned_user_id), '[]'::jsonb)
  into v_mentions
  from public.community_message_mentions m
  where m.message_id = p_message_id;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'emoji', r.emoji,
        'count', r.cnt,
        'reacted_by_me', r.mine
      )
      order by r.emoji
    ),
    '[]'::jsonb
  )
  into v_reactions
  from (
    select
      mr.emoji,
      count(*)::int as cnt,
      bool_or(mr.user_id = auth.uid()) as mine
    from public.message_reactions mr
    where mr.message_id = p_message_id
    group by mr.emoji
  ) r;

  select coalesce(
    jsonb_agg(nano_internal.community_attachment_json(a.id) order by a.created_at),
    '[]'::jsonb
  )
  into v_attachments
  from public.community_message_attachments a
  where a.message_id = p_message_id
    and a.status = 'ready';

  return jsonb_build_object(
    'id', v_msg.id,
    'community_id', v_msg.community_id,
    'author_id', v_msg.author_id,
    'author_display_name', coalesce(v_author_name, 'Member'),
    'body', v_msg.body,
    'parent_message_id', v_msg.parent_message_id,
    'created_at', v_msg.created_at,
    'is_self', v_msg.author_id = auth.uid(),
    'mention_user_ids', v_mentions,
    'reactions', v_reactions,
    'attachments', v_attachments,
    'is_pinned', v_msg.pinned_at is not null,
    'pinned_at', v_msg.pinned_at,
    'pinned_by', v_msg.pinned_by
  );
end;
$$;

create or replace function public.my_communities()
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
begin
  perform nano_internal.assert_communities_allowed();

  return coalesce((
    select jsonb_agg(
      jsonb_build_object(
        'id', c.id,
        'slug', c.slug,
        'name', c.name,
        'summary', c.summary,
        'visibility', c.visibility,
        'status', c.status,
        'posting_mode', c.posting_mode,
        'member_count', (
          select count(*)::int
          from public.community_memberships m2
          where m2.community_id = c.id
            and m2.status = 'active'
        ),
        'my_role', m.role,
        'my_status', m.status,
        'joined_at', m.joined_at,
        'is_muted', coalesce(pref.muted, false),
        'is_archived', pref.archived_at is not null
      )
      order by c.name
    )
    from public.community_memberships m
    join public.communities c on c.id = m.community_id
    left join public.community_member_prefs pref
      on pref.community_id = c.id and pref.user_id = auth.uid()
    where m.user_id = auth.uid()
      and m.status = 'active'
      and c.status = 'active'
      and pref.archived_at is null
  ), '[]'::jsonb);
end;
$$;

create or replace function public.get_community_detail(p_community_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_c public.communities%rowtype;
  v_role text;
  v_status text;
  v_joined timestamptz;
  v_count int := 0;
  v_muted boolean := false;
  v_archived boolean := false;
begin
  perform nano_internal.assert_communities_allowed();

  if p_community_id is null then
    raise exception 'COMMUNITY_REQUIRED' using errcode = 'P0001';
  end if;

  select * into v_c from public.communities where id = p_community_id;
  if not found or v_c.status <> 'active' then
    raise exception 'COMMUNITY_NOT_FOUND' using errcode = 'P0001';
  end if;

  select m.role, m.status, m.joined_at
    into v_role, v_status, v_joined
  from public.community_memberships m
  where m.community_id = p_community_id
    and m.user_id = auth.uid();

  if v_c.visibility = 'private'
     and coalesce(v_status, '') not in ('active', 'pending') then
    raise exception 'COMMUNITY_NOT_FOUND' using errcode = 'P0001';
  end if;

  select count(*)::int into v_count
  from public.community_memberships m2
  where m2.community_id = p_community_id
    and m2.status = 'active';

  select coalesce(pref.muted, false), pref.archived_at is not null
    into v_muted, v_archived
  from public.community_member_prefs pref
  where pref.community_id = p_community_id
    and pref.user_id = auth.uid();

  return jsonb_build_object(
    'id', v_c.id,
    'slug', v_c.slug,
    'name', v_c.name,
    'summary', v_c.summary,
    'rules_text', v_c.rules_text,
    'visibility', v_c.visibility,
    'status', v_c.status,
    'posting_mode', v_c.posting_mode,
    'member_count', v_count,
    'my_role', v_role,
    'my_status', v_status,
    'joined_at', v_joined,
    'created_at', v_c.created_at,
    'is_muted', coalesce(v_muted, false),
    'is_archived', coalesce(v_archived, false)
  );
end;
$$;

create or replace function public.send_community_message(
  p_community_id uuid,
  p_body text,
  p_parent_message_id uuid default null,
  p_mention_ids uuid[] default null,
  p_attachment_ids uuid[] default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_role text;
  v_body text := trim(coalesce(p_body, ''));
  v_id uuid;
  v_mention uuid;
  v_parent public.community_messages%rowtype;
  v_attach_count int := 0;
  v_mode text;
begin
  perform nano_internal.assert_communities_allowed();

  v_role := nano_internal.caller_community_role(p_community_id);
  if v_role is null then
    raise exception 'COMMUNITY_MEMBER_REQUIRED' using errcode = 'P0001';
  end if;

  select posting_mode into v_mode from public.communities where id = p_community_id;
  if v_mode = 'admins_only' and v_role not in ('owner', 'admin', 'moderator') then
    raise exception 'COMMUNITY_POSTING_RESTRICTED' using errcode = 'P0001';
  end if;

  if p_attachment_ids is not null then
    select count(*)::int into v_attach_count
    from public.community_message_attachments a
    where a.id = any (p_attachment_ids)
      and a.community_id = p_community_id
      and a.author_id = auth.uid()
      and a.message_id is null
      and a.status = 'pending';
    if v_attach_count <> coalesce(array_length(p_attachment_ids, 1), 0) then
      raise exception 'COMMUNITY_ATTACHMENT_INVALID' using errcode = 'P0001';
    end if;
  end if;

  if v_body = '' and v_attach_count = 0 then
    raise exception 'COMMUNITY_MESSAGE_REQUIRED' using errcode = 'P0001';
  end if;

  if v_body <> '' then
    perform nano_internal.assert_community_message_allowed(auth.uid(), v_body);
  else
    perform nano_internal.assert_rate_limit(auth.uid(), 'community_message');
  end if;

  if p_parent_message_id is not null then
    select * into v_parent
    from public.community_messages
    where id = p_parent_message_id;
    if not found or v_parent.community_id <> p_community_id then
      raise exception 'COMMUNITY_PARENT_INVALID' using errcode = 'P0001';
    end if;
  end if;

  insert into public.community_messages (
    community_id, author_id, body, parent_message_id
  ) values (
    p_community_id, auth.uid(), v_body, p_parent_message_id
  )
  returning id into v_id;

  if p_mention_ids is not null then
    foreach v_mention in array p_mention_ids loop
      if exists (
        select 1
        from public.community_memberships m
        where m.community_id = p_community_id
          and m.user_id = v_mention
          and m.status = 'active'
      ) then
        insert into public.community_message_mentions (message_id, mentioned_user_id)
        values (v_id, v_mention)
        on conflict do nothing;
      end if;
    end loop;
  end if;

  if p_attachment_ids is not null then
    update public.community_message_attachments
    set message_id = v_id,
        status = 'ready'
    where id = any (p_attachment_ids)
      and author_id = auth.uid()
      and community_id = p_community_id
      and message_id is null
      and status = 'pending';
  end if;

  return nano_internal.community_message_json(v_id);
end;
$$;

create or replace function public.pin_community_message(
  p_message_id uuid,
  p_pinned boolean default true
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_msg public.community_messages%rowtype;
  v_role text;
begin
  perform nano_internal.assert_communities_allowed();

  select * into v_msg from public.community_messages where id = p_message_id;
  if not found then
    raise exception 'COMMUNITY_MESSAGE_NOT_FOUND' using errcode = 'P0001';
  end if;

  v_role := nano_internal.caller_community_role(v_msg.community_id);
  if v_role is null or v_role not in ('owner', 'admin', 'moderator') then
    raise exception 'COMMUNITY_MOD_REQUIRED' using errcode = 'P0001';
  end if;

  if coalesce(p_pinned, true) then
    update public.community_messages
    set pinned_at = timezone('utc', now()),
        pinned_by = auth.uid()
    where id = p_message_id;
  else
    update public.community_messages
    set pinned_at = null,
        pinned_by = null
    where id = p_message_id;
  end if;

  return nano_internal.community_message_json(p_message_id);
end;
$$;

revoke all on function public.pin_community_message(uuid, boolean) from public, anon;
grant execute on function public.pin_community_message(uuid, boolean) to authenticated, service_role;

create or replace function public.list_community_pins(p_community_id uuid)
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
  if v_role is null then
    raise exception 'COMMUNITY_MEMBER_REQUIRED' using errcode = 'P0001';
  end if;

  return coalesce((
    select jsonb_agg(nano_internal.community_message_json(m.id) order by m.pinned_at desc)
    from public.community_messages m
    where m.community_id = p_community_id
      and m.pinned_at is not null
  ), '[]'::jsonb);
end;
$$;

revoke all on function public.list_community_pins(uuid) from public, anon;
grant execute on function public.list_community_pins(uuid) to authenticated, service_role;

create or replace function public.search_community_messages(
  p_community_id uuid,
  p_query text,
  p_limit int default 30
)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_role text;
  v_q text := nullif(trim(coalesce(p_query, '')), '');
  v_limit int := least(greatest(coalesce(p_limit, 30), 1), 50);
begin
  perform nano_internal.assert_communities_allowed();
  v_role := nano_internal.caller_community_role(p_community_id);
  if v_role is null then
    raise exception 'COMMUNITY_MEMBER_REQUIRED' using errcode = 'P0001';
  end if;
  if v_q is null or char_length(v_q) < 2 then
    return '[]'::jsonb;
  end if;

  return coalesce((
    select jsonb_agg(nano_internal.community_message_json(m.id) order by m.created_at desc)
    from (
      select cm.id, cm.created_at
      from public.community_messages cm
      where cm.community_id = p_community_id
        and cm.body ilike '%' || v_q || '%'
      order by cm.created_at desc
      limit v_limit
    ) m
  ), '[]'::jsonb);
end;
$$;

revoke all on function public.search_community_messages(uuid, text, int) from public, anon;
grant execute on function public.search_community_messages(uuid, text, int) to authenticated, service_role;

create or replace function public.list_community_gallery(
  p_community_id uuid,
  p_kind text default null,
  p_limit int default 50
)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_role text;
  v_kind text := nullif(lower(trim(coalesce(p_kind, ''))), '');
  v_limit int := least(greatest(coalesce(p_limit, 50), 1), 100);
begin
  perform nano_internal.assert_communities_allowed();
  v_role := nano_internal.caller_community_role(p_community_id);
  if v_role is null then
    raise exception 'COMMUNITY_MEMBER_REQUIRED' using errcode = 'P0001';
  end if;

  if v_kind is not null and v_kind not in ('voice', 'photo', 'video', 'file') then
    raise exception 'COMMUNITY_MEDIA_KIND_INVALID' using errcode = 'P0001';
  end if;

  return coalesce((
    select jsonb_agg(nano_internal.community_attachment_json(a.id) order by a.created_at desc)
    from (
      select att.id, att.created_at
      from public.community_message_attachments att
      where att.community_id = p_community_id
        and att.status = 'ready'
        and att.message_id is not null
        and (v_kind is null or att.kind = v_kind)
      order by att.created_at desc
      limit v_limit
    ) a
  ), '[]'::jsonb);
end;
$$;

revoke all on function public.list_community_gallery(uuid, text, int) from public, anon;
grant execute on function public.list_community_gallery(uuid, text, int) to authenticated, service_role;

create or replace function public.set_community_member_prefs(
  p_community_id uuid,
  p_muted boolean default null,
  p_archived boolean default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_role text;
  v_muted boolean;
  v_archived_at timestamptz;
begin
  perform nano_internal.assert_communities_allowed();
  v_role := nano_internal.caller_community_role(p_community_id);
  if v_role is null then
    raise exception 'COMMUNITY_MEMBER_REQUIRED' using errcode = 'P0001';
  end if;

  insert into public.community_member_prefs as pref (
    community_id, user_id, muted, archived_at, updated_at
  ) values (
    p_community_id,
    auth.uid(),
    coalesce(p_muted, false),
    case when coalesce(p_archived, false) then timezone('utc', now()) else null end,
    timezone('utc', now())
  )
  on conflict (community_id, user_id) do update
    set muted = case when p_muted is null then pref.muted else p_muted end,
        archived_at = case
          when p_archived is null then pref.archived_at
          when p_archived then timezone('utc', now())
          else null
        end,
        updated_at = timezone('utc', now())
  returning muted, archived_at into v_muted, v_archived_at;

  return jsonb_build_object(
    'community_id', p_community_id,
    'is_muted', v_muted,
    'is_archived', v_archived_at is not null
  );
end;
$$;

revoke all on function public.set_community_member_prefs(uuid, boolean, boolean) from public, anon;
grant execute on function public.set_community_member_prefs(uuid, boolean, boolean)
  to authenticated, service_role;

create or replace function public.set_community_posting_mode(
  p_community_id uuid,
  p_mode text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_role text;
  v_mode text := lower(trim(coalesce(p_mode, '')));
begin
  perform nano_internal.assert_communities_allowed();
  v_role := nano_internal.caller_community_role(p_community_id);
  if v_role is null or v_role not in ('owner', 'admin') then
    raise exception 'COMMUNITY_ADMIN_REQUIRED' using errcode = 'P0001';
  end if;
  if v_mode not in ('open', 'admins_only') then
    raise exception 'COMMUNITY_POSTING_MODE_INVALID' using errcode = 'P0001';
  end if;

  update public.communities
  set posting_mode = v_mode,
      updated_at = timezone('utc', now())
  where id = p_community_id;

  return public.get_community_detail(p_community_id);
end;
$$;

revoke all on function public.set_community_posting_mode(uuid, text) from public, anon;
grant execute on function public.set_community_posting_mode(uuid, text) to authenticated, service_role;
