-- ATT-01: in-app attendance grid (sessions + entries). Excel → ATT-02. Corrections → ATT-03.

do $$
begin
  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'attendance_entry_status'
  ) then
    create type public.attendance_entry_status as enum (
      'present', 'absent', 'late', 'leave', 'excused'
    );
  end if;

  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'attendance_session_status'
  ) then
    create type public.attendance_session_status as enum ('draft', 'submitted');
  end if;
end $$;

create table if not exists public.attendance_sessions (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id),
  teacher_assignment_id uuid not null references public.teacher_assignments (id),
  teacher_user_id uuid not null references public.profiles (id),
  session_date date not null,
  period_key text not null default 'daily',
  status public.attendance_session_status not null default 'draft',
  idempotency_key text not null,
  revision integer not null default 1,
  submitted_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint attendance_sessions_period_key_nonempty check (btrim(period_key) <> ''),
  constraint attendance_sessions_idempotency_nonempty check (btrim(idempotency_key) <> '')
);

create unique index if not exists attendance_sessions_scope_uidx
  on public.attendance_sessions (teacher_assignment_id, session_date, period_key);

create unique index if not exists attendance_sessions_idempotency_uidx
  on public.attendance_sessions (school_id, idempotency_key);

create table if not exists public.attendance_entries (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.attendance_sessions (id) on delete cascade,
  student_user_id uuid not null references public.profiles (id),
  status public.attendance_entry_status not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint attendance_entries_session_student_uidx unique (session_id, student_user_id)
);

create index if not exists attendance_entries_session_idx
  on public.attendance_entries (session_id);

alter table public.attendance_sessions enable row level security;
alter table public.attendance_entries enable row level security;

-- Reads/writes go through SECURITY DEFINER RPCs only.
revoke all on table public.attendance_sessions from public, anon, authenticated;
revoke all on table public.attendance_entries from public, anon, authenticated;
grant select, insert, update, delete on table public.attendance_sessions to service_role;
grant select, insert, update, delete on table public.attendance_entries to service_role;

create or replace function nano_internal.require_active_teacher_assignment(
  p_assignment_id uuid
)
returns public.teacher_assignments
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_school_id uuid;
  v_row public.teacher_assignments%rowtype;
begin
  if p_assignment_id is null then
    raise exception using errcode = 'NS073', message = 'Assignment id is required.';
  end if;

  v_school_id := nano_internal.require_teacher_school_id();

  select * into v_row
  from public.teacher_assignments ta
  where ta.id = p_assignment_id
    and ta.school_id = v_school_id
    and ta.teacher_user_id = auth.uid()
    and ta.status = 'active'::public.membership_status
    and (ta.ends_on is null or ta.ends_on >= timezone('utc', now())::date)
    and ta.starts_on <= timezone('utc', now())::date;

  if not found then
    raise exception using
      errcode = 'NS074',
      message = 'Assignment is not in your active scope.';
  end if;

  return v_row;
end;
$fn$;

revoke all on function nano_internal.require_active_teacher_assignment(uuid)
  from public, anon;
grant execute on function nano_internal.require_active_teacher_assignment(uuid)
  to authenticated, service_role;

create or replace function nano_internal.attendance_roster_for_assignment(
  p_assignment public.teacher_assignments
)
returns table (
  student_user_id uuid,
  display_name text
)
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_class_id uuid;
begin
  if p_assignment.class_id is not null then
    v_class_id := p_assignment.class_id;
  else
    select c.id into v_class_id
    from public.classes c
    where c.school_id = p_assignment.school_id
      and lower(c.name) = lower(p_assignment.class_label)
    order by c.created_at
    limit 1;
  end if;

  if v_class_id is null then
    return;
  end if;

  return query
  select
    se.student_user_id,
    coalesce(p.display_name, '') as display_name
  from public.student_enrollments se
  join public.profiles p on p.id = se.student_user_id
  join public.school_memberships sm
    on sm.user_id = se.student_user_id
   and sm.school_id = se.school_id
   and sm.role = 'student'::public.membership_role
   and sm.status = 'active'::public.membership_status
  where se.school_id = p_assignment.school_id
    and se.class_id = v_class_id
    and se.status = 'active'::public.membership_status
  order by coalesce(p.display_name, '');
end;
$fn$;

revoke all on function nano_internal.attendance_roster_for_assignment(public.teacher_assignments)
  from public, anon;
grant execute on function nano_internal.attendance_roster_for_assignment(public.teacher_assignments)
  to authenticated, service_role;

create or replace function public.teacher_attendance_load(
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
  v_session public.attendance_sessions%rowtype;
  v_roster jsonb;
  v_entries jsonb := '[]'::jsonb;
  v_mode text := 'daily';
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

  select coalesce(jsonb_agg(jsonb_build_object(
    'id', r.student_user_id,
    'display_name', r.display_name
  ) order by r.display_name), '[]'::jsonb)
  into v_roster
  from nano_internal.attendance_roster_for_assignment(v_assignment) r;

  select * into v_session
  from public.attendance_sessions s
  where s.teacher_assignment_id = v_assignment.id
    and s.session_date = p_session_date
    and s.period_key = v_period;

  if found then
    select coalesce(jsonb_agg(jsonb_build_object(
      'student_user_id', e.student_user_id,
      'status', e.status::text
    ) order by e.student_user_id::text), '[]'::jsonb)
    into v_entries
    from public.attendance_entries e
    where e.session_id = v_session.id;
  end if;

  return jsonb_build_object(
    'assignment_id', v_assignment.id,
    'school_id', v_assignment.school_id,
    'session_date', p_session_date,
    'period_key', v_period,
    'attendance_mode', v_mode,
    'class_label', coalesce(
      (select c.name from public.classes c where c.id = v_assignment.class_id),
      v_assignment.class_label
    ),
    'subject_code', coalesce(
      (select ss.code from public.school_subjects ss where ss.id = v_assignment.school_subject_id),
      v_assignment.subject_code
    ),
    'session', case when v_session.id is null then null else jsonb_build_object(
      'id', v_session.id,
      'status', v_session.status::text,
      'revision', v_session.revision,
      'idempotency_key', v_session.idempotency_key,
      'submitted_at', v_session.submitted_at
    ) end,
    'roster', v_roster,
    'entries', v_entries,
    'generated_at', timezone('utc', now())
  );
end;
$fn$;

revoke all on function public.teacher_attendance_load(uuid, date, text) from public, anon;
grant execute on function public.teacher_attendance_load(uuid, date, text)
  to authenticated, service_role;

create or replace function public.teacher_attendance_submit(
  p_assignment_id uuid,
  p_session_date date,
  p_idempotency_key text,
  p_entries jsonb,
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
  v_key text := btrim(coalesce(p_idempotency_key, ''));
  v_mode text := 'daily';
  v_session public.attendance_sessions%rowtype;
  v_existing_by_key public.attendance_sessions%rowtype;
  v_entry jsonb;
  v_student uuid;
  v_status text;
  v_roster_ids uuid[];
  v_has_session boolean := false;
begin
  if p_session_date is null then
    raise exception using errcode = 'NS075', message = 'Session date is required.';
  end if;
  if v_key = '' then
    raise exception using errcode = 'NS076', message = 'Idempotency key is required.';
  end if;
  if p_entries is null or jsonb_typeof(p_entries) <> 'array' then
    raise exception using errcode = 'NS077', message = 'Entries array is required.';
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

  select * into v_existing_by_key
  from public.attendance_sessions s
  where s.school_id = v_assignment.school_id
    and s.idempotency_key = v_key;

  if found then
    if v_existing_by_key.teacher_assignment_id is distinct from v_assignment.id
       or v_existing_by_key.session_date is distinct from p_session_date
       or v_existing_by_key.period_key is distinct from v_period then
      raise exception using
        errcode = 'NS078',
        message = 'Idempotency key already used for another attendance session.';
    end if;
    return public.teacher_attendance_load(v_assignment.id, p_session_date, v_period);
  end if;

  select * into v_session
  from public.attendance_sessions s
  where s.teacher_assignment_id = v_assignment.id
    and s.session_date = p_session_date
    and s.period_key = v_period
  for update;

  if found then
    v_has_session := true;
    if v_session.status = 'submitted'::public.attendance_session_status then
      raise exception using
        errcode = 'NS079',
        message = 'Attendance already submitted for this scope and date.';
    end if;
  end if;

  select coalesce(array_agg(r.student_user_id), '{}'::uuid[])
  into v_roster_ids
  from nano_internal.attendance_roster_for_assignment(v_assignment) r;

  for v_entry in select value from jsonb_array_elements(p_entries) as t(value)
  loop
    begin
      v_student := (v_entry->>'student_user_id')::uuid;
    exception
      when others then
        raise exception using errcode = 'NS077', message = 'Invalid student_user_id in entries.';
    end;
    v_status := lower(btrim(coalesce(v_entry->>'status', '')));
    if v_status not in ('present', 'absent', 'late', 'leave', 'excused') then
      raise exception using errcode = 'NS077', message = 'Invalid attendance status.';
    end if;
    if not (v_student = any (v_roster_ids)) then
      raise exception using errcode = 'NS080', message = 'Student is not on the assigned roster.';
    end if;
  end loop;

  if not v_has_session then
    insert into public.attendance_sessions (
      school_id, teacher_assignment_id, teacher_user_id,
      session_date, period_key, status, idempotency_key,
      revision, submitted_at
    ) values (
      v_assignment.school_id, v_assignment.id, auth.uid(),
      p_session_date, v_period, 'submitted'::public.attendance_session_status, v_key,
      1, timezone('utc', now())
    )
    returning * into v_session;
  else
    update public.attendance_sessions s
    set status = 'submitted'::public.attendance_session_status,
        idempotency_key = v_key,
        revision = s.revision + 1,
        submitted_at = timezone('utc', now()),
        updated_at = timezone('utc', now())
    where s.id = v_session.id
    returning * into v_session;
    delete from public.attendance_entries e where e.session_id = v_session.id;
  end if;

  for v_entry in select value from jsonb_array_elements(p_entries) as t(value)
  loop
    insert into public.attendance_entries (session_id, student_user_id, status)
    values (
      v_session.id,
      (v_entry->>'student_user_id')::uuid,
      (lower(btrim(v_entry->>'status')))::public.attendance_entry_status
    );
  end loop;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'teacher', v_assignment.school_id,
    'create'::public.audit_action_kind, 'attendance_session', v_session.id::text,
    jsonb_build_object(
      'assignment_id', v_assignment.id,
      'session_date', p_session_date,
      'period_key', v_period,
      'entry_count', jsonb_array_length(p_entries),
      'idempotency_key', v_key
    )
  );

  return public.teacher_attendance_load(v_assignment.id, p_session_date, v_period);
end;
$fn$;

revoke all on function public.teacher_attendance_submit(uuid, date, text, jsonb, text)
  from public, anon;
grant execute on function public.teacher_attendance_submit(uuid, date, text, jsonb, text)
  to authenticated, service_role;

-- Refresh TCH-01 pending attendance count from unsubmitted scopes for today.
create or replace function public.teacher_dashboard()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_school_id uuid;
  v_teacher_id uuid := auth.uid();
  v_school public.schools%rowtype;
  v_profile public.profiles%rowtype;
  v_assignments jsonb;
  v_active_count int := 0;
  v_pending_attendance int := 0;
begin
  v_school_id := nano_internal.require_teacher_school_id();

  select * into v_school from public.schools where id = v_school_id;
  select * into v_profile from public.profiles where id = v_teacher_id;

  select coalesce(jsonb_agg(row_to_json(a)::jsonb order by a.class_label, a.subject_code), '[]'::jsonb)
  into v_assignments
  from (
    select
      ta.id,
      ta.class_id,
      ta.section_id,
      ta.school_subject_id,
      coalesce(c.name, ta.class_label) as class_label,
      coalesce(sec.name, '') as section_name,
      coalesce(ss.code, ta.subject_code) as subject_code,
      coalesce(ss.name, ta.subject_code) as subject_name,
      ta.status::text as status,
      ta.starts_on,
      ta.ends_on
    from public.teacher_assignments ta
    left join public.classes c on c.id = ta.class_id
    left join public.sections sec on sec.id = ta.section_id
    left join public.school_subjects ss on ss.id = ta.school_subject_id
    where ta.school_id = v_school_id
      and ta.teacher_user_id = v_teacher_id
      and ta.status = 'active'::public.membership_status
      and (ta.ends_on is null or ta.ends_on >= timezone('utc', now())::date)
      and ta.starts_on <= timezone('utc', now())::date
  ) a;

  v_active_count := coalesce(jsonb_array_length(v_assignments), 0);

  select count(*)::int into v_pending_attendance
  from public.teacher_assignments ta
  where ta.school_id = v_school_id
    and ta.teacher_user_id = v_teacher_id
    and ta.status = 'active'::public.membership_status
    and (ta.ends_on is null or ta.ends_on >= timezone('utc', now())::date)
    and ta.starts_on <= timezone('utc', now())::date
    and not exists (
      select 1
      from public.attendance_sessions s
      where s.teacher_assignment_id = ta.id
        and s.session_date = timezone('utc', now())::date
        and s.period_key = 'daily'
        and s.status = 'submitted'::public.attendance_session_status
    );

  return jsonb_build_object(
    'school_id', v_school_id,
    'school_code', v_school.code,
    'school_name', coalesce(nullif(btrim(v_school.display_name), ''), v_school.name),
    'teacher_id', v_teacher_id,
    'teacher_name', coalesce(v_profile.display_name, ''),
    'active_assignment_count', v_active_count,
    'pending_attendance_count', coalesce(v_pending_attendance, 0),
    'draft_assessment_count', 0,
    'unpublished_marks_count', 0,
    'recent_classroom_count', 0,
    'assignments', v_assignments,
    'generated_at', timezone('utc', now())
  );
end;
$fn$;

comment on table public.attendance_sessions is
  'ATT-01 teacher attendance sessions (one per assignment/date/period).';
comment on table public.attendance_entries is
  'ATT-01 per-student attendance marks within a session.';
comment on function public.teacher_attendance_load(uuid, date, text) is
  'ATT-01 load roster + session for an active teacher assignment.';
comment on function public.teacher_attendance_submit(uuid, date, text, jsonb, text) is
  'ATT-01 submit attendance with idempotency; rejects duplicate submitted sessions.';
