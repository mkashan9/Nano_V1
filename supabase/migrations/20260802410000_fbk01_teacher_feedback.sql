-- FBK-01: teacher structured feedback notes for roster students (draft/publish).
-- Guardian read deferred (PAR-* / guardian_links). Student Flex surface deferred.

do $$
begin
  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'feedback_category'
  ) then
    create type public.feedback_category as enum (
      'effort',
      'behavior',
      'progress'
    );
  end if;

  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'feedback_note_status'
  ) then
    create type public.feedback_note_status as enum ('draft', 'published');
  end if;
end $$;

create table if not exists public.feedback_notes (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id),
  teacher_assignment_id uuid not null references public.teacher_assignments (id),
  teacher_user_id uuid not null references public.profiles (id),
  student_user_id uuid not null references public.profiles (id),
  category public.feedback_category not null,
  body text not null default '',
  status public.feedback_note_status not null default 'draft',
  published_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint feedback_notes_body_nonempty check (btrim(body) <> '')
);

create index if not exists feedback_notes_assignment_idx
  on public.feedback_notes (teacher_assignment_id, created_at desc);

create index if not exists feedback_notes_student_idx
  on public.feedback_notes (student_user_id, created_at desc);

create index if not exists feedback_notes_school_status_idx
  on public.feedback_notes (school_id, status);

alter table public.feedback_notes enable row level security;

revoke all on table public.feedback_notes from public, anon, authenticated;
grant select, insert, update, delete on table public.feedback_notes to service_role;

drop trigger if exists feedback_notes_set_updated_at on public.feedback_notes;
create trigger feedback_notes_set_updated_at
  before update on public.feedback_notes
  for each row execute function public.set_updated_at();

create or replace function nano_internal.require_feedback_roster_student(
  p_assignment public.teacher_assignments,
  p_student_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_ok boolean := false;
begin
  if p_student_user_id is null then
    raise exception using
      errcode = 'NS135',
      message = 'Student is required.';
  end if;

  select exists (
    select 1
    from public.student_enrollments se
    where se.school_id = p_assignment.school_id
      and se.class_id = p_assignment.class_id
      and se.student_user_id = p_student_user_id
      and se.status = 'active'::public.membership_status
  ) into v_ok;

  if not v_ok then
    raise exception using
      errcode = 'NS136',
      message = 'Student is not on this assignment roster.';
  end if;
end;
$fn$;

create or replace function public.teacher_feedback_list(p_assignment_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_assignment public.teacher_assignments%rowtype;
  v_notes jsonb;
begin
  v_assignment := nano_internal.require_active_teacher_assignment(p_assignment_id);

  select coalesce(jsonb_agg(jsonb_build_object(
    'id', n.id,
    'school_id', n.school_id,
    'teacher_assignment_id', n.teacher_assignment_id,
    'student_user_id', n.student_user_id,
    'student_display_name', coalesce(
      nullif(btrim(p.display_name), ''),
      'Student'
    ),
    'category', n.category::text,
    'body', n.body,
    'status', n.status::text,
    'published_at', n.published_at,
    'created_at', n.created_at,
    'updated_at', n.updated_at
  ) order by n.created_at desc), '[]'::jsonb)
  into v_notes
  from public.feedback_notes n
  left join public.profiles p on p.id = n.student_user_id
  where n.teacher_assignment_id = v_assignment.id
    and n.teacher_user_id = auth.uid();

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
    'notes', v_notes,
    'generated_at', timezone('utc', now())
  );
end;
$fn$;

create or replace function public.teacher_feedback_create(
  p_assignment_id uuid,
  p_student_user_id uuid,
  p_category text,
  p_body text,
  p_publish boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_assignment public.teacher_assignments%rowtype;
  v_body text := btrim(coalesce(p_body, ''));
  v_category public.feedback_category;
  v_status public.feedback_note_status := 'draft';
  v_published_at timestamptz := null;
  v_id uuid;
begin
  if v_body = '' then
    raise exception using errcode = 'NS137', message = 'Feedback body is required.';
  end if;

  begin
    v_category := lower(btrim(coalesce(p_category, '')))::public.feedback_category;
  exception
    when invalid_text_representation then
      raise exception using
        errcode = 'NS138',
        message = 'Invalid feedback category.';
  end;

  v_assignment := nano_internal.require_active_teacher_assignment(p_assignment_id);
  perform nano_internal.require_feedback_roster_student(
    v_assignment,
    p_student_user_id
  );

  if coalesce(p_publish, false) then
    v_status := 'published';
    v_published_at := timezone('utc', now());
  end if;

  insert into public.feedback_notes (
    school_id,
    teacher_assignment_id,
    teacher_user_id,
    student_user_id,
    category,
    body,
    status,
    published_at
  ) values (
    v_assignment.school_id,
    v_assignment.id,
    auth.uid(),
    p_student_user_id,
    v_category,
    v_body,
    v_status,
    v_published_at
  )
  returning id into v_id;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'teacher', v_assignment.school_id,
    'create'::public.audit_action_kind, 'feedback_note', v_id::text,
    jsonb_build_object(
      'assignment_id', v_assignment.id,
      'student_user_id', p_student_user_id,
      'category', v_category::text,
      'status', v_status::text
    )
  );

  return public.teacher_feedback_list(v_assignment.id);
end;
$fn$;

create or replace function public.teacher_feedback_update(
  p_note_id uuid,
  p_category text,
  p_body text,
  p_publish boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_row public.feedback_notes%rowtype;
  v_body text := btrim(coalesce(p_body, ''));
  v_category public.feedback_category;
  v_status public.feedback_note_status;
  v_published_at timestamptz;
begin
  if p_note_id is null then
    raise exception using errcode = 'NS139', message = 'Feedback note id is required.';
  end if;
  if v_body = '' then
    raise exception using errcode = 'NS137', message = 'Feedback body is required.';
  end if;

  begin
    v_category := lower(btrim(coalesce(p_category, '')))::public.feedback_category;
  exception
    when invalid_text_representation then
      raise exception using
        errcode = 'NS138',
        message = 'Invalid feedback category.';
  end;

  select * into v_row
  from public.feedback_notes n
  where n.id = p_note_id
  for update;

  if not found then
    raise exception using errcode = 'NS140', message = 'Feedback note not found.';
  end if;

  if v_row.teacher_user_id is distinct from auth.uid() then
    raise exception using
      errcode = 'NS098',
      message = 'Feedback note is not in your scope.';
  end if;

  if v_row.status is distinct from 'draft'::public.feedback_note_status then
    raise exception using
      errcode = 'NS141',
      message = 'Only draft feedback notes can be edited.';
  end if;

  perform nano_internal.require_active_teacher_assignment(v_row.teacher_assignment_id);

  v_status := v_row.status;
  v_published_at := v_row.published_at;
  if coalesce(p_publish, false) then
    v_status := 'published';
    v_published_at := timezone('utc', now());
  end if;

  update public.feedback_notes n
  set category = v_category,
      body = v_body,
      status = v_status,
      published_at = v_published_at,
      updated_at = timezone('utc', now())
  where n.id = v_row.id;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'teacher', v_row.school_id,
    'update'::public.audit_action_kind, 'feedback_note', v_row.id::text,
    jsonb_build_object(
      'category', v_category::text,
      'status', v_status::text,
      'published', coalesce(p_publish, false)
    )
  );

  return public.teacher_feedback_list(v_row.teacher_assignment_id);
end;
$fn$;

revoke all on function public.teacher_feedback_list(uuid) from public, anon;
grant execute on function public.teacher_feedback_list(uuid)
  to authenticated, service_role;

revoke all on function public.teacher_feedback_create(uuid, uuid, text, text, boolean)
  from public, anon;
grant execute on function public.teacher_feedback_create(uuid, uuid, text, text, boolean)
  to authenticated, service_role;

revoke all on function public.teacher_feedback_update(uuid, text, text, boolean)
  from public, anon;
grant execute on function public.teacher_feedback_update(uuid, text, text, boolean)
  to authenticated, service_role;

comment on table public.feedback_notes is
  'FBK-01 teacher structured feedback notes; guardian read deferred.';
comment on function public.teacher_feedback_list(uuid) is
  'FBK-01 list teacher-owned feedback notes for an active assignment.';
comment on function public.teacher_feedback_create(uuid, uuid, text, text, boolean) is
  'FBK-01 create draft or published feedback for a roster student.';
comment on function public.teacher_feedback_update(uuid, text, text, boolean) is
  'FBK-01 edit draft feedback; optional publish.';
