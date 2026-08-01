-- ADM-07: notification template admin RPCs exist for platform staff.

begin;

do $$
begin
  if to_regclass('public.notification_templates') is null then
    raise exception 'notification_templates table missing';
  end if;
  if to_regprocedure('public.list_notification_templates_admin()') is null then
    raise exception 'list_notification_templates_admin missing';
  end if;
  if to_regprocedure(
    'public.create_notification_template_draft(text, text, text, text, text, text, text, text, boolean)'
  ) is null then
    raise exception 'create_notification_template_draft missing';
  end if;
  if to_regprocedure('public.publish_notification_template(uuid)') is null then
    raise exception 'publish_notification_template missing';
  end if;
  if to_regprocedure(
    'public.disable_notification_template(uuid, text)'
  ) is null then
    raise exception 'disable_notification_template missing';
  end if;
  if has_function_privilege(
    'anon', 'public.publish_notification_template(uuid)', 'execute'
  ) then
    raise exception 'anon must not publish notification templates';
  end if;

  raise notice 'adm07_notification_admin: ok';
end;
$$;

rollback;
