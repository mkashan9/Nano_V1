-- MRK-05 result summary RPC presence.

do $$
begin
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'teacher_marks_result_summary'
  ) then
    raise exception 'teacher_marks_result_summary missing';
  end if;
end $$;
