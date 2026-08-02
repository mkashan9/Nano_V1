-- CLS-01: teacher classroom announcements (draft create/list/update; optional publish-now).
-- Attachments → CLS-02. Schedule/ack → CLS-03. Student feed → FLX-04.

do $$
begin
  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'classroom_item_status'
  ) then
    create type public.classroom_item_status as enum ('draft', 'published');
  end if;
end $$;

create table if not exists public.classroom_items (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id),
  teacher_assignment_id uuid not null references public.teacher_assignments (id),
  teacher_user_id uuid not null references public.profiles (id),
  title text not null,
  body text not null default '',
  status public.classroom_item_status not null default 'draft',
  published_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint classroom_items_title_nonempty check (btrim(title) <> '')
);

create index if not exists classroom_items_assignment_idx
  on public.classroom_items (teacher_assignment_id, created_at desc);

create index if not exists classroom_items_school_status_idx
  on public.classroom_items (school_id, status);

alter table public.classroom_items enable row level security;

revoke all on table public.classroom_items from public, anon, authenticated;
grant select, insert, update, delete on table public.classroom_items to service_role;

drop trigger if exists classroom_items_set_updated_at on public.classroom_items;
create trigger classroom_items_set_updated_at
  before update on public.classroom_items
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
    'updated_at', i.updated_at
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

create or replace function public.teacher_classroom_create(
  p_assignment_id uuid,
  p_title text,
  p_body text default '',
  p_publish boolean default false
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
  v_id uuid;
begin
  if v_title = '' then
    raise exception using errcode = 'NS116', message = 'Title is required.';
  end if;

  v_assignment := nano_internal.require_active_teacher_assignment(p_assignment_id);

  if coalesce(p_publish, false) then
    v_status := 'published';
    v_published_at := timezone('utc', now());
  end if;

  insert into public.classroom_items (
    school_id, teacher_assignment_id, teacher_user_id,
    title, body, status, published_at
  ) values (
    v_assignment.school_id, v_assignment.id, auth.uid(),
    v_title, v_body, v_status, v_published_at
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
      'status', v_status::text
    )
  );

  return public.teacher_classroom_list(v_assignment.id);
end;
$fn$;

create or replace function public.teacher_classroom_update(
  p_item_id uuid,
  p_title text,
  p_body text default ''
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

  update public.classroom_items i
  set title = v_title,
      body = v_body,
      updated_at = timezone('utc', now())
  where i.id = v_row.id;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'teacher', v_row.school_id,
    'update'::public.audit_action_kind, 'classroom_item', v_row.id::text,
    jsonb_build_object('title', v_title)
  );

  return public.teacher_classroom_list(v_row.teacher_assignment_id);
end;
$fn$;

revoke all on function public.teacher_classroom_list(uuid) from public, anon;
grant execute on function public.teacher_classroom_list(uuid)
  to authenticated, service_role;

revoke all on function public.teacher_classroom_create(uuid, text, text, boolean)
  from public, anon;
grant execute on function public.teacher_classroom_create(uuid, text, text, boolean)
  to authenticated, service_role;

revoke all on function public.teacher_classroom_update(uuid, text, text)
  from public, anon;
grant execute on function public.teacher_classroom_update(uuid, text, text)
  to authenticated, service_role;

comment on table public.classroom_items is
  'CLS-01 teacher classroom announcements scoped to teacher_assignments.';
comment on function public.teacher_classroom_list(uuid) is
  'CLS-01 list announcements for an active teacher assignment.';
comment on function public.teacher_classroom_create(uuid, text, text, boolean) is
  'CLS-01 create a draft (or publish-now) classroom announcement.';
comment on function public.teacher_classroom_update(uuid, text, text) is
  'CLS-01 update a draft classroom announcement.';
