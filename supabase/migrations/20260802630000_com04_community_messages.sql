-- COM-04: text messages, replies, mentions, reactions.

create table if not exists public.community_messages (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references public.communities (id) on delete cascade,
  author_id uuid not null references public.profiles (id) on delete cascade,
  body text not null,
  parent_message_id uuid references public.community_messages (id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  constraint community_messages_body_len check (
    char_length(trim(body)) between 1 and 2000
  )
);

comment on table public.community_messages is
  'COM-04 text messages and replies. Media deferred to COM-05.';

create index if not exists community_messages_community_created_idx
  on public.community_messages (community_id, created_at desc);

create index if not exists community_messages_parent_idx
  on public.community_messages (parent_message_id)
  where parent_message_id is not null;

create table if not exists public.community_message_mentions (
  message_id uuid not null references public.community_messages (id) on delete cascade,
  mentioned_user_id uuid not null references public.profiles (id) on delete cascade,
  primary key (message_id, mentioned_user_id)
);

comment on table public.community_message_mentions is
  'COM-04 @mentions on community messages.';

create table if not exists public.message_reactions (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.community_messages (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  emoji text not null,
  created_at timestamptz not null default timezone('utc', now()),
  constraint message_reactions_emoji_len check (
    char_length(emoji) between 1 and 8
  ),
  constraint message_reactions_unique unique (message_id, user_id, emoji)
);

comment on table public.message_reactions is
  'COM-04 emoji reactions on community messages.';

create index if not exists message_reactions_message_idx
  on public.message_reactions (message_id);

alter table public.community_messages enable row level security;
alter table public.community_message_mentions enable row level security;
alter table public.message_reactions enable row level security;

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
    'reactions', v_reactions
  );
end;
$$;

revoke all on function nano_internal.community_message_json(uuid) from public, anon;
grant execute on function nano_internal.community_message_json(uuid) to authenticated, service_role;

create or replace function public.list_community_messages(
  p_community_id uuid,
  p_before timestamptz default null,
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
  v_limit int := least(greatest(coalesce(p_limit, 50), 1), 100);
begin
  perform nano_internal.assert_communities_allowed();

  v_role := nano_internal.caller_community_role(p_community_id);
  if v_role is null then
    raise exception 'COMMUNITY_MEMBER_REQUIRED' using errcode = 'P0001';
  end if;

  return coalesce((
    select jsonb_agg(nano_internal.community_message_json(m.id) order by m.created_at asc)
    from (
      select cm.id, cm.created_at
      from public.community_messages cm
      where cm.community_id = p_community_id
        and (p_before is null or cm.created_at < p_before)
      order by cm.created_at desc
      limit v_limit
    ) m
  ), '[]'::jsonb);
end;
$$;

revoke all on function public.list_community_messages(uuid, timestamptz, int) from public, anon;
grant execute on function public.list_community_messages(uuid, timestamptz, int) to authenticated, service_role;

create or replace function public.send_community_message(
  p_community_id uuid,
  p_body text,
  p_parent_message_id uuid default null,
  p_mention_ids uuid[] default null
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
begin
  perform nano_internal.assert_communities_allowed();

  v_role := nano_internal.caller_community_role(p_community_id);
  if v_role is null then
    raise exception 'COMMUNITY_MEMBER_REQUIRED' using errcode = 'P0001';
  end if;

  if v_body = '' then
    raise exception 'COMMUNITY_MESSAGE_REQUIRED' using errcode = 'P0001';
  end if;

  perform nano_internal.assert_community_message_allowed(auth.uid(), v_body);

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

  return nano_internal.community_message_json(v_id);
end;
$$;

revoke all on function public.send_community_message(uuid, text, uuid, uuid[]) from public, anon;
grant execute on function public.send_community_message(uuid, text, uuid, uuid[]) to authenticated, service_role;

create or replace function public.toggle_message_reaction(
  p_message_id uuid,
  p_emoji text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_msg public.community_messages%rowtype;
  v_role text;
  v_emoji text := trim(coalesce(p_emoji, ''));
begin
  perform nano_internal.assert_communities_allowed();

  if v_emoji = '' or char_length(v_emoji) > 8 then
    raise exception 'COMMUNITY_REACTION_INVALID' using errcode = 'P0001';
  end if;

  select * into v_msg from public.community_messages where id = p_message_id;
  if not found then
    raise exception 'COMMUNITY_MESSAGE_NOT_FOUND' using errcode = 'P0001';
  end if;

  v_role := nano_internal.caller_community_role(v_msg.community_id);
  if v_role is null then
    raise exception 'COMMUNITY_MEMBER_REQUIRED' using errcode = 'P0001';
  end if;

  if exists (
    select 1 from public.message_reactions r
    where r.message_id = p_message_id
      and r.user_id = auth.uid()
      and r.emoji = v_emoji
  ) then
    delete from public.message_reactions
    where message_id = p_message_id
      and user_id = auth.uid()
      and emoji = v_emoji;
  else
    insert into public.message_reactions (message_id, user_id, emoji)
    values (p_message_id, auth.uid(), v_emoji);
  end if;

  return nano_internal.community_message_json(p_message_id);
end;
$$;

revoke all on function public.toggle_message_reaction(uuid, text) from public, anon;
grant execute on function public.toggle_message_reaction(uuid, text) to authenticated, service_role;
