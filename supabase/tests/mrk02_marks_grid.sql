-- MRK-02 marks grid RPC presence.

do $$
begin
  if to_regclass('public.marks_entries') is null then
    raise exception 'marks_entries missing';
  end if;
  if to_regprocedure('public.teacher_marks_load(uuid)') is null then
    raise exception 'teacher_marks_load missing';
  end if;
  if to_regprocedure('public.teacher_marks_save(uuid,jsonb,text)') is null then
    raise exception 'teacher_marks_save missing';
  end if;
end $$;
