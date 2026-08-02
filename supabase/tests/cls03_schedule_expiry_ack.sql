-- CLS-03 schedule / expiry / acknowledgement presence.

do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'classroom_items'
      and column_name = 'scheduled_publish_at'
  ) then
    raise exception 'scheduled_publish_at missing';
  end if;
  if to_regclass('public.classroom_acknowledgements') is null then
    raise exception 'classroom_acknowledgements missing';
  end if;
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'student_classroom_acknowledge'
  ) then
    raise exception 'student_classroom_acknowledge missing';
  end if;
end $$;
