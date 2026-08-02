-- CLS-02: classroom attachments (link-first; optional file metadata).
-- Schedule/ack → CLS-03. Student feed → FLX-04. Malware/upload worker deferred.

do $$
begin
  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'classroom_attachment_kind'
  ) then
    create type public.classroom_attachment_kind as enum ('link', 'file');
  end if;
end $$;

create table if not exists public.classroom_attachments (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id),
  classroom_item_id uuid not null references public.classroom_items (id) on delete cascade,
  kind public.classroom_attachment_kind not null default 'link',
  title text not null,
  url text,
  storage_bucket text,
  storage_path text,
  content_type text,
  byte_size bigint,
  checksum text,
  sort_order integer not null default 1,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint classroom_attachments_title_nonempty check (btrim(title) <> ''),
  constraint classroom_attachments_link_has_url check (
    kind <> 'link'::public.classroom_attachment_kind
    or (url is not null and btrim(url) <> '')
  ),
  constraint classroom_attachments_file_has_ref check (
    kind <> 'file'::public.classroom_attachment_kind
    or (
      (url is not null and btrim(url) <> '')
      or (storage_path is not null and btrim(storage_path) <> '')
    )
  ),
  constraint classroom_attachments_byte_size_nonneg check (
    byte_size is null or byte_size >= 0
  )
);

create index if not exists classroom_attachments_item_idx
  on public.classroom_attachments (classroom_item_id, sort_order, created_at);

alter table public.classroom_attachments enable row level security;

revoke all on table public.classroom_attachments from public, anon, authenticated;
grant select, insert, update, delete on table public.classroom_attachments to service_role;

drop trigger if exists classroom_attachments_set_updated_at on public.classroom_attachments;
create trigger classroom_attachments_set_updated_at
  before update on public.classroom_attachments
  for each row execute function public.set_updated_at();

create or replace function public.teacher_classroom_list(p_assignment_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_assignment public.teacher_assignments%rowtype;
  v_items jsonb;
begin
  v_assignment := nano_internal.require_active_teacher_assignment(p_assignment_id);

  select coalesce(jsonb_agg(jsonb_build_object(
    'id', i.id,
    'school_id', i.school_id,
    'teacher_assignment_id', i.teacher_assignment_id,
    'title', i.title,
    'body', i.body,
    'status', i.status::text,
    'published_at', i.published_at,
    'created_at', i.created_at,
    'updated_at', i.updated_at,
    'attachments', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', a.id,
        'classroom_item_id', a.classroom_item_id,
        'kind', a.kind::text,
        'title', a.title,
        'url', a.url,
        'storage_bucket', a.storage_bucket,
        'storage_path', a.storage_path,
        'content_type', a.content_type,
        'byte_size', a.byte_size,
        'checksum', a.checksum,
        'sort_order', a.sort_order
      ) order by a.sort_order, a.created_at)
      from public.classroom_attachments a
      where a.classroom_item_id = i.id
    ), '[]'::jsonb)
  ) order by i.created_at desc), '[]'::jsonb)
  into v_items
  from public.classroom_items i
  where i.teacher_assignment_id = v_assignment.id
    and i.teacher_user_id = auth.uid();

  return jsonb_build_object(
    'assignment_id', v_assignment.id,
    'school_id', v_assignment.school_id,
    'class_label', coalesce(
      (select c.name from public.classes c where c.id = v_assignment.class_id),
      v_assignment.class_label
    ),
    'subject_code', coalesce(
      (select ss.code from public.school_subjects ss where ss.id = v_assignment.school_subject_id),
      v_assignment.subject_code
    ),
    'items', v_items,
    'generated_at', timezone('utc', now())
  );
end;
$fn$;

create or replace function public.teacher_classroom_attachment_add(
  p_item_id uuid,
  p_kind text,
  p_title text,
  p_url text default null,
  p_storage_bucket text default null,
  p_storage_path text default null,
  p_content_type text default null,
  p_byte_size bigint default null,
  p_checksum text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_item public.classroom_items%rowtype;
  v_kind text := lower(btrim(coalesce(p_kind, 'link')));
  v_title text := btrim(coalesce(p_title, ''));
  v_url text := nullif(btrim(coalesce(p_url, '')), '');
  v_path text := nullif(btrim(coalesce(p_storage_path, '')), '');
  v_sort integer := 1;
  v_id uuid;
begin
  if p_item_id is null then
    raise exception using errcode = 'NS117', message = 'Announcement id is required.';
  end if;
  if v_title = '' then
    raise exception using errcode = 'NS120', message = 'Attachment title is required.';
  end if;
  if v_kind not in ('link', 'file') then
    raise exception using errcode = 'NS121', message = 'Invalid attachment kind.';
  end if;

  select * into v_item
  from public.classroom_items i
  where i.id = p_item_id
  for update;

  if not found then
    raise exception using errcode = 'NS118', message = 'Announcement not found.';
  end if;

  if v_item.teacher_user_id is distinct from auth.uid() then
    raise exception using errcode = 'NS098', message = 'Announcement is not in your scope.';
  end if;

  if v_item.status is distinct from 'draft'::public.classroom_item_status then
    raise exception using
      errcode = 'NS122',
      message = 'Attachments can only be changed on draft announcements.';
  end if;

  perform nano_internal.require_active_teacher_assignment(v_item.teacher_assignment_id);

  if v_kind = 'link' then
    if v_url is null or v_url !~* '^https?://' then
      raise exception using
        errcode = 'NS123',
        message = 'Link attachments require an http(s) URL.';
    end if;
  elsif v_url is null and v_path is null then
    raise exception using
      errcode = 'NS124',
      message = 'File attachments require a URL or storage path.';
  end if;

  select coalesce(max(a.sort_order), 0) + 1 into v_sort
  from public.classroom_attachments a
  where a.classroom_item_id = v_item.id;

  insert into public.classroom_attachments (
    school_id, classroom_item_id, kind, title, url,
    storage_bucket, storage_path, content_type, byte_size, checksum,
    sort_order, created_by
  ) values (
    v_item.school_id, v_item.id, v_kind::public.classroom_attachment_kind, v_title, v_url,
    nullif(btrim(coalesce(p_storage_bucket, '')), ''), v_path,
    nullif(btrim(coalesce(p_content_type, '')), ''), p_byte_size,
    nullif(btrim(coalesce(p_checksum, '')), ''),
    v_sort, auth.uid()
  )
  returning id into v_id;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'teacher', v_item.school_id,
    'create'::public.audit_action_kind, 'classroom_attachment', v_id::text,
    jsonb_build_object(
      'classroom_item_id', v_item.id,
      'kind', v_kind,
      'title', v_title
    )
  );

  return public.teacher_classroom_list(v_item.teacher_assignment_id);
end;
$fn$;

create or replace function public.teacher_classroom_attachment_remove(p_attachment_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_att public.classroom_attachments%rowtype;
  v_item public.classroom_items%rowtype;
begin
  if p_attachment_id is null then
    raise exception using errcode = 'NS125', message = 'Attachment id is required.';
  end if;

  select * into v_att
  from public.classroom_attachments a
  where a.id = p_attachment_id
  for update;

  if not found then
    raise exception using errcode = 'NS126', message = 'Attachment not found.';
  end if;

  select * into v_item
  from public.classroom_items i
  where i.id = v_att.classroom_item_id
  for update;

  if not found then
    raise exception using errcode = 'NS118', message = 'Announcement not found.';
  end if;

  if v_item.teacher_user_id is distinct from auth.uid() then
    raise exception using errcode = 'NS098', message = 'Announcement is not in your scope.';
  end if;

  if v_item.status is distinct from 'draft'::public.classroom_item_status then
    raise exception using
      errcode = 'NS122',
      message = 'Attachments can only be changed on draft announcements.';
  end if;

  perform nano_internal.require_active_teacher_assignment(v_item.teacher_assignment_id);

  delete from public.classroom_attachments where id = v_att.id;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'teacher', v_item.school_id,
    'delete'::public.audit_action_kind, 'classroom_attachment', v_att.id::text,
    jsonb_build_object('classroom_item_id', v_item.id)
  );

  return public.teacher_classroom_list(v_item.teacher_assignment_id);
end;
$fn$;

revoke all on function public.teacher_classroom_attachment_add(
  uuid, text, text, text, text, text, text, bigint, text
) from public, anon;
grant execute on function public.teacher_classroom_attachment_add(
  uuid, text, text, text, text, text, text, bigint, text
) to authenticated, service_role;

revoke all on function public.teacher_classroom_attachment_remove(uuid)
  from public, anon;
grant execute on function public.teacher_classroom_attachment_remove(uuid)
  to authenticated, service_role;

comment on table public.classroom_attachments is
  'CLS-02 classroom announcement attachments (link-first; file metadata optional).';
comment on function public.teacher_classroom_attachment_add(
  uuid, text, text, text, text, text, text, bigint, text
) is
  'CLS-02 add an attachment to a draft classroom announcement.';
comment on function public.teacher_classroom_attachment_remove(uuid) is
  'CLS-02 remove an attachment from a draft classroom announcement.';
