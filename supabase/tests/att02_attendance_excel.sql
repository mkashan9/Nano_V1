-- ATT-02 attendance template/import RPC presence.

do $$
begin
  if to_regprocedure('public.teacher_attendance_template(uuid,date,text)') is null then
    raise exception 'teacher_attendance_template missing';
  end if;
  if to_regprocedure('public.preview_attendance_import(uuid,date,text,jsonb,text)') is null then
    raise exception 'preview_attendance_import missing';
  end if;
  if to_regprocedure('public.commit_attendance_import(uuid,date,text,jsonb,text)') is null then
    raise exception 'commit_attendance_import missing';
  end if;
  if to_regclass('public.attendance_import_jobs') is null then
    raise exception 'attendance_import_jobs missing';
  end if;
end $$;

select set_config('request.jwt.claim.sub', 'cccccccc-cccc-cccc-cccc-cccccccccccc', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config('role', 'authenticated', true);

do $$
declare
  v_asg uuid;
  v jsonb;
begin
  select id into v_asg
  from public.teacher_assignments
  where teacher_user_id = 'cccccccc-cccc-cccc-cccc-cccccccccccc'
    and status = 'active'
  order by created_at
  limit 1;

  v := public.teacher_attendance_template(v_asg, timezone('utc', now())::date, 'daily');
  if jsonb_typeof(v->'rows') is distinct from 'array' then
    raise exception 'template rows must be array';
  end if;
  if jsonb_typeof(v->'headers') is distinct from 'array' then
    raise exception 'template headers must be array';
  end if;
end $$;
