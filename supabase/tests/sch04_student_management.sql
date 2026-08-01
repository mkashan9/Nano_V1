-- SCH-04 student management RPC presence.

do $$
begin
  if to_regclass('public.student_enrollments') is null then
    raise exception 'student_enrollments missing';
  end if;
  if to_regprocedure('public.list_school_students(text)') is null then
    raise exception 'list_school_students missing';
  end if;
  if to_regprocedure('public.create_school_student(text, text, text, uuid)') is null then
    raise exception 'create_school_student missing';
  end if;
  if to_regprocedure('public.set_school_student_status(uuid, text, text)') is null then
    raise exception 'set_school_student_status missing';
  end if;
  if to_regprocedure('public.enroll_school_student(uuid, uuid)') is null then
    raise exception 'enroll_school_student missing';
  end if;
  if to_regprocedure('public.preview_student_import(jsonb)') is null then
    raise exception 'preview_student_import missing';
  end if;
  if to_regprocedure('public.commit_student_import(jsonb)') is null then
    raise exception 'commit_student_import missing';
  end if;
end $$;
