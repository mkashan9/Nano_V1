-- FLX-04: student classroom feed of published announcements for enrolled classes.
-- Reuses CLS-03 student_classroom_acknowledge for acks.

create or replace function public.student_classroom_feed()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_items jsonb;
begin
  if auth.uid() is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  if not exists (
    select 1
    from public.school_memberships sm
    where sm.user_id = auth.uid()
      and sm.role = 'student'::public.membership_role
      and sm.status = 'active'::public.membership_status
  ) then
    return jsonb_build_object(
      'items', '[]'::jsonb,
      'generated_at', timezone('utc', now())
    );
  end if;

  -- Promote due scheduled drafts for classes this student belongs to.
  update public.classroom_items i
  set status = 'published'::public.classroom_item_status,
      published_at = coalesce(i.published_at, i.scheduled_publish_at, timezone('utc', now())),
      updated_at = timezone('utc', now())
  from public.teacher_assignments ta
  where i.teacher_assignment_id = ta.id
    and i.status = 'draft'::public.classroom_item_status
    and i.scheduled_publish_at is not null
    and i.scheduled_publish_at <= timezone('utc', now())
    and exists (
      select 1
      from public.student_enrollments se
      where se.school_id = i.school_id
        and se.class_id = ta.class_id
        and se.student_user_id = auth.uid()
        and se.status = 'active'::public.membership_status
    );

  select coalesce(jsonb_agg(row_to_json(r)::jsonb order by r.published_at desc nulls last, r.created_at desc), '[]'::jsonb)
  into v_items
  from (
    select
      i.id,
      i.title,
      i.body,
      i.status::text as status,
      i.published_at,
      i.expires_at,
      i.requires_acknowledgement,
      i.created_at,
      (
        i.expires_at is not null and i.expires_at <= timezone('utc', now())
      ) as is_expired,
      exists (
        select 1
        from public.classroom_acknowledgements a
        where a.classroom_item_id = i.id
          and a.student_user_id = auth.uid()
      ) as acknowledged,
      (
        select a.acknowledged_at
        from public.classroom_acknowledgements a
        where a.classroom_item_id = i.id
          and a.student_user_id = auth.uid()
        limit 1
      ) as acknowledged_at,
      coalesce(
        (select ss.code from public.school_subjects ss where ss.id = ta.school_subject_id),
        ta.subject_code
      ) as subject_code,
      coalesce(
        (select c.name from public.classes c where c.id = ta.class_id),
        ta.class_label
      ) as class_label,
      coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', att.id,
          'classroom_item_id', att.classroom_item_id,
          'kind', att.kind::text,
          'title', att.title,
          'url', att.url,
          'storage_bucket', att.storage_bucket,
          'storage_path', att.storage_path,
          'content_type', att.content_type,
          'byte_size', att.byte_size,
          'checksum', att.checksum,
          'sort_order', att.sort_order
        ) order by att.sort_order, att.created_at)
        from public.classroom_attachments att
        where att.classroom_item_id = i.id
      ), '[]'::jsonb) as attachments
    from public.classroom_items i
    join public.teacher_assignments ta on ta.id = i.teacher_assignment_id
    where i.status = 'published'::public.classroom_item_status
      and exists (
        select 1
        from public.student_enrollments se
        where se.school_id = i.school_id
          and se.class_id = ta.class_id
          and se.student_user_id = auth.uid()
          and se.status = 'active'::public.membership_status
      )
  ) r;

  return jsonb_build_object(
    'items', v_items,
    'generated_at', timezone('utc', now())
  );
end;
$fn$;

revoke all on function public.student_classroom_feed() from public, anon;
grant execute on function public.student_classroom_feed()
  to authenticated, service_role;

comment on function public.student_classroom_feed() is
  'FLX-04 student feed of published classroom announcements for enrolled classes.';
