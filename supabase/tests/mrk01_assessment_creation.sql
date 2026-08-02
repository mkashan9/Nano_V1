-- MRK-01 assessment creation RPC presence.

do $$
begin
  if to_regclass('public.assessments') is null then
    raise exception 'assessments missing';
  end if;
  if to_regprocedure('public.teacher_assessments_list(uuid)') is null then
    raise exception 'teacher_assessments_list missing';
  end if;
  if to_regprocedure(
    'public.teacher_assessment_create(uuid,text,text,date,numeric,numeric,text,uuid)'
  ) is null then
    raise exception 'teacher_assessment_create missing';
  end if;
  if to_regprocedure(
    'public.teacher_assessment_update(uuid,text,text,date,numeric,numeric,text,uuid)'
  ) is null then
    raise exception 'teacher_assessment_update missing';
  end if;
end $$;
