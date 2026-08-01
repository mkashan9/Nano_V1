-- SCH-02: academic structure RPC presence (school-admin gate exercised live).

do $$
begin
  if to_regprocedure('public.list_academic_structure()') is null then
    raise exception 'list_academic_structure missing';
  end if;
  if to_regprocedure('public.create_grade_level(text, integer)') is null then
    raise exception 'create_grade_level missing';
  end if;
  if to_regprocedure('public.create_class(uuid, text)') is null then
    raise exception 'create_class missing';
  end if;
  if to_regprocedure('public.create_section(uuid, text)') is null then
    raise exception 'create_section missing';
  end if;
  if to_regprocedure('public.create_school_subject(text, text, uuid)') is null then
    raise exception 'create_school_subject missing';
  end if;
  if to_regprocedure('public.assign_class_subject(uuid, uuid, uuid)') is null then
    raise exception 'assign_class_subject missing';
  end if;
  if to_regprocedure('public.archive_academic_structure(text, uuid)') is null then
    raise exception 'archive_academic_structure missing';
  end if;
  if to_regclass('public.grade_levels') is null
     or to_regclass('public.classes') is null
     or to_regclass('public.sections') is null
     or to_regclass('public.school_subjects') is null
     or to_regclass('public.class_subjects') is null then
    raise exception 'SCH-02 tables missing';
  end if;
end $$;
