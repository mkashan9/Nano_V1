-- ADM-04: learning catalog authoring RPCs exist for platform staff.

begin;

do $$
begin
  if to_regprocedure(
    'public.create_subject_draft(text, text, text, text, text, text, integer, integer, boolean, uuid)'
  ) is null then
    raise exception 'create_subject_draft missing';
  end if;
  if to_regprocedure('public.publish_subject_version(uuid)') is null then
    raise exception 'publish_subject_version missing';
  end if;
  if to_regprocedure('public.archive_subject_version(uuid)') is null then
    raise exception 'archive_subject_version missing';
  end if;
  if to_regprocedure(
    'public.create_topic_draft(uuid, text, text, text, text[], integer, integer, text, text, jsonb, uuid, uuid)'
  ) is null then
    raise exception 'create_topic_draft missing';
  end if;
  if to_regprocedure('public.publish_topic_version(uuid)') is null then
    raise exception 'publish_topic_version missing';
  end if;
  if to_regprocedure('public.archive_topic_version(uuid)') is null then
    raise exception 'archive_topic_version missing';
  end if;
  if to_regclass('public.learning_authoring') is null then
    raise exception 'learning_authoring view missing';
  end if;
  if has_function_privilege(
    'anon',
    'public.publish_subject_version(uuid)',
    'execute'
  ) then
    raise exception 'anon must not publish subjects';
  end if;

  raise notice 'adm04_learning_content: ok';
end;
$$;

rollback;
