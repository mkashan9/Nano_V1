-- SCH-06: school marks / result policies and result periods.
-- Attendance entry and marks publish stay teacher modules (ATT/MRK).

create table public.school_marks_policies (
  school_id uuid primary key references public.schools (id) on delete cascade,
  attendance_mode text not null default 'daily'
    check (attendance_mode in ('daily', 'session')),
  passing_percent numeric(5,2) not null default 40
    check (passing_percent >= 0 and passing_percent <= 100),
  allow_bonus boolean not null default false,
  report_card_format text not null default 'both'
    check (report_card_format in ('percent', 'grade', 'both')),
  grade_bands jsonb not null default '[
    {"min":90,"label":"A+"},
    {"min":80,"label":"A"},
    {"min":70,"label":"B"},
    {"min":60,"label":"C"},
    {"min":50,"label":"D"},
    {"min":0,"label":"F"}
  ]'::jsonb,
  updated_at timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now())
);

create table public.result_periods (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools (id) on delete cascade,
  name text not null,
  starts_on date,
  ends_on date,
  status text not null default 'open'
    check (status in ('open', 'closed')),
  closed_at timestamptz,
  closed_reason text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint result_periods_name_nonempty check (length(btrim(name)) > 0)
);

create unique index result_periods_school_name_uq
  on public.result_periods (school_id, lower(btrim(name)));

create index result_periods_school_idx on public.result_periods (school_id);

alter table public.school_marks_policies enable row level security;
alter table public.result_periods enable row level security;

create policy school_marks_policies_select_member on public.school_marks_policies
  for select to authenticated
  using (nano_internal.is_school_member(school_id));

create policy result_periods_select_member on public.result_periods
  for select to authenticated
  using (nano_internal.is_school_member(school_id));

drop trigger if exists school_marks_policies_set_updated_at on public.school_marks_policies;
create trigger school_marks_policies_set_updated_at
  before update on public.school_marks_policies
  for each row execute function public.set_updated_at();

drop trigger if exists result_periods_set_updated_at on public.result_periods;
create trigger result_periods_set_updated_at
  before update on public.result_periods
  for each row execute function public.set_updated_at();

-- Seed default policy rows for existing schools.
insert into public.school_marks_policies (school_id)
select s.id from public.schools s
on conflict (school_id) do nothing;

create or replace function public.get_school_marks_policy()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_school_id uuid;
  v_policy public.school_marks_policies%rowtype;
  v_periods jsonb;
begin
  v_school_id := nano_internal.require_school_admin_school_id();

  insert into public.school_marks_policies (school_id)
  values (v_school_id)
  on conflict (school_id) do nothing;

  select * into v_policy
  from public.school_marks_policies
  where school_id = v_school_id;

  select coalesce(jsonb_agg(row_to_json(p)::jsonb order by p.starts_on nulls last, p.name), '[]'::jsonb)
  into v_periods
  from (
    select
      id,
      name,
      starts_on,
      ends_on,
      status,
      closed_at,
      closed_reason,
      created_at
    from public.result_periods
    where school_id = v_school_id
  ) p;

  return jsonb_build_object(
    'school_id', v_school_id,
    'attendance_mode', v_policy.attendance_mode,
    'passing_percent', v_policy.passing_percent,
    'allow_bonus', v_policy.allow_bonus,
    'report_card_format', v_policy.report_card_format,
    'grade_bands', v_policy.grade_bands,
    'updated_at', v_policy.updated_at,
    'periods', v_periods
  );
end;
$fn$;

revoke all on function public.get_school_marks_policy() from public, anon;
grant execute on function public.get_school_marks_policy()
  to authenticated, service_role;

create or replace function public.upsert_school_marks_policy(
  p_attendance_mode text,
  p_passing_percent numeric,
  p_allow_bonus boolean,
  p_report_card_format text,
  p_grade_bands jsonb default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_school_id uuid;
  v_mode text := lower(btrim(coalesce(p_attendance_mode, '')));
  v_format text := lower(btrim(coalesce(p_report_card_format, '')));
  v_bands jsonb;
begin
  v_school_id := nano_internal.require_school_admin_school_id();

  if v_mode not in ('daily', 'session') then
    raise exception using errcode = 'NS062', message = 'Attendance mode must be daily or session.';
  end if;
  if p_passing_percent is null or p_passing_percent < 0 or p_passing_percent > 100 then
    raise exception using errcode = 'NS063', message = 'Passing percent must be between 0 and 100.';
  end if;
  if v_format not in ('percent', 'grade', 'both') then
    raise exception using errcode = 'NS064', message = 'Report card format must be percent, grade, or both.';
  end if;

  v_bands := coalesce(p_grade_bands, (
    select grade_bands from public.school_marks_policies where school_id = v_school_id
  ), '[
    {"min":90,"label":"A+"},
    {"min":80,"label":"A"},
    {"min":70,"label":"B"},
    {"min":60,"label":"C"},
    {"min":50,"label":"D"},
    {"min":0,"label":"F"}
  ]'::jsonb);

  if jsonb_typeof(v_bands) <> 'array' or jsonb_array_length(v_bands) = 0 then
    raise exception using errcode = 'NS065', message = 'Grade bands must be a non-empty JSON array.';
  end if;

  insert into public.school_marks_policies (
    school_id, attendance_mode, passing_percent, allow_bonus, report_card_format, grade_bands
  ) values (
    v_school_id, v_mode, p_passing_percent, coalesce(p_allow_bonus, false), v_format, v_bands
  )
  on conflict (school_id) do update set
    attendance_mode = excluded.attendance_mode,
    passing_percent = excluded.passing_percent,
    allow_bonus = excluded.allow_bonus,
    report_card_format = excluded.report_card_format,
    grade_bands = excluded.grade_bands,
    updated_at = timezone('utc', now());

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'school_admin', v_school_id,
    'update'::public.audit_action_kind, 'school_marks_policy', v_school_id::text,
    jsonb_build_object(
      'attendance_mode', v_mode,
      'passing_percent', p_passing_percent,
      'allow_bonus', coalesce(p_allow_bonus, false),
      'report_card_format', v_format
    )
  );

  return public.get_school_marks_policy();
end;
$fn$;

revoke all on function public.upsert_school_marks_policy(text, numeric, boolean, text, jsonb)
  from public, anon;
grant execute on function public.upsert_school_marks_policy(text, numeric, boolean, text, jsonb)
  to authenticated, service_role;

create or replace function public.create_result_period(
  p_name text,
  p_starts_on date default null,
  p_ends_on date default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_school_id uuid;
  v_name text := btrim(coalesce(p_name, ''));
  v_id uuid;
begin
  v_school_id := nano_internal.require_school_admin_school_id();
  if v_name = '' then
    raise exception using errcode = 'NS066', message = 'Period name is required.';
  end if;
  if p_starts_on is not null and p_ends_on is not null and p_ends_on < p_starts_on then
    raise exception using errcode = 'NS067', message = 'Period end date must be on or after start date.';
  end if;

  insert into public.result_periods (school_id, name, starts_on, ends_on, status)
  values (v_school_id, v_name, p_starts_on, p_ends_on, 'open')
  returning id into v_id;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'school_admin', v_school_id,
    'create'::public.audit_action_kind, 'result_period', v_id::text,
    jsonb_build_object('name', v_name, 'starts_on', p_starts_on, 'ends_on', p_ends_on)
  );

  return public.get_school_marks_policy();
end;
$fn$;

revoke all on function public.create_result_period(text, date, date) from public, anon;
grant execute on function public.create_result_period(text, date, date)
  to authenticated, service_role;

create or replace function public.close_result_period(
  p_period_id uuid,
  p_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_school_id uuid;
  v_reason text := btrim(coalesce(p_reason, ''));
  v_row public.result_periods%rowtype;
begin
  v_school_id := nano_internal.require_school_admin_school_id();
  if v_reason = '' then
    raise exception using errcode = 'NS068', message = 'A reason is required.';
  end if;

  select * into v_row
  from public.result_periods
  where id = p_period_id and school_id = v_school_id;
  if not found then
    raise exception using errcode = 'NS069', message = 'Result period not found in this school.';
  end if;
  if v_row.status = 'closed' then
    raise exception using errcode = 'NS070', message = 'Result period is already closed.';
  end if;

  update public.result_periods
  set status = 'closed',
      closed_at = timezone('utc', now()),
      closed_reason = v_reason,
      updated_at = timezone('utc', now())
  where id = p_period_id;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'school_admin', v_school_id,
    'update'::public.audit_action_kind, 'result_period', p_period_id::text,
    jsonb_build_object('status', 'closed', 'reason', v_reason)
  );

  return public.get_school_marks_policy();
end;
$fn$;

revoke all on function public.close_result_period(uuid, text) from public, anon;
grant execute on function public.close_result_period(uuid, text)
  to authenticated, service_role;

comment on table public.school_marks_policies is
  'SCH-06 school-scoped attendance/grading/report-card policy.';
comment on table public.result_periods is
  'SCH-06 open/closed result periods; closed periods need privileged correction later.';
comment on function public.get_school_marks_policy() is
  'SCH-06 load marks policy + result periods for the caller school.';
comment on function public.upsert_school_marks_policy(text, numeric, boolean, text, jsonb) is
  'SCH-06 upsert school marks policy.';
comment on function public.create_result_period(text, date, date) is
  'SCH-06 create an open result period.';
comment on function public.close_result_period(uuid, text) is
  'SCH-06 close a result period with audited reason.';
