-- COM-05: community media attachments (voice / photo / video / file).

insert into storage.buckets (id, name, public)
values ('community-media', 'community-media', false)
on conflict (id) do nothing;

create table if not exists public.community_message_attachments (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references public.communities (id) on delete cascade,
  message_id uuid references public.community_messages (id) on delete cascade,
  author_id uuid not null references public.profiles (id) on delete cascade,
  kind text not null
    check (kind in ('voice', 'photo', 'video', 'file')),
  storage_bucket text not null default 'community-media',
  storage_path text not null,
  content_type text,
  byte_size bigint check (byte_size is null or byte_size >= 0),
  checksum text,
  duration_ms int check (duration_ms is null or duration_ms >= 0),
  original_filename text,
  status text not null default 'pending'
    check (status in ('pending', 'ready', 'blocked')),
  created_at timestamptz not null default timezone('utc', now()),
  constraint community_message_attachments_path_unique unique (storage_bucket, storage_path)
);

comment on table public.community_message_attachments is
  'COM-05 media attachments for community messages. Evidence-ready for SAFE-02.';

create index if not exists community_message_attachments_message_idx
  on public.community_message_attachments (message_id)
  where message_id is not null;

create index if not exists community_message_attachments_community_idx
  on public.community_message_attachments (community_id, created_at desc);

alter table public.community_message_attachments enable row level security;

alter table public.community_messages
  drop constraint if exists community_messages_body_len;

alter table public.community_messages
  add constraint community_messages_body_len check (
    char_length(trim(body)) <= 2000
  );

create or replace function nano_internal.community_attachment_json(p_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
  select jsonb_build_object(
    'id', a.id,
    'community_id', a.community_id,
    'message_id', a.message_id,
    'kind', a.kind,
    'storage_bucket', a.storage_bucket,
    'storage_path', a.storage_path,
    'content_type', a.content_type,
    'byte_size', a.byte_size,
    'duration_ms', a.duration_ms,
    'original_filename', a.original_filename,
    'status', a.status
  )
  from public.community_message_attachments a
  where a.id = p_id;
$$;

revoke all on function nano_internal.community_attachment_json(uuid) from public, anon;
grant execute on function nano_internal.community_attachment_json(uuid) to authenticated, service_role;

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
    'attachments', v_attachments
  );
end;
$$;

create or replace function public.prepare_community_media_upload(
  p_community_id uuid,
  p_kind text,
  p_content_type text default null,
  p_byte_size bigint default null,
  p_original_filename text default null,
  p_duration_ms int default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_role text;
  v_kind text := lower(trim(coalesce(p_kind, '')));
  v_id uuid := gen_random_uuid();
  v_ext text := 'bin';
  v_path text;
begin
  perform nano_internal.assert_communities_allowed();

  v_role := nano_internal.caller_community_role(p_community_id);
  if v_role is null then
    raise exception 'COMMUNITY_MEMBER_REQUIRED' using errcode = 'P0001';
  end if;

  if v_kind not in ('voice', 'photo', 'video', 'file') then
    raise exception 'COMMUNITY_MEDIA_KIND_INVALID' using errcode = 'P0001';
  end if;

  perform nano_internal.assert_rate_limit(auth.uid(), 'community_message');

  if p_content_type is not null and position('/' in p_content_type) > 0 then
    v_ext := lower(split_part(p_content_type, '/', 2));
    v_ext := regexp_replace(v_ext, '[^a-z0-9]+', '', 'g');
    if v_ext = '' then
      v_ext := 'bin';
    end if;
  end if;

  v_path := p_community_id::text || '/' || auth.uid()::text || '/' || v_id::text || '.' || v_ext;

  insert into public.community_message_attachments (
    id, community_id, author_id, kind, storage_bucket, storage_path,
    content_type, byte_size, duration_ms, original_filename, status
  ) values (
    v_id, p_community_id, auth.uid(), v_kind, 'community-media', v_path,
    p_content_type, p_byte_size, p_duration_ms, nullif(trim(coalesce(p_original_filename, '')), ''),
    'pending'
  );

  return nano_internal.community_attachment_json(v_id);
end;
$$;

revoke all on function public.prepare_community_media_upload(uuid, text, text, bigint, text, int)
  from public, anon;
grant execute on function public.prepare_community_media_upload(uuid, text, text, bigint, text, int)
  to authenticated, service_role;

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
begin
  perform nano_internal.assert_communities_allowed();

  v_role := nano_internal.caller_community_role(p_community_id);
  if v_role is null then
    raise exception 'COMMUNITY_MEMBER_REQUIRED' using errcode = 'P0001';
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

revoke all on function public.send_community_message(uuid, text, uuid, uuid[], uuid[])
  from public, anon;
grant execute on function public.send_community_message(uuid, text, uuid, uuid[], uuid[])
  to authenticated, service_role;

-- Drop COM-04 4-arg signature if present (replaced by attachment-aware overload).
drop function if exists public.send_community_message(uuid, text, uuid, uuid[]);

drop policy if exists community_media_select on storage.objects;
create policy community_media_select on storage.objects
  for select to authenticated
  using (
    bucket_id = 'community-media'
    and nano_internal.caller_community_role((string_to_array(name, '/'))[1]::uuid) is not null
  );

drop policy if exists community_media_insert on storage.objects;
create policy community_media_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'community-media'
    and (string_to_array(name, '/'))[2] = auth.uid()::text
    and nano_internal.caller_community_role((string_to_array(name, '/'))[1]::uuid) is not null
  );
