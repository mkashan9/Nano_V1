-- MRK-04 marks publish/correct RPC presence.

do $$
begin
  if to_regclass('public.marks_corrections') is null then
    raise exception 'marks_corrections missing';
  end if;
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'teacher_marks_publish'
  ) then
    raise exception 'teacher_marks_publish missing';
  end if;
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'teacher_marks_history'
  ) then
    raise exception 'teacher_marks_history missing';
  end if;
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'teacher_marks_correct'
  ) then
    raise exception 'teacher_marks_correct missing';
  end if;
end $$;
