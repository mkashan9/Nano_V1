-- CLS-03: scheduled publication, expiry, and acknowledgements.
-- Student feed UI → FLX-04. Expired rows remain listed (history).

alter table public.classroom_items
  add column if not exists scheduled_publish_at timestamptz,
  add column if not exists expires_at timestamptz,
  add column if not exists requires_acknowledgement boolean not null default true;

alter table public.classroom_items
  drop constraint if exists classroom_items_expiry_after_publish;
alter table public.classroom_items
  add constraint classroom_items_expiry_after_publish check (
    expires_at is null
    or scheduled_publish_at is null
    or expires_at > scheduled_publish_at
  );

create table if not exists public.classroom_acknowledgements (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id),
  classroom_item_id uuid not null references public.classroom_items (id) on delete cascade,
  student_user_id uuid not null references public.profiles (id),
  acknowledged_at timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now()),
  constraint classroom_acknowledgements_unique unique (classroom_item_id, student_user_id)
);

create index if not exists classroom_acknowledgements_item_idx
  on public.classroom_acknowledgements (classroom_item_id, acknowledged_at);

alter table public.classroom_acknowledgements enable row level security;

revoke all on table public.classroom_acknowledgements
  from public, anon, authenticated;
grant select, insert, update, delete on table public.classroom_acknowledgements
  to service_role;

create or replace function nano_internal.classroom_promote_due(p_assignment_id uuid)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
begin
  update public.classroom_items i
  set status = 'published'::public.classroom_item_status,
      published_at = coalesce(i.published_at, i.scheduled_publish_at, timezone('utc', now())),
      updated_at = timezone('utc', now())
  where i.teacher_assignment_id = p_assignment_id
    and i.status = 'draft'::public.classroom_item_status
    and i.scheduled_publish_at is not null
    and i.scheduled_publish_at <= timezone('utc', now());
end;
$fn$;

create or replace function nano_internal.classroom_roster_count(p_assignment_id uuid)
returns integer
language sql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
  select coalesce(count(*)::integer, 0)
  from public.teacher_assignments ta
  join public.student_enrollments se
    on se.school_id = ta.school_id
   and se.class_id = ta.class_id
   and se.status = 'active'::public.membership_status
  where ta.id = p_assignment_id;
$$;

create or replace function public.teacher_classroom_list(p_assignment_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_assignment public.teacher_assignments%rowtype;
  v_items jsonb;
  v_roster integer;
begin
  v_assignment := nano_internal.require_active_teacher_assignment(p_assignment_id);
  perform nano_internal.classroom_promote_due(p_assignment_id);
  v_roster := nano_internal.classroom_roster_count(p_assignment_id);

  select coalesce(jsonb_agg(jsonb_build_object(
    'id', i.id,
    'school_id', i.school_id,
    'teacher_assignment_id', i.teacher_assignment_id,
    'title', i.title,
    'body', i.body,
    'status', i.status::text,
    'scheduled_publish_at', i.scheduled_publish_at,
    'expires_at', i.expires_at,
    'requires_acknowledgement', i.requires_acknowledgement,
    'is_expired', (
      i.expires_at is not null and i.expires_at <= timezone('utc', now())
    ),
    'ack_count', (
      select count(*)::integer
      from public.classroom_acknowledgements a
      where a.classroom_item_id = i.id
    ),
    'roster_count', v_roster,
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

drop function if exists public.teacher_classroom_create(uuid, text, text, boolean);
create or replace function public.teacher_classroom_create(
  p_assignment_id uuid,
  p_title text,
  p_body text default '',
  p_publish boolean default false,
  p_scheduled_publish_at timestamptz default null,
  p_expires_at timestamptz default null,
  p_requires_acknowledgement boolean default true
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_assignment public.teacher_assignments%rowtype;
  v_title text := btrim(coalesce(p_title, ''));
  v_body text := coalesce(p_body, '');
  v_status public.classroom_item_status := 'draft';
  v_published_at timestamptz := null;
  v_scheduled timestamptz := p_scheduled_publish_at;
  v_expires timestamptz := p_expires_at;
  v_id uuid;
begin
  if v_title = '' then
    raise exception using errcode = 'NS116', message = 'Title is required.';
  end if;

  v_assignment := nano_internal.require_active_teacher_assignment(p_assignment_id);

  if coalesce(p_publish, false) and v_scheduled is not null then
    raise exception using
      errcode = 'NS127',
      message = 'Choose either publish now or a schedule, not both.';
  end if;

  if v_expires is not null and v_scheduled is not null and v_expires <= v_scheduled then
    raise exception using
      errcode = 'NS128',
      message = 'Expiry must be after the scheduled publish time.';
  end if;

  if coalesce(p_publish, false) then
    v_status := 'published';
    v_published_at := timezone('utc', now());
    v_scheduled := null;
    if v_expires is not null and v_expires <= v_published_at then
      raise exception using
        errcode = 'NS128',
        message = 'Expiry must be after publish time.';
    end if;
  elsif v_scheduled is not null and v_scheduled <= timezone('utc', now()) then
    v_status := 'published';
    v_published_at := v_scheduled;
  end if;

  insert into public.classroom_items (
    school_id, teacher_assignment_id, teacher_user_id,
    title, body, status, published_at,
    scheduled_publish_at, expires_at, requires_acknowledgement
  ) values (
    v_assignment.school_id, v_assignment.id, auth.uid(),
    v_title, v_body, v_status, v_published_at,
    v_scheduled, v_expires, coalesce(p_requires_acknowledgement, true)
  )
  returning id into v_id;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'teacher', v_assignment.school_id,
    'create'::public.audit_action_kind, 'classroom_item', v_id::text,
    jsonb_build_object(
      'assignment_id', v_assignment.id,
      'title', v_title,
      'status', v_status::text,
      'scheduled_publish_at', v_scheduled,
      'expires_at', v_expires
    )
  );

  return public.teacher_classroom_list(v_assignment.id);
end;
$fn$;

drop function if exists public.teacher_classroom_update(uuid, text, text);
create or replace function public.teacher_classroom_update(
  p_item_id uuid,
  p_title text,
  p_body text default '',
  p_scheduled_publish_at timestamptz default null,
  p_expires_at timestamptz default null,
  p_requires_acknowledgement boolean default null,
  p_clear_schedule boolean default false,
  p_clear_expiry boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_row public.classroom_items%rowtype;
  v_title text := btrim(coalesce(p_title, ''));
  v_body text := coalesce(p_body, '');
  v_scheduled timestamptz;
  v_expires timestamptz;
  v_status public.classroom_item_status;
  v_published_at timestamptz;
begin
  if p_item_id is null then
    raise exception using errcode = 'NS117', message = 'Announcement id is required.';
  end if;
  if v_title = '' then
    raise exception using errcode = 'NS116', message = 'Title is required.';
  end if;

  select * into v_row
  from public.classroom_items i
  where i.id = p_item_id
  for update;

  if not found then
    raise exception using errcode = 'NS118', message = 'Announcement not found.';
  end if;

  if v_row.teacher_user_id is distinct from auth.uid() then
    raise exception using errcode = 'NS098', message = 'Announcement is not in your scope.';
  end if;

  if v_row.status is distinct from 'draft'::public.classroom_item_status then
    raise exception using
      errcode = 'NS119',
      message = 'Only draft announcements can be edited.';
  end if;

  perform nano_internal.require_active_teacher_assignment(v_row.teacher_assignment_id);

  v_scheduled := case
    when coalesce(p_clear_schedule, false) then null
    when p_scheduled_publish_at is not null then p_scheduled_publish_at
    else v_row.scheduled_publish_at
  end;
  v_expires := case
    when coalesce(p_clear_expiry, false) then null
    when p_expires_at is not null then p_expires_at
    else v_row.expires_at
  end;

  if v_expires is not null and v_scheduled is not null and v_expires <= v_scheduled then
    raise exception using
      errcode = 'NS128',
      message = 'Expiry must be after the scheduled publish time.';
  end if;

  v_status := v_row.status;
  v_published_at := v_row.published_at;
  if v_scheduled is not null and v_scheduled <= timezone('utc', now()) then
    v_status := 'published';
    v_published_at := coalesce(v_published_at, v_scheduled);
  end if;

  update public.classroom_items i
  set title = v_title,
      body = v_body,
      scheduled_publish_at = v_scheduled,
      expires_at = v_expires,
      requires_acknowledgement = coalesce(
        p_requires_acknowledgement, i.requires_acknowledgement
      ),
      status = v_status,
      published_at = v_published_at,
      updated_at = timezone('utc', now())
  where i.id = v_row.id;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'teacher', v_row.school_id,
    'update'::public.audit_action_kind, 'classroom_item', v_row.id::text,
    jsonb_build_object(
      'title', v_title,
      'scheduled_publish_at', v_scheduled,
      'expires_at', v_expires
    )
  );

  return public.teacher_classroom_list(v_row.teacher_assignment_id);
end;
$fn$;

create or replace function public.student_classroom_acknowledge(p_item_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_item public.classroom_items%rowtype;
  v_assignment public.teacher_assignments%rowtype;
  v_enrolled boolean := false;
  v_id uuid;
begin
  if p_item_id is null then
    raise exception using errcode = 'NS117', message = 'Announcement id is required.';
  end if;

  select * into v_item
  from public.classroom_items i
  where i.id = p_item_id
  for share;

  if not found then
    raise exception using errcode = 'NS118', message = 'Announcement not found.';
  end if;

  if v_item.status is distinct from 'published'::public.classroom_item_status then
    raise exception using
      errcode = 'NS129',
      message = 'Only published announcements can be acknowledged.';
  end if;

  if v_item.expires_at is not null and v_item.expires_at <= timezone('utc', now()) then
    raise exception using
      errcode = 'NS130',
      message = 'This announcement has expired.';
  end if;

  if not coalesce(v_item.requires_acknowledgement, true) then
    raise exception using
      errcode = 'NS131',
      message = 'Acknowledgement is not required for this announcement.';
  end if;

  select * into v_assignment
  from public.teacher_assignments ta
  where ta.id = v_item.teacher_assignment_id;

  select exists (
    select 1
    from public.student_enrollments se
    where se.school_id = v_item.school_id
      and se.class_id = v_assignment.class_id
      and se.student_user_id = auth.uid()
      and se.status = 'active'::public.membership_status
  ) into v_enrolled;

  if not v_enrolled then
    raise exception using
      errcode = 'NS132',
      message = 'Announcement is not in your class.';
  end if;

  insert into public.classroom_acknowledgements (
    school_id, classroom_item_id, student_user_id
  ) values (
    v_item.school_id, v_item.id, auth.uid()
  )
  on conflict (classroom_item_id, student_user_id) do update
    set acknowledged_at = excluded.acknowledged_at
  returning id into v_id;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'student', v_item.school_id,
    'create'::public.audit_action_kind, 'classroom_acknowledgement', v_id::text,
    jsonb_build_object('classroom_item_id', v_item.id)
  );

  return jsonb_build_object(
    'id', v_id,
    'classroom_item_id', v_item.id,
    'acknowledged_at', timezone('utc', now())
  );
end;
$fn$;

revoke all on function public.teacher_classroom_create(
  uuid, text, text, boolean, timestamptz, timestamptz, boolean
) from public, anon;
grant execute on function public.teacher_classroom_create(
  uuid, text, text, boolean, timestamptz, timestamptz, boolean
) to authenticated, service_role;

revoke all on function public.teacher_classroom_update(
  uuid, text, text, timestamptz, timestamptz, boolean, boolean, boolean
) from public, anon;
grant execute on function public.teacher_classroom_update(
  uuid, text, text, timestamptz, timestamptz, boolean, boolean, boolean
) to authenticated, service_role;

revoke all on function public.student_classroom_acknowledge(uuid) from public, anon;
grant execute on function public.student_classroom_acknowledge(uuid)
  to authenticated, service_role;

comment on column public.classroom_items.scheduled_publish_at is
  'CLS-03 optional future publish time; due drafts promote on list.';
comment on column public.classroom_items.expires_at is
  'CLS-03 optional expiry; expired items remain in history.';
comment on table public.classroom_acknowledgements is
  'CLS-03 student acknowledgements for published classroom items.';
comment on function public.student_classroom_acknowledge(uuid) is
  'CLS-03 idempotent student acknowledgement (audited).';
