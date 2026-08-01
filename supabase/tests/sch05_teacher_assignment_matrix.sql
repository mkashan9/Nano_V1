-- SCH-05 teacher assignment matrix RPC presence.

do $$
begin
  if to_regprocedure('public.list_teacher_assignment_matrix()') is null then
    raise exception 'list_teacher_assignment_matrix missing';
  end if;
  if to_regprocedure('public.assign_teacher(uuid, uuid, uuid, uuid, date)') is null then
    raise exception 'assign_teacher missing';
  end if;
  if to_regprocedure('public.end_teacher_assignment(uuid, text)') is null then
    raise exception 'end_teacher_assignment missing';
  end if;
  if to_regprocedure('public.replace_teacher_assignment(uuid, uuid, text)') is null then
    raise exception 'replace_teacher_assignment missing';
  end if;
  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'teacher_assignments'
      and column_name = 'class_id'
  ) then
    raise exception 'teacher_assignments.class_id missing';
  end if;
end $$;
