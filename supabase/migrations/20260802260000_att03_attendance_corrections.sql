-- ATT-03: attendance corrections with immutable history (never erase prior values).

create table if not exists public.attendance_corrections (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id),
  session_id uuid not null references public.attendance_sessions (id),
  entry_id uuid not null references public.attendance_entries (id),
  student_user_id uuid not null references public.profiles (id),
  previous_status public.attendance_entry_status not null,
  new_status public.attendance_entry_status not null,
  reason text not null,
  corrected_by uuid not null references public.profiles (id),
  corrected_at timestamptz not null default timezone('utc', now()),
  revision_before integer not null,
  revision_after integer not null,
  constraint attendance_corrections_reason_nonempty check (btrim(reason) <> ''),
  constraint attendance_corrections_status_changed
    check (previous_status is distinct from new_status)
);

create index if not exists attendance_corrections_session_idx
  on public.attendance_corrections (session_id, corrected_at desc);

create index if not exists attendance_corrections_student_idx
  on public.attendance_corrections (session_id, student_user_id, corrected_at desc);

alter table public.attendance_corrections enable row level security;

revoke all on table public.attendance_corrections from public, anon, authenticated;
grant select, insert, update, delete on table public.attendance_corrections to service_role;

create or replace function nano_internal.forbid_attendance_correction_mutation()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $fn$
begin
  raise exception using
    errcode = 'NS081',
    message = 'Attendance corrections are immutable.';
end;
$fn$;

drop trigger if exists attendance_corrections_no_update on public.attendance_corrections;
create trigger attendance_corrections_no_update
  before update or delete on public.attendance_corrections
  for each row
  execute function nano_internal.forbid_attendance_correction_mutation();

create or replace function public.teacher_attendance_history(
  p_assignment_id uuid,
  p_session_date date,
  p_period_key text default 'daily'
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_assignment public.teacher_assignments%rowtype;
  v_period text := coalesce(nullif(btrim(p_period_key), ''), 'daily');
  v_mode text := 'daily';
  v_session public.attendance_sessions%rowtype;
  v_rows jsonb := '[]'::jsonb;
begin
  if p_session_date is null then
    raise exception using errcode = 'NS075', message = 'Session date is required.';
  end if;

  v_assignment := nano_internal.require_active_teacher_assignment(p_assignment_id);

  select coalesce(smp.attendance_mode, 'daily') into v_mode
  from public.school_marks_policies smp
  where smp.school_id = v_assignment.school_id;
  if v_mode is null then
    v_mode := 'daily';
  end if;
  if v_mode = 'daily' then
    v_period := 'daily';
  end if;

  select * into v_session
  from public.attendance_sessions s
  where s.teacher_assignment_id = v_assignment.id
    and s.session_date = p_session_date
    and s.period_key = v_period;

  if found then
    select coalesce(jsonb_agg(jsonb_build_object(
      'id', c.id,
      'session_id', c.session_id,
      'student_user_id', c.student_user_id,
      'display_name', coalesce(p.display_name, ''),
      'previous_status', c.previous_status::text,
      'new_status', c.new_status::text,
      'reason', c.reason,
      'corrected_by', c.corrected_by,
      'corrected_by_name', coalesce(actor.display_name, ''),
      'corrected_at', c.corrected_at,
      'revision_before', c.revision_before,
      'revision_after', c.revision_after
    ) order by c.corrected_at desc, c.id), '[]'::jsonb)
    into v_rows
    from public.attendance_corrections c
    left join public.profiles p on p.id = c.student_user_id
    left join public.profiles actor on actor.id = c.corrected_by
    where c.session_id = v_session.id;
  end if;

  return jsonb_build_object(
    'assignment_id', v_assignment.id,
    'session_id', v_session.id,
    'session_date', p_session_date,
    'period_key', v_period,
    'corrections', v_rows,
    'generated_at', timezone('utc', now())
  );
end;
$fn$;

create or replace function public.teacher_attendance_correct(
  p_assignment_id uuid,
  p_session_date date,
  p_student_user_id uuid,
  p_new_status text,
  p_reason text,
  p_period_key text default 'daily'
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_assignment public.teacher_assignments%rowtype;
  v_period text := coalesce(nullif(btrim(p_period_key), ''), 'daily');
  v_mode text := 'daily';
  v_session public.attendance_sessions%rowtype;
  v_entry public.attendance_entries%rowtype;
  v_status text := lower(btrim(coalesce(p_new_status, '')));
  v_reason text := btrim(coalesce(p_reason, ''));
  v_revision_before integer;
  v_revision_after integer;
  v_correction_id uuid;
begin
  if p_session_date is null then
    raise exception using errcode = 'NS075', message = 'Session date is required.';
  end if;
  if p_student_user_id is null then
    raise exception using errcode = 'NS082', message = 'Student id is required.';
  end if;
  if v_reason = '' then
    raise exception using errcode = 'NS083', message = 'Correction reason is required.';
  end if;
  if v_status not in ('present', 'absent', 'late', 'leave', 'excused') then
    raise exception using errcode = 'NS077', message = 'Invalid attendance status.';
  end if;

  v_assignment := nano_internal.require_active_teacher_assignment(p_assignment_id);

  select coalesce(smp.attendance_mode, 'daily') into v_mode
  from public.school_marks_policies smp
  where smp.school_id = v_assignment.school_id;
  if v_mode is null then
    v_mode := 'daily';
  end if;
  if v_mode = 'daily' then
    v_period := 'daily';
  end if;

  select * into v_session
  from public.attendance_sessions s
  where s.teacher_assignment_id = v_assignment.id
    and s.session_date = p_session_date
    and s.period_key = v_period
  for update;

  if not found then
    raise exception using
      errcode = 'NS084',
      message = 'Attendance session not found for correction.';
  end if;

  if v_session.status is distinct from 'submitted'::public.attendance_session_status then
    raise exception using
      errcode = 'NS085',
      message = 'Only submitted attendance can be corrected.';
  end if;

  if not exists (
    select 1
    from nano_internal.attendance_roster_for_assignment(v_assignment) r
    where r.student_user_id = p_student_user_id
  ) then
    raise exception using
      errcode = 'NS080',
      message = 'Student is not on the assigned roster.';
  end if;

  select * into v_entry
  from public.attendance_entries e
  where e.session_id = v_session.id
    and e.student_user_id = p_student_user_id
  for update;

  if not found then
    raise exception using
      errcode = 'NS086',
      message = 'Attendance entry not found for student.';
  end if;

  if v_entry.status::text = v_status then
    raise exception using
      errcode = 'NS087',
      message = 'New status must differ from the current value.';
  end if;

  v_revision_before := v_session.revision;
  v_revision_after := v_revision_before + 1;

  insert into public.attendance_corrections (
    school_id, session_id, entry_id, student_user_id,
    previous_status, new_status, reason, corrected_by,
    revision_before, revision_after
  ) values (
    v_assignment.school_id, v_session.id, v_entry.id, p_student_user_id,
    v_entry.status, v_status::public.attendance_entry_status, v_reason, auth.uid(),
    v_revision_before, v_revision_after
  )
  returning id into v_correction_id;

  update public.attendance_entries e
  set status = v_status::public.attendance_entry_status,
      updated_at = timezone('utc', now())
  where e.id = v_entry.id;

  update public.attendance_sessions s
  set revision = v_revision_after,
      updated_at = timezone('utc', now())
  where s.id = v_session.id;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'teacher', v_assignment.school_id,
    'update'::public.audit_action_kind, 'attendance_correction', v_correction_id::text,
    jsonb_build_object(
      'session_id', v_session.id,
      'student_user_id', p_student_user_id,
      'previous_status', v_entry.status::text,
      'new_status', v_status,
      'reason', v_reason,
      'revision_before', v_revision_before,
      'revision_after', v_revision_after
    )
  );

  return jsonb_build_object(
    'corrected', true,
    'correction_id', v_correction_id,
    'grid', public.teacher_attendance_load(v_assignment.id, p_session_date, v_period),
    'history', public.teacher_attendance_history(v_assignment.id, p_session_date, v_period)
  );
end;
$fn$;

revoke all on function public.teacher_attendance_history(uuid, date, text) from public, anon;
grant execute on function public.teacher_attendance_history(uuid, date, text)
  to authenticated, service_role;

revoke all on function public.teacher_attendance_correct(uuid, date, uuid, text, text, text)
  from public, anon;
grant execute on function public.teacher_attendance_correct(uuid, date, uuid, text, text, text)
  to authenticated, service_role;

comment on table public.attendance_corrections is
  'ATT-03 immutable attendance correction history; prior statuses are never erased.';
comment on function public.teacher_attendance_correct(uuid, date, uuid, text, text, text) is
  'ATT-03 correct a submitted attendance entry with required reason; appends history.';
comment on function public.teacher_attendance_history(uuid, date, text) is
  'ATT-03 list correction history for an attendance session.';
