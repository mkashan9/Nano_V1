-- FLX-04 student_classroom_feed presence.

do $$
begin
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'student_classroom_feed'
  ) then
    raise exception 'student_classroom_feed missing';
  end if;
end $$;
