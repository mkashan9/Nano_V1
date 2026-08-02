-- MRK-03 marks template/import RPC presence.

do $$
begin
  if to_regclass('public.marks_import_jobs') is null then
    raise exception 'marks_import_jobs missing';
  end if;
  if to_regprocedure('public.teacher_marks_template(uuid)') is null then
    raise exception 'teacher_marks_template missing';
  end if;
  if to_regprocedure('public.preview_marks_import(uuid,text,jsonb)') is null then
    raise exception 'preview_marks_import missing';
  end if;
  if to_regprocedure('public.commit_marks_import(uuid,text,jsonb)') is null then
    raise exception 'commit_marks_import missing';
  end if;
end $$;
