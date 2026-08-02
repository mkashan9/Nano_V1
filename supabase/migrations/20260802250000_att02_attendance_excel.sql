-- ATT-02: attendance Excel/CSV template, preview, and commit (same records as ATT-01).

create table if not exists public.attendance_import_jobs (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id),
  teacher_user_id uuid not null references public.profiles (id),
  teacher_assignment_id uuid not null references public.teacher_assignments (id),
  session_date date not null,
  period_key text not null default 'daily',
  status text not null default 'previewed'
    check (status in ('previewed', 'committed', 'failed')),
  idempotency_key text not null,
  ok_count integer not null default 0,
  fail_count integer not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  committed_at timestamptz,
  constraint attendance_import_jobs_idempotency_nonempty check (btrim(idempotency_key) <> '')
);

create unique index if not exists attendance_import_jobs_idempotency_uidx
  on public.attendance_import_jobs (school_id, idempotency_key);

create table if not exists public.attendance_import_rows (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.attendance_import_jobs (id) on delete cascade,
  row_number integer not null,
  student_user_id text,
  status_text text,
  ok boolean not null default false,
  error_message text,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists attendance_import_rows_job_idx
  on public.attendance_import_rows (job_id);

alter table public.attendance_import_jobs enable row level security;
alter table public.attendance_import_rows enable row level security;

revoke all on table public.attendance_import_jobs from public, anon, authenticated;
revoke all on table public.attendance_import_rows from public, anon, authenticated;
grant select, insert, update, delete on table public.attendance_import_jobs to service_role;
grant select, insert, update, delete on table public.attendance_import_rows to service_role;

create or replace function public.teacher_attendance_template(
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
  v_load jsonb;
  v_rows jsonb := '[]'::jsonb;
begin
  v_load := public.teacher_attendance_load(p_assignment_id, p_session_date, p_period_key);

  select coalesce(jsonb_agg(jsonb_build_object(
    'student_user_id', r->>'id',
    'display_name', coalesce(r->>'display_name', ''),
    'status', coalesce(
      (
        select e->>'status'
        from jsonb_array_elements(coalesce(v_load->'entries', '[]'::jsonb)) e
        where e->>'student_user_id' = r->>'id'
        limit 1
      ),
      'present'
    )
  ) order by coalesce(r->>'display_name', '')), '[]'::jsonb)
  into v_rows
  from jsonb_array_elements(coalesce(v_load->'roster', '[]'::jsonb)) r;

  return jsonb_build_object(
    'assignment_id', v_load->>'assignment_id',
    'session_date', v_load->>'session_date',
    'period_key', v_load->>'period_key',
    'class_label', v_load->>'class_label',
    'subject_code', v_load->>'subject_code',
    'headers', jsonb_build_array('student_user_id', 'display_name', 'status'),
    'rows', v_rows,
    'generated_at', timezone('utc', now())
  );
end;
$fn$;

revoke all on function public.teacher_attendance_template(uuid, date, text)
  from public, anon;
grant execute on function public.teacher_attendance_template(uuid, date, text)
  to authenticated, service_role;

create or replace function public.preview_attendance_import(
  p_assignment_id uuid,
  p_session_date date,
  p_idempotency_key text,
  p_rows jsonb,
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
  v_roster_ids uuid[];
  v_row jsonb;
  v_idx int := 0;
  v_student_text text;
  v_student uuid;
  v_status text;
  v_ok jsonb := '[]'::jsonb;
  v_fail jsonb := '[]'::jsonb;
  v_job_id uuid;
  v_existing public.attendance_sessions%rowtype;
begin
  if p_session_date is null then
    raise exception using errcode = 'NS075', message = 'Session date is required.';
  end if;
  if v_key = '' then
    raise exception using errcode = 'NS076', message = 'Idempotency key is required.';
  end if;
  if p_rows is null or jsonb_typeof(p_rows) <> 'array' then
    raise exception using errcode = 'NS077', message = 'Rows array is required.';
  end if;

  v_assignment := nano_internal.require_active_teacher_assignment(p_assignment_id);

  select coalesce(smp.attendance_mode, 'daily') into v_mode
  from public.school_marks_policies smp
  where smp.school_id = v_assignment.school_id;
  if v_mode is null then v_mode := 'daily'; end if;
  if v_mode = 'daily' then v_period := 'daily'; end if;

  select * into v_existing
  from public.attendance_sessions s
  where s.teacher_assignment_id = v_assignment.id
    and s.session_date = p_session_date
    and s.period_key = v_period;

  if found
     and v_existing.status = 'submitted'::public.attendance_session_status
     and v_existing.idempotency_key is distinct from v_key then
    raise exception using
      errcode = 'NS079',
      message = 'Attendance already submitted for this scope and date.';
  end if;

  select coalesce(array_agg(r.student_user_id), '{}'::uuid[])
  into v_roster_ids
  from nano_internal.attendance_roster_for_assignment(v_assignment) r;

  for v_row in select value from jsonb_array_elements(p_rows) as t(value)
  loop
    v_idx := v_idx + 1;
    v_student_text := btrim(coalesce(v_row->>'student_user_id', ''));
    v_status := lower(btrim(coalesce(v_row->>'status', '')));

    begin
      v_student := v_student_text::uuid;
    exception
      when others then
        v_fail := v_fail || jsonb_build_array(jsonb_build_object(
          'row', v_idx,
          'student_user_id', v_student_text,
          'error', 'student_user_id must be a stable UUID'
        ));
        continue;
    end;

    if v_status not in ('present', 'absent', 'late', 'leave', 'excused') then
      v_fail := v_fail || jsonb_build_array(jsonb_build_object(
        'row', v_idx,
        'student_user_id', v_student_text,
        'error', 'invalid status'
      ));
      continue;
    end if;

    if not (v_student = any (v_roster_ids)) then
      v_fail := v_fail || jsonb_build_array(jsonb_build_object(
        'row', v_idx,
        'student_user_id', v_student_text,
        'error', 'student not on assigned roster'
      ));
      continue;
    end if;

    v_ok := v_ok || jsonb_build_array(jsonb_build_object(
      'row', v_idx,
      'student_user_id', v_student,
      'status', v_status
    ));
  end loop;

  insert into public.attendance_import_jobs (
    school_id, teacher_user_id, teacher_assignment_id,
    session_date, period_key, status, idempotency_key,
    ok_count, fail_count
  ) values (
    v_assignment.school_id, auth.uid(), v_assignment.id,
    p_session_date, v_period, 'previewed', v_key,
    coalesce(jsonb_array_length(v_ok), 0),
    coalesce(jsonb_array_length(v_fail), 0)
  )
  on conflict (school_id, idempotency_key) do update
    set ok_count = excluded.ok_count,
        fail_count = excluded.fail_count,
        status = 'previewed',
        teacher_assignment_id = excluded.teacher_assignment_id,
        session_date = excluded.session_date,
        period_key = excluded.period_key
  returning id into v_job_id;

  delete from public.attendance_import_rows where job_id = v_job_id;

  insert into public.attendance_import_rows (job_id, row_number, student_user_id, status_text, ok, error_message)
  select v_job_id, (r->>'row')::int, r->>'student_user_id', r->>'status', true, null
  from jsonb_array_elements(v_ok) r;

  insert into public.attendance_import_rows (job_id, row_number, student_user_id, status_text, ok, error_message)
  select v_job_id, (r->>'row')::int, r->>'student_user_id', null, false, r->>'error'
  from jsonb_array_elements(v_fail) r;

  return jsonb_build_object(
    'job_id', v_job_id,
    'assignment_id', v_assignment.id,
    'session_date', p_session_date,
    'period_key', v_period,
    'ok_count', coalesce(jsonb_array_length(v_ok), 0),
    'fail_count', coalesce(jsonb_array_length(v_fail), 0),
    'ok_rows', v_ok,
    'failed_rows', v_fail,
    'can_commit', coalesce(jsonb_array_length(v_fail), 0) = 0
      and coalesce(jsonb_array_length(v_ok), 0) > 0
  );
end;
$fn$;

revoke all on function public.preview_attendance_import(uuid, date, text, jsonb, text)
  from public, anon;
grant execute on function public.preview_attendance_import(uuid, date, text, jsonb, text)
  to authenticated, service_role;

create or replace function public.commit_attendance_import(
  p_assignment_id uuid,
  p_session_date date,
  p_idempotency_key text,
  p_rows jsonb,
  p_period_key text default 'daily'
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_preview jsonb;
  v_entries jsonb := '[]'::jsonb;
  v_grid jsonb;
  v_job_id uuid;
begin
  v_preview := public.preview_attendance_import(
    p_assignment_id, p_session_date, p_idempotency_key, p_rows, p_period_key
  );

  if coalesce((v_preview->>'can_commit')::boolean, false) is not true then
    raise exception using
      errcode = 'NS081',
      message = 'Attendance import has validation errors.';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'student_user_id', r->>'student_user_id',
    'status', r->>'status'
  )), '[]'::jsonb)
  into v_entries
  from jsonb_array_elements(coalesce(v_preview->'ok_rows', '[]'::jsonb)) r;

  v_grid := public.teacher_attendance_submit(
    p_assignment_id,
    p_session_date,
    p_idempotency_key,
    v_entries,
    coalesce(v_preview->>'period_key', p_period_key)
  );

  v_job_id := (v_preview->>'job_id')::uuid;
  update public.attendance_import_jobs
  set status = 'committed',
      committed_at = timezone('utc', now())
  where id = v_job_id;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'teacher', (v_grid->>'school_id')::uuid,
    'create'::public.audit_action_kind, 'attendance_import', v_job_id::text,
    jsonb_build_object(
      'assignment_id', p_assignment_id,
      'session_date', p_session_date,
      'ok_count', v_preview->'ok_count',
      'idempotency_key', p_idempotency_key
    )
  );

  return jsonb_build_object(
    'committed', true,
    'message', 'Attendance import committed.',
    'preview', v_preview,
    'grid', v_grid
  );
end;
$fn$;

revoke all on function public.commit_attendance_import(uuid, date, text, jsonb, text)
  from public, anon;
grant execute on function public.commit_attendance_import(uuid, date, text, jsonb, text)
  to authenticated, service_role;

comment on table public.attendance_import_jobs is
  'ATT-02 attendance CSV/Excel import jobs.';
comment on table public.attendance_import_rows is
  'ATT-02 per-row preview outcomes for attendance imports.';
comment on function public.teacher_attendance_template(uuid, date, text) is
  'ATT-02 prefilled attendance template rows (stable student ids).';
comment on function public.preview_attendance_import(uuid, date, text, jsonb, text) is
  'ATT-02 validate attendance import rows against assigned roster.';
comment on function public.commit_attendance_import(uuid, date, text, jsonb, text) is
  'ATT-02 commit validated import into canonical attendance_sessions/entries.';
