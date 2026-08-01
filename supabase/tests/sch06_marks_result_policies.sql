-- SCH-06 marks / result policy RPC presence.

do $$
begin
  if to_regclass('public.school_marks_policies') is null then
    raise exception 'school_marks_policies missing';
  end if;
  if to_regclass('public.result_periods') is null then
    raise exception 'result_periods missing';
  end if;
  if to_regprocedure('public.get_school_marks_policy()') is null then
    raise exception 'get_school_marks_policy missing';
  end if;
  if to_regprocedure('public.upsert_school_marks_policy(text, numeric, boolean, text, jsonb)') is null then
    raise exception 'upsert_school_marks_policy missing';
  end if;
  if to_regprocedure('public.create_result_period(text, date, date)') is null then
    raise exception 'create_result_period missing';
  end if;
  if to_regprocedure('public.close_result_period(uuid, text)') is null then
    raise exception 'close_result_period missing';
  end if;
end $$;
