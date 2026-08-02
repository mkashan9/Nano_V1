-- CLS-01 classroom announcements RPC presence.

do $$
begin
  if to_regclass('public.classroom_items') is null then
    raise exception 'classroom_items missing';
  end if;
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'teacher_classroom_list'
  ) then
    raise exception 'teacher_classroom_list missing';
  end if;
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'teacher_classroom_create'
  ) then
    raise exception 'teacher_classroom_create missing';
  end if;
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'teacher_classroom_update'
  ) then
    raise exception 'teacher_classroom_update missing';
  end if;
end $$;
