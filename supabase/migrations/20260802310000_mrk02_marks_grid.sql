-- MRK-02: in-app marks grid for draft assessments. Excel → MRK-03. Publish → MRK-04.

do $$
begin
  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'marks_entry_status'
  ) then
    create type public.marks_entry_status as enum (
      'scored', 'absent', 'exempt', 'not_submitted'
    );
  end if;
end $$;

create table if not exists public.marks_entries (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id),
  assessment_id uuid not null references public.assessments (id) on delete cascade,
  student_user_id uuid not null references public.profiles (id),
  status public.marks_entry_status not null default 'scored',
  obtained_marks numeric(10,2),
  remarks text not null default '',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint marks_entries_assessment_student_uidx unique (assessment_id, student_user_id),
  constraint marks_entries_scored_has_marks check (
    (status = 'scored'::public.marks_entry_status and obtained_marks is not null)
    or (status <> 'scored'::public.marks_entry_status and obtained_marks is null)
  ),
  constraint marks_entries_obtained_nonnegative check (
    obtained_marks is null or obtained_marks >= 0
  )
);

create index if not exists marks_entries_assessment_idx
  on public.marks_entries (assessment_id);

alter table public.marks_entries enable row level security;

revoke all on table public.marks_entries from public, anon, authenticated;
grant select, insert, update, delete on table public.marks_entries to service_role;

drop trigger if exists marks_entries_set_updated_at on public.marks_entries;
create trigger marks_entries_set_updated_at
  before update on public.marks_entries
  for each row execute function public.set_updated_at();

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

create or replace function public.teacher_marks_save(
  p_assessment_id uuid,
  p_entries jsonb,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_assessment public.assessments%rowtype;
  v_assignment public.teacher_assignments%rowtype;
  v_allow_bonus boolean := false;
  v_entry jsonb;
  v_student uuid;
  v_status text;
  v_obtained numeric;
  v_remarks text;
  v_roster_ids uuid[];
  v_key text := nullif(btrim(coalesce(p_idempotency_key, '')), '');
begin
  if p_assessment_id is null then
    raise exception using errcode = 'NS096', message = 'Assessment id is required.';
  end if;
  if p_entries is null or jsonb_typeof(p_entries) <> 'array' then
    raise exception using errcode = 'NS100', message = 'Entries array is required.';
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

  if v_assessment.status is distinct from 'draft'::public.assessment_status then
    raise exception using
      errcode = 'NS101',
      message = 'Marks can only be edited on draft assessments.';
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

  select coalesce(array_agg(r.student_user_id), '{}'::uuid[])
  into v_roster_ids
  from nano_internal.attendance_roster_for_assignment(v_assignment) r;

  for v_entry in select value from jsonb_array_elements(p_entries) as t(value)
  loop
    begin
      v_student := (v_entry->>'student_user_id')::uuid;
    exception
      when others then
        raise exception using errcode = 'NS100', message = 'Invalid student_user_id in entries.';
    end;

    if not (v_student = any (v_roster_ids)) then
      raise exception using
        errcode = 'NS080',
        message = 'Student is not on the assigned roster.';
    end if;

    v_status := lower(btrim(coalesce(v_entry->>'status', '')));
    if v_status not in ('scored', 'absent', 'exempt', 'not_submitted') then
      raise exception using errcode = 'NS100', message = 'Invalid marks entry status.';
    end if;

    v_remarks := coalesce(v_entry->>'remarks', '');

    if v_status = 'scored' then
      if v_entry->>'obtained_marks' is null or btrim(v_entry->>'obtained_marks') = '' then
        raise exception using errcode = 'NS102', message = 'Obtained marks required for scored entries.';
      end if;
      begin
        v_obtained := (v_entry->>'obtained_marks')::numeric;
      exception
        when others then
          raise exception using errcode = 'NS102', message = 'Invalid obtained marks.';
      end;
      if v_obtained < 0 then
        raise exception using errcode = 'NS102', message = 'Obtained marks cannot be negative.';
      end if;
      if v_obtained > v_assessment.total_marks and not v_allow_bonus then
        raise exception using
          errcode = 'NS103',
          message = 'Obtained marks cannot exceed total unless bonus is allowed.';
      end if;
    else
      v_obtained := null;
    end if;
  end loop;

  delete from public.marks_entries e where e.assessment_id = v_assessment.id;

  for v_entry in select value from jsonb_array_elements(p_entries) as t(value)
  loop
    v_student := (v_entry->>'student_user_id')::uuid;
    v_status := lower(btrim(v_entry->>'status'));
    v_remarks := coalesce(v_entry->>'remarks', '');
    if v_status = 'scored' then
      v_obtained := (v_entry->>'obtained_marks')::numeric;
    else
      v_obtained := null;
    end if;

    insert into public.marks_entries (
      school_id, assessment_id, student_user_id, status, obtained_marks, remarks
    ) values (
      v_assignment.school_id, v_assessment.id, v_student,
      v_status::public.marks_entry_status, v_obtained, v_remarks
    );
  end loop;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'teacher', v_assignment.school_id,
    'update'::public.audit_action_kind, 'marks_entries', v_assessment.id::text,
    jsonb_build_object(
      'assessment_id', v_assessment.id,
      'entry_count', jsonb_array_length(p_entries),
      'idempotency_key', v_key
    )
  );

  return public.teacher_marks_load(v_assessment.id);
end;
$fn$;

revoke all on function public.teacher_marks_load(uuid) from public, anon;
grant execute on function public.teacher_marks_load(uuid)
  to authenticated, service_role;

revoke all on function public.teacher_marks_save(uuid, jsonb, text) from public, anon;
grant execute on function public.teacher_marks_save(uuid, jsonb, text)
  to authenticated, service_role;

-- Unpublished marks = draft assessments that already have marks rows.
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
  v_draft_assessments int := 0;
  v_unpublished_marks int := 0;
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

  select count(*)::int into v_draft_assessments
  from public.assessments a
  where a.school_id = v_school_id
    and a.teacher_user_id = v_teacher_id
    and a.status = 'draft'::public.assessment_status;

  select count(distinct a.id)::int into v_unpublished_marks
  from public.assessments a
  join public.marks_entries e on e.assessment_id = a.id
  where a.school_id = v_school_id
    and a.teacher_user_id = v_teacher_id
    and a.status = 'draft'::public.assessment_status;

  return jsonb_build_object(
    'school_id', v_school_id,
    'school_code', v_school.code,
    'school_name', coalesce(nullif(btrim(v_school.display_name), ''), v_school.name),
    'teacher_id', v_teacher_id,
    'teacher_name', coalesce(v_profile.display_name, ''),
    'active_assignment_count', v_active_count,
    'pending_attendance_count', coalesce(v_pending_attendance, 0),
    'draft_assessment_count', coalesce(v_draft_assessments, 0),
    'unpublished_marks_count', coalesce(v_unpublished_marks, 0),
    'recent_classroom_count', 0,
    'assignments', v_assignments,
    'generated_at', timezone('utc', now())
  );
end;
$fn$;

comment on table public.marks_entries is
  'MRK-02 draft marks grid entries. Publish remains MRK-04.';
comment on function public.teacher_marks_load(uuid) is
  'MRK-02 load roster + marks entries for an owned assessment.';
comment on function public.teacher_marks_save(uuid, jsonb, text) is
  'MRK-02 save draft marks entries for a draft assessment.';
