-- SCH-03 teacher management RPC presence.

do $$
begin
  if to_regprocedure('public.list_school_teachers(text)') is null then
    raise exception 'list_school_teachers missing';
  end if;
  if to_regprocedure('public.create_school_teacher(text, text, text)') is null then
    raise exception 'create_school_teacher missing';
  end if;
  if to_regprocedure('public.set_school_teacher_status(uuid, text, text)') is null then
    raise exception 'set_school_teacher_status missing';
  end if;
  if to_regprocedure('public.preview_teacher_import(jsonb)') is null then
    raise exception 'preview_teacher_import missing';
  end if;
  if to_regprocedure('public.commit_teacher_import(jsonb)') is null then
    raise exception 'commit_teacher_import missing';
  end if;
end $$;
