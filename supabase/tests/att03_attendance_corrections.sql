-- ATT-03 attendance correction RPC presence and immutability.

do $$
begin
  if to_regprocedure(
    'public.teacher_attendance_correct(uuid,date,uuid,text,text,text)'
  ) is null then
    raise exception 'teacher_attendance_correct missing';
  end if;
  if to_regprocedure('public.teacher_attendance_history(uuid,date,text)') is null then
    raise exception 'teacher_attendance_history missing';
  end if;
  if to_regclass('public.attendance_corrections') is null then
    raise exception 'attendance_corrections missing';
  end if;
end $$;
