-- FBK-01 presence: feedback_notes + teacher RPCs.

do $$
begin
  if to_regclass('public.feedback_notes') is null then
    raise exception 'feedback_notes missing';
  end if;
  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'feedback_category'
  ) then
    raise exception 'feedback_category missing';
  end if;
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'teacher_feedback_list'
  ) then
    raise exception 'teacher_feedback_list missing';
  end if;
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'teacher_feedback_create'
  ) then
    raise exception 'teacher_feedback_create missing';
  end if;
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'teacher_feedback_update'
  ) then
    raise exception 'teacher_feedback_update missing';
  end if;
end $$;
