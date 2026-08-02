-- MRK-04: publish draft assessments; correct published marks with immutable history.

alter table public.assessments
  add column if not exists revision integer not null default 1,
  add column if not exists published_at timestamptz,
  add column if not exists published_by uuid references public.profiles (id);

create table if not exists public.marks_corrections (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id),
  assessment_id uuid not null references public.assessments (id),
  entry_id uuid not null references public.marks_entries (id),
  student_user_id uuid not null references public.profiles (id),
  previous_status public.marks_entry_status not null,
  new_status public.marks_entry_status not null,
  previous_obtained_marks numeric(10,2),
  new_obtained_marks numeric(10,2),
  previous_remarks text not null default '',
  new_remarks text not null default '',
  reason text not null,
  corrected_by uuid not null references public.profiles (id),
  corrected_at timestamptz not null default timezone('utc', now()),
  revision_before integer not null,
  revision_after integer not null,
  constraint marks_corrections_reason_nonempty check (btrim(reason) <> ''),
  constraint marks_corrections_changed check (
    previous_status is distinct from new_status
    or previous_obtained_marks is distinct from new_obtained_marks
    or btrim(previous_remarks) is distinct from btrim(new_remarks)
  )
);

create index if not exists marks_corrections_assessment_idx
  on public.marks_corrections (assessment_id, corrected_at desc);

create index if not exists marks_corrections_student_idx
  on public.marks_corrections (assessment_id, student_user_id, corrected_at desc);

alter table public.marks_corrections enable row level security;

revoke all on table public.marks_corrections from public, anon, authenticated;
grant select, insert, update, delete on table public.marks_corrections to service_role;

create or replace function nano_internal.forbid_marks_correction_mutation()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $fn$
begin
  raise exception using
    errcode = 'NS105',
    message = 'Marks corrections are immutable.';
end;
$fn$;

drop trigger if exists marks_corrections_no_update on public.marks_corrections;
create trigger marks_corrections_no_update
  before update or delete on public.marks_corrections
  for each row
  execute function nano_internal.forbid_marks_correction_mutation();

create or replace function nano_internal.assert_assessment_period_open(
  p_assessment public.assessments
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $fn$
declare
  v_status text;
begin
  if p_assessment.result_period_id is null then
    return;
  end if;
  select rp.status into v_status
  from public.result_periods rp
  where rp.id = p_assessment.result_period_id;
  if v_status = 'closed' then
    raise exception using
      errcode = 'NS106',
      message = 'Result period is closed; privileged correction required.';
  end if;
end;
$fn$;

create or replace function public.teacher_marks_load(p_assessment_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_assessment public.assessments%rowtype;
  v_assignment public.teacher_assignments%rowtype;
  v_allow_bonus boolean := false;
  v_roster jsonb;
  v_entries jsonb := '[]'::jsonb;
begin
  if p_assessment_id is null then
    raise exception using errcode = 'NS096', message = 'Assessment id is required.';
  end if;

  select * into v_assessment
  from public.assessments a
  where a.id = p_assessment_id;

  if not found then
    raise exception using errcode = 'NS097', message = 'Assessment not found.';
  end if;

  if v_assessment.teacher_user_id is distinct from auth.uid() then
    raise exception using errcode = 'NS098', message = 'Assessment is not in your scope.';
  end if;

  v_assignment := nano_internal.require_active_teacher_assignment(
    v_assessment.teacher_assignment_id
  );

  select coalesce(smp.allow_bonus, false) into v_allow_bonus
  from public.school_marks_policies smp
  where smp.school_id = v_assignment.school_id;
  if v_allow_bonus is null then
    v_allow_bonus := false;
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'id', r.student_user_id,
    'display_name', r.display_name
  ) order by r.display_name), '[]'::jsonb)
  into v_roster
  from nano_internal.attendance_roster_for_assignment(v_assignment) r;

  select coalesce(jsonb_agg(jsonb_build_object(
    'student_user_id', e.student_user_id,
    'status', e.status::text,
    'obtained_marks', e.obtained_marks,
    'remarks', e.remarks
  ) order by e.student_user_id::text), '[]'::jsonb)
  into v_entries
  from public.marks_entries e
  where e.assessment_id = v_assessment.id;

  return jsonb_build_object(
    'assessment_id', v_assessment.id,
    'assignment_id', v_assignment.id,
    'school_id', v_assignment.school_id,
    'assessment_name', v_assessment.name,
    'category', v_assessment.category,
    'assessment_date', v_assessment.assessment_date,
    'total_marks', v_assessment.total_marks,
    'assessment_status', v_assessment.status::text,
    'revision', v_assessment.revision,
    'published_at', v_assessment.published_at,
    'allow_bonus', v_allow_bonus,
    'class_label', coalesce(
      (select c.name from public.classes c where c.id = v_assignment.class_id),
      v_assignment.class_label
    ),
    'subject_code', coalesce(
      (select ss.code from public.school_subjects ss where ss.id = v_assignment.school_subject_id),
      v_assignment.subject_code
    ),
    'roster', v_roster,
    'entries', v_entries,
    'generated_at', timezone('utc', now())
  );
end;
$fn$;

create or replace function public.teacher_marks_publish(
  p_assessment_id uuid,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_assessment public.assessments%rowtype;
  v_entry_count integer := 0;
begin
  if p_assessment_id is null then
    raise exception using errcode = 'NS096', message = 'Assessment id is required.';
  end if;

  select * into v_assessment
  from public.assessments a
  where a.id = p_assessment_id
  for update;

  if not found then
    raise exception using errcode = 'NS097', message = 'Assessment not found.';
  end if;

  if v_assessment.teacher_user_id is distinct from auth.uid() then
    raise exception using errcode = 'NS098', message = 'Assessment is not in your scope.';
  end if;

  perform nano_internal.require_active_teacher_assignment(
    v_assessment.teacher_assignment_id
  );
  perform nano_internal.assert_assessment_period_open(v_assessment);

  if v_assessment.status is distinct from 'draft'::public.assessment_status then
    raise exception using
      errcode = 'NS107',
      message = 'Only draft assessments can be published.';
  end if;

  select count(*) into v_entry_count
  from public.marks_entries e
  where e.assessment_id = v_assessment.id;

  if v_entry_count < 1 then
    raise exception using
      errcode = 'NS108',
      message = 'Save at least one marks entry before publishing.';
  end if;

  update public.assessments a
  set status = 'published'::public.assessment_status,
      revision = a.revision + 1,
      published_at = timezone('utc', now()),
      published_by = auth.uid(),
      updated_at = timezone('utc', now())
  where a.id = v_assessment.id;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'teacher', v_assessment.school_id,
    'update'::public.audit_action_kind, 'assessment_publish', v_assessment.id::text,
    jsonb_build_object(
      'assessment_id', v_assessment.id,
      'entry_count', v_entry_count,
      'idempotency_key', nullif(btrim(coalesce(p_idempotency_key, '')), '')
    )
  );

  return public.teacher_marks_load(p_assessment_id);
end;
$fn$;

create or replace function public.teacher_marks_history(p_assessment_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_assessment public.assessments%rowtype;
  v_rows jsonb := '[]'::jsonb;
begin
  if p_assessment_id is null then
    raise exception using errcode = 'NS096', message = 'Assessment id is required.';
  end if;

  select * into v_assessment
  from public.assessments a
  where a.id = p_assessment_id;

  if not found then
    raise exception using errcode = 'NS097', message = 'Assessment not found.';
  end if;

  if v_assessment.teacher_user_id is distinct from auth.uid() then
    raise exception using errcode = 'NS098', message = 'Assessment is not in your scope.';
  end if;

  perform nano_internal.require_active_teacher_assignment(
    v_assessment.teacher_assignment_id
  );

  select coalesce(jsonb_agg(jsonb_build_object(
    'id', c.id,
    'assessment_id', c.assessment_id,
    'student_user_id', c.student_user_id,
    'display_name', coalesce(p.display_name, ''),
    'previous_status', c.previous_status::text,
    'new_status', c.new_status::text,
    'previous_obtained_marks', c.previous_obtained_marks,
    'new_obtained_marks', c.new_obtained_marks,
    'previous_remarks', c.previous_remarks,
    'new_remarks', c.new_remarks,
    'reason', c.reason,
    'corrected_by', c.corrected_by,
    'corrected_by_name', coalesce(actor.display_name, ''),
    'corrected_at', c.corrected_at,
    'revision_before', c.revision_before,
    'revision_after', c.revision_after
  ) order by c.corrected_at desc, c.id), '[]'::jsonb)
  into v_rows
  from public.marks_corrections c
  left join public.profiles p on p.id = c.student_user_id
  left join public.profiles actor on actor.id = c.corrected_by
  where c.assessment_id = v_assessment.id;

  return jsonb_build_object(
    'assessment_id', v_assessment.id,
    'corrections', v_rows,
    'generated_at', timezone('utc', now())
  );
end;
$fn$;

create or replace function public.teacher_marks_correct(
  p_assessment_id uuid,
  p_student_user_id uuid,
  p_new_status text,
  p_obtained_marks numeric,
  p_remarks text,
  p_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_assessment public.assessments%rowtype;
  v_assignment public.teacher_assignments%rowtype;
  v_entry public.marks_entries%rowtype;
  v_status text := lower(btrim(coalesce(p_new_status, '')));
  v_reason text := btrim(coalesce(p_reason, ''));
  v_remarks text := coalesce(p_remarks, '');
  v_obtained numeric := p_obtained_marks;
  v_allow_bonus boolean := false;
  v_revision_before integer;
  v_revision_after integer;
  v_correction_id uuid;
begin
  if p_assessment_id is null then
    raise exception using errcode = 'NS096', message = 'Assessment id is required.';
  end if;
  if p_student_user_id is null then
    raise exception using errcode = 'NS082', message = 'Student id is required.';
  end if;
  if v_reason = '' then
    raise exception using errcode = 'NS083', message = 'Correction reason is required.';
  end if;
  if v_status not in ('scored', 'absent', 'exempt', 'not_submitted') then
    raise exception using errcode = 'NS109', message = 'Invalid marks status.';
  end if;

  select * into v_assessment
  from public.assessments a
  where a.id = p_assessment_id
  for update;

  if not found then
    raise exception using errcode = 'NS097', message = 'Assessment not found.';
  end if;

  if v_assessment.teacher_user_id is distinct from auth.uid() then
    raise exception using errcode = 'NS098', message = 'Assessment is not in your scope.';
  end if;

  if v_assessment.status not in (
    'published'::public.assessment_status,
    'corrected'::public.assessment_status
  ) then
    raise exception using
      errcode = 'NS110',
      message = 'Only published assessments can be corrected.';
  end if;

  perform nano_internal.assert_assessment_period_open(v_assessment);
  v_assignment := nano_internal.require_active_teacher_assignment(
    v_assessment.teacher_assignment_id
  );

  select coalesce(smp.allow_bonus, false) into v_allow_bonus
  from public.school_marks_policies smp
  where smp.school_id = v_assignment.school_id;
  if v_allow_bonus is null then
    v_allow_bonus := false;
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
  from public.marks_entries e
  where e.assessment_id = v_assessment.id
    and e.student_user_id = p_student_user_id
  for update;

  if not found then
    raise exception using
      errcode = 'NS111',
      message = 'Marks entry not found for student.';
  end if;

  if v_status = 'scored' then
    if v_obtained is null then
      raise exception using
        errcode = 'NS112',
        message = 'Obtained marks required for scored entries.';
    end if;
    if v_obtained < 0 then
      raise exception using
        errcode = 'NS113',
        message = 'Obtained marks cannot be negative.';
    end if;
    if v_obtained > v_assessment.total_marks and not v_allow_bonus then
      raise exception using
        errcode = 'NS114',
        message = 'Obtained marks exceeds total.';
    end if;
  else
    v_obtained := null;
  end if;

  if v_entry.status::text = v_status
    and v_entry.obtained_marks is not distinct from v_obtained
    and btrim(v_entry.remarks) is not distinct from btrim(v_remarks)
  then
    raise exception using
      errcode = 'NS087',
      message = 'Correction must change status, marks, or remarks.';
  end if;

  v_revision_before := v_assessment.revision;
  v_revision_after := v_revision_before + 1;

  insert into public.marks_corrections (
    school_id, assessment_id, entry_id, student_user_id,
    previous_status, new_status,
    previous_obtained_marks, new_obtained_marks,
    previous_remarks, new_remarks,
    reason, corrected_by, revision_before, revision_after
  ) values (
    v_assessment.school_id, v_assessment.id, v_entry.id, p_student_user_id,
    v_entry.status, v_status::public.marks_entry_status,
    v_entry.obtained_marks, v_obtained,
    v_entry.remarks, v_remarks,
    v_reason, auth.uid(), v_revision_before, v_revision_after
  )
  returning id into v_correction_id;

  update public.marks_entries e
  set status = v_status::public.marks_entry_status,
      obtained_marks = v_obtained,
      remarks = v_remarks,
      updated_at = timezone('utc', now())
  where e.id = v_entry.id;

  update public.assessments a
  set status = 'corrected'::public.assessment_status,
      revision = v_revision_after,
      updated_at = timezone('utc', now())
  where a.id = v_assessment.id;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'teacher', v_assessment.school_id,
    'update'::public.audit_action_kind, 'marks_correction', v_correction_id::text,
    jsonb_build_object(
      'assessment_id', v_assessment.id,
      'student_user_id', p_student_user_id,
      'previous_status', v_entry.status::text,
      'new_status', v_status,
      'previous_obtained_marks', v_entry.obtained_marks,
      'new_obtained_marks', v_obtained,
      'reason', v_reason,
      'revision_before', v_revision_before,
      'revision_after', v_revision_after
    )
  );

  return jsonb_build_object(
    'corrected', true,
    'correction_id', v_correction_id,
    'grid', public.teacher_marks_load(p_assessment_id),
    'history', public.teacher_marks_history(p_assessment_id)
  );
end;
$fn$;

revoke all on function public.teacher_marks_publish(uuid, text) from public, anon;
grant execute on function public.teacher_marks_publish(uuid, text)
  to authenticated, service_role;

revoke all on function public.teacher_marks_history(uuid) from public, anon;
grant execute on function public.teacher_marks_history(uuid)
  to authenticated, service_role;

revoke all on function public.teacher_marks_correct(uuid, uuid, text, numeric, text, text)
  from public, anon;
grant execute on function public.teacher_marks_correct(uuid, uuid, text, numeric, text, text)
  to authenticated, service_role;

comment on table public.marks_corrections is
  'MRK-04 immutable marks correction history; prior values are never erased.';
comment on function public.teacher_marks_publish(uuid, text) is
  'MRK-04 publish a draft assessment with saved marks entries.';
comment on function public.teacher_marks_correct(uuid, uuid, text, numeric, text, text) is
  'MRK-04 correct a published marks entry with required reason; appends history.';
comment on function public.teacher_marks_history(uuid) is
  'MRK-04 list correction history for an assessment.';
