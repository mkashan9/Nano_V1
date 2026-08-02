-- CLS-02 classroom attachments RPC presence.

do $$
begin
  if to_regclass('public.classroom_attachments') is null then
    raise exception 'classroom_attachments missing';
  end if;
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'teacher_classroom_attachment_add'
  ) then
    raise exception 'teacher_classroom_attachment_add missing';
  end if;
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'teacher_classroom_attachment_remove'
  ) then
    raise exception 'teacher_classroom_attachment_remove missing';
  end if;
end $$;
