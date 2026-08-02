-- FLX-02 student_attendance_mine presence.

do $$
begin
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'student_attendance_mine'
  ) then
    raise exception 'student_attendance_mine missing';
  end if;
end $$;
