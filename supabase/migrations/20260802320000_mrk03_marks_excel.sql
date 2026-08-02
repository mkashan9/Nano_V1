-- MRK-03: marks CSV/Excel-compatible template, preview, and commit (same as MRK-02 grid).

create table if not exists public.marks_import_jobs (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id),
  teacher_user_id uuid not null references public.profiles (id),
  assessment_id uuid not null references public.assessments (id),
  status text not null default 'previewed'
    check (status in ('previewed', 'committed', 'failed')),
  idempotency_key text not null,
  ok_count integer not null default 0,
  fail_count integer not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  committed_at timestamptz,
  constraint marks_import_jobs_idempotency_nonempty check (btrim(idempotency_key) <> '')
);

create unique index if not exists marks_import_jobs_idempotency_uidx
  on public.marks_import_jobs (school_id, idempotency_key);

create table if not exists public.marks_import_rows (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.marks_import_jobs (id) on delete cascade,
  row_number integer not null,
  student_user_id text,
  status_text text,
  obtained_text text,
  ok boolean not null default false,
  error_message text,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists marks_import_rows_job_idx
  on public.marks_import_rows (job_id);

alter table public.marks_import_jobs enable row level security;
alter table public.marks_import_rows enable row level security;

revoke all on table public.marks_import_jobs from public, anon, authenticated;
revoke all on table public.marks_import_rows from public, anon, authenticated;
grant select, insert, update, delete on table public.marks_import_jobs to service_role;
grant select, insert, update, delete on table public.marks_import_rows to service_role;

create or replace function public.teacher_marks_template(p_assessment_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_load jsonb;
  v_rows jsonb := '[]'::jsonb;
begin
  v_load := public.teacher_marks_load(p_assessment_id);

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
      'not_submitted'
    ),
    'obtained_marks', coalesce(
      (
        select e->>'obtained_marks'
        from jsonb_array_elements(coalesce(v_load->'entries', '[]'::jsonb)) e
        where e->>'student_user_id' = r->>'id'
        limit 1
      ),
      ''
    ),
    'remarks', coalesce(
      (
        select e->>'remarks'
        from jsonb_array_elements(coalesce(v_load->'entries', '[]'::jsonb)) e
        where e->>'student_user_id' = r->>'id'
        limit 1
      ),
      ''
    )
  ) order by coalesce(r->>'display_name', '')), '[]'::jsonb)
  into v_rows
  from jsonb_array_elements(coalesce(v_load->'roster', '[]'::jsonb)) r;

  return jsonb_build_object(
    'assessment_id', v_load->>'assessment_id',
    'assignment_id', v_load->>'assignment_id',
    'assessment_name', v_load->>'assessment_name',
    'total_marks', v_load->'total_marks',
    'class_label', v_load->>'class_label',
    'subject_code', v_load->>'subject_code',
    'headers', jsonb_build_array(
      'student_user_id', 'display_name', 'status', 'obtained_marks', 'remarks'
    ),
    'rows', v_rows,
    'generated_at', timezone('utc', now())
  );
end;
$fn$;

create or replace function public.preview_marks_import(
  p_assessment_id uuid,
  p_idempotency_key text,
  p_rows jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_load jsonb;
  v_assessment_id uuid;
  v_school_id uuid;
  v_total numeric;
  v_allow_bonus boolean := false;
  v_key text := btrim(coalesce(p_idempotency_key, ''));
  v_roster_ids uuid[];
  v_row jsonb;
  v_idx int := 0;
  v_student_text text;
  v_student uuid;
  v_status text;
  v_obtained_text text;
  v_obtained numeric;
  v_ok jsonb := '[]'::jsonb;
  v_fail jsonb := '[]'::jsonb;
  v_job_id uuid;
begin
  if v_key = '' then
    raise exception using errcode = 'NS076', message = 'Idempotency key is required.';
  end if;
  if p_rows is null or jsonb_typeof(p_rows) <> 'array' then
    raise exception using errcode = 'NS100', message = 'Rows array is required.';
  end if;

  v_load := public.teacher_marks_load(p_assessment_id);
  if (v_load->>'assessment_status') is distinct from 'draft' then
    raise exception using
      errcode = 'NS101',
      message = 'Marks can only be imported on draft assessments.';
  end if;

  v_assessment_id := (v_load->>'assessment_id')::uuid;
  v_school_id := (v_load->>'school_id')::uuid;
  v_total := (v_load->>'total_marks')::numeric;
  v_allow_bonus := coalesce((v_load->>'allow_bonus')::boolean, false);

  select coalesce(array_agg((r->>'id')::uuid), '{}'::uuid[])
  into v_roster_ids
  from jsonb_array_elements(coalesce(v_load->'roster', '[]'::jsonb)) r;

  for v_row in select value from jsonb_array_elements(p_rows) as t(value)
  loop
    v_idx := v_idx + 1;
    v_student_text := btrim(coalesce(v_row->>'student_user_id', ''));
    v_status := lower(btrim(coalesce(v_row->>'status', '')));
    v_obtained_text := btrim(coalesce(v_row->>'obtained_marks', ''));

    begin
      v_student := v_student_text::uuid;
    exception
      when others then
        v_fail := v_fail || jsonb_build_array(jsonb_build_object(
          'row', v_idx,
          'student_user_id', v_student_text,
          'error', 'invalid student_user_id'
        ));
        continue;
    end;

    if not (v_student = any (v_roster_ids)) then
      v_fail := v_fail || jsonb_build_array(jsonb_build_object(
        'row', v_idx,
        'student_user_id', v_student_text,
        'error', 'student not on assigned roster'
      ));
      continue;
    end if;

    if v_status not in ('scored', 'absent', 'exempt', 'not_submitted') then
      v_fail := v_fail || jsonb_build_array(jsonb_build_object(
        'row', v_idx,
        'student_user_id', v_student_text,
        'error', 'invalid status'
      ));
      continue;
    end if;

    if v_status = 'scored' then
      if v_obtained_text = '' then
        v_fail := v_fail || jsonb_build_array(jsonb_build_object(
          'row', v_idx,
          'student_user_id', v_student_text,
          'error', 'obtained_marks required for scored'
        ));
        continue;
      end if;
      begin
        v_obtained := v_obtained_text::numeric;
      exception
        when others then
          v_fail := v_fail || jsonb_build_array(jsonb_build_object(
            'row', v_idx,
            'student_user_id', v_student_text,
            'error', 'invalid obtained_marks'
          ));
          continue;
      end;
      if v_obtained < 0 then
        v_fail := v_fail || jsonb_build_array(jsonb_build_object(
          'row', v_idx,
          'student_user_id', v_student_text,
          'error', 'obtained_marks cannot be negative'
        ));
        continue;
      end if;
      if v_obtained > v_total and not v_allow_bonus then
        v_fail := v_fail || jsonb_build_array(jsonb_build_object(
          'row', v_idx,
          'student_user_id', v_student_text,
          'error', 'obtained_marks exceeds total'
        ));
        continue;
      end if;
    else
      v_obtained := null;
    end if;

    v_ok := v_ok || jsonb_build_array(jsonb_build_object(
      'row', v_idx,
      'student_user_id', v_student,
      'status', v_status,
      'obtained_marks', v_obtained,
      'remarks', coalesce(v_row->>'remarks', '')
    ));
  end loop;

  insert into public.marks_import_jobs (
    school_id, teacher_user_id, assessment_id,
    status, idempotency_key, ok_count, fail_count
  ) values (
    v_school_id, auth.uid(), v_assessment_id,
    'previewed', v_key,
    coalesce(jsonb_array_length(v_ok), 0),
    coalesce(jsonb_array_length(v_fail), 0)
  )
  on conflict (school_id, idempotency_key) do update
    set ok_count = excluded.ok_count,
        fail_count = excluded.fail_count,
        status = 'previewed',
        assessment_id = excluded.assessment_id
  returning id into v_job_id;

  delete from public.marks_import_rows where job_id = v_job_id;

  insert into public.marks_import_rows (
    job_id, row_number, student_user_id, status_text, obtained_text, ok, error_message
  )
  select v_job_id, (r->>'row')::int, r->>'student_user_id', r->>'status',
         r->>'obtained_marks', true, null
  from jsonb_array_elements(v_ok) r;

  insert into public.marks_import_rows (
    job_id, row_number, student_user_id, status_text, obtained_text, ok, error_message
  )
  select v_job_id, (r->>'row')::int, r->>'student_user_id', null, null, false, r->>'error'
  from jsonb_array_elements(v_fail) r;

  return jsonb_build_object(
    'job_id', v_job_id,
    'assessment_id', v_assessment_id,
    'ok_count', coalesce(jsonb_array_length(v_ok), 0),
    'fail_count', coalesce(jsonb_array_length(v_fail), 0),
    'ok_rows', v_ok,
    'failed_rows', v_fail,
    'can_commit', coalesce(jsonb_array_length(v_fail), 0) = 0
      and coalesce(jsonb_array_length(v_ok), 0) > 0
  );
end;
$fn$;

create or replace function public.commit_marks_import(
  p_assessment_id uuid,
  p_idempotency_key text,
  p_rows jsonb
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
  v_preview := public.preview_marks_import(
    p_assessment_id, p_idempotency_key, p_rows
  );

  if coalesce((v_preview->>'can_commit')::boolean, false) is not true then
    raise exception using
      errcode = 'NS104',
      message = 'Marks import has validation errors.';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'student_user_id', r->>'student_user_id',
    'status', r->>'status',
    'obtained_marks', r->'obtained_marks',
    'remarks', coalesce(r->>'remarks', '')
  )), '[]'::jsonb)
  into v_entries
  from jsonb_array_elements(coalesce(v_preview->'ok_rows', '[]'::jsonb)) r;

  v_grid := public.teacher_marks_save(
    p_assessment_id,
    v_entries,
    p_idempotency_key
  );

  v_job_id := (v_preview->>'job_id')::uuid;
  update public.marks_import_jobs
  set status = 'committed',
      committed_at = timezone('utc', now())
  where id = v_job_id;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'teacher', (v_grid->>'school_id')::uuid,
    'create'::public.audit_action_kind, 'marks_import', v_job_id::text,
    jsonb_build_object(
      'assessment_id', p_assessment_id,
      'ok_count', v_preview->'ok_count',
      'idempotency_key', p_idempotency_key
    )
  );

  return jsonb_build_object(
    'committed', true,
    'message', 'Marks import committed.',
    'preview', v_preview,
    'grid', v_grid
  );
end;
$fn$;

revoke all on function public.teacher_marks_template(uuid) from public, anon;
grant execute on function public.teacher_marks_template(uuid)
  to authenticated, service_role;

revoke all on function public.preview_marks_import(uuid, text, jsonb) from public, anon;
grant execute on function public.preview_marks_import(uuid, text, jsonb)
  to authenticated, service_role;

revoke all on function public.commit_marks_import(uuid, text, jsonb) from public, anon;
grant execute on function public.commit_marks_import(uuid, text, jsonb)
  to authenticated, service_role;

comment on table public.marks_import_jobs is
  'MRK-03 marks CSV/Excel import jobs.';
comment on table public.marks_import_rows is
  'MRK-03 per-row preview outcomes for marks imports.';
comment on function public.teacher_marks_template(uuid) is
  'MRK-03 prefilled marks template rows (stable student ids).';
comment on function public.preview_marks_import(uuid, text, jsonb) is
  'MRK-03 validate marks import rows against assessment roster.';
comment on function public.commit_marks_import(uuid, text, jsonb) is
  'MRK-03 commit validated import into canonical marks_entries.';
