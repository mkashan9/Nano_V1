-- ATT-01 attendance load/submit presence and scope guard.

do $$
begin
  if to_regprocedure('public.teacher_attendance_load(uuid,date,text)') is null then
    raise exception 'teacher_attendance_load missing';
  end if;
  if to_regprocedure('public.teacher_attendance_submit(uuid,date,text,jsonb,text)') is null then
    raise exception 'teacher_attendance_submit missing';
  end if;
  if to_regclass('public.attendance_sessions') is null then
    raise exception 'attendance_sessions missing';
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

  if v_asg is null then
    raise exception 'seed teacher assignment missing';
  end if;

  v := public.teacher_attendance_load(v_asg, timezone('utc', now())::date, 'daily');
  if (v->>'assignment_id') is distinct from v_asg::text then
    raise exception 'load assignment mismatch';
  end if;
  if jsonb_typeof(v->'roster') is distinct from 'array' then
    raise exception 'roster must be array';
  end if;

  begin
    perform public.teacher_attendance_load(
      '00000000-0000-0000-0000-000000000099',
      timezone('utc', now())::date,
      'daily'
    );
    raise exception 'foreign assignment should be denied';
  exception
    when others then
      if sqlerrm not like '%active scope%' and sqlstate <> 'NS074' then
        raise;
      end if;
  end;
end $$;

select set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', true);

do $$
declare
  v_asg uuid := '00000000-0000-0000-0000-000000000099';
begin
  begin
    perform public.teacher_attendance_load(v_asg, timezone('utc', now())::date, 'daily');
    raise exception 'student should not load attendance';
  exception
    when others then
      if sqlerrm not like '%teacher membership%'
         and sqlerrm not like '%active scope%'
         and sqlstate not in ('NS072', 'NS074') then
        raise;
      end if;
  end;
end $$;
