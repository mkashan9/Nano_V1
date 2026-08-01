-- ADM-04: Learning Stack catalog authoring for platform staff.
-- Subjects/topics draft -> publish -> archive. Question bank stays QZ-01/02.

create or replace view public.learning_authoring
with (security_invoker = true) as
select
  s.id as subject_id,
  s.slug as subject_slug,
  s.sort_order as subject_order,
  sv.id as subject_version_id,
  sv.version as subject_version,
  sv.title as subject_title,
  sv.title_ur as subject_title_ur,
  sv.summary as subject_summary,
  sv.world_color_hex,
  sv.status as subject_status,
  sv.published_at as subject_published_at,
  coalesce(er.track, 'both') as track,
  er.min_grade,
  er.max_grade,
  coalesce(er.independent_allowed, true) as independent_allowed,
  coalesce((
    select jsonb_agg(
      jsonb_build_object(
        'topic_id', t.id,
        'topic_slug', t.slug,
        'topic_order', t.sort_order,
        'topic_version_id', tv.id,
        'topic_version', tv.version,
        'title', tv.title,
        'title_ur', tv.title_ur,
        'status', tv.status,
        'estimated_minutes', tv.estimated_minutes,
        'duration_seconds', tv.duration_seconds,
        'video_provider', tv.video_provider,
        'video_ref', tv.video_ref,
        'objectives', tv.objectives,
        'published_at', tv.published_at
      )
      order by t.sort_order, tv.version desc
    )
    from public.topics t
    join lateral (
      select tv2.*
      from public.topic_versions tv2
      where tv2.topic_id = t.id
        and tv2.subject_version_id = sv.id
      order by
        case tv2.status
          when 'published' then 1
          when 'draft' then 2
          else 3
        end,
        tv2.version desc
      limit 1
    ) tv on true
    where t.subject_id = s.id
  ), '[]'::jsonb) as topics
from public.learning_subjects s
join lateral (
  select sv2.*
  from public.subject_versions sv2
  where sv2.subject_id = s.id
  order by
    case sv2.status
      when 'published' then 1
      when 'draft' then 2
      else 3
    end,
    sv2.version desc
  limit 1
) sv on true
left join public.eligibility_rules er on er.subject_id = s.id;

comment on view public.learning_authoring is
  'ADM-04 curator catalog: latest useful subject version plus topic summaries. '
  'Platform admins see drafts via underlying RLS; learners still cannot.';

grant select on public.learning_authoring to authenticated, service_role;

create or replace function public.create_subject_draft(
  p_slug text,
  p_title text,
  p_summary text default '',
  p_title_ur text default null,
  p_world_color_hex text default '#2F7BFF',
  p_track text default 'both',
  p_min_grade integer default null,
  p_max_grade integer default null,
  p_independent_allowed boolean default true,
  p_subject_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_subject_id uuid;
  v_version integer;
  v_row public.subject_versions%rowtype;
  v_slug text := lower(btrim(coalesce(p_slug, '')));
  v_title text := btrim(coalesce(p_title, ''));
  v_color text := upper(btrim(coalesce(p_world_color_hex, '#2F7BFF')));
  v_track text := lower(btrim(coalesce(p_track, 'both')));
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NL010',
      message = 'Only platform admins can author Learning Stack content.';
  end if;

  if v_slug = '' or v_title = '' then
    raise exception using
      errcode = 'NL011',
      message = 'Subject slug and title are required.';
  end if;

  if v_color !~ '^#[0-9A-F]{6}$' then
    raise exception using
      errcode = 'NL012',
      message = 'World color must be a hex like #2F7BFF.';
  end if;

  if v_track not in ('junior', 'senior', 'both') then
    raise exception using
      errcode = 'NL013',
      message = 'Track must be junior, senior, or both.';
  end if;

  if p_subject_id is null then
    insert into public.learning_subjects (slug, sort_order)
    values (
      v_slug,
      coalesce((select max(sort_order) + 1 from public.learning_subjects), 1)
    )
    returning id into v_subject_id;
    v_version := 1;
  else
    if not exists (
      select 1 from public.learning_subjects where id = p_subject_id
    ) then
      raise exception using
        errcode = 'NL014',
        message = 'Unknown subject.';
    end if;
    if exists (
      select 1 from public.subject_versions
      where subject_id = p_subject_id and status = 'draft'
    ) then
      raise exception using
        errcode = 'NL015',
        message = 'This subject already has a draft. Publish or archive it first.';
    end if;
    v_subject_id := p_subject_id;
    select coalesce(max(version), 0) + 1 into v_version
    from public.subject_versions
    where subject_id = v_subject_id;
  end if;

  insert into public.subject_versions (
    subject_id, version, title, title_ur, summary, world_color_hex, status
  ) values (
    v_subject_id, v_version, v_title, p_title_ur,
    coalesce(p_summary, ''), v_color, 'draft'
  )
  returning * into v_row;

  insert into public.eligibility_rules (
    subject_id, track, min_grade, max_grade, independent_allowed
  ) values (
    v_subject_id, v_track, p_min_grade, p_max_grade,
    coalesce(p_independent_allowed, true)
  )
  on conflict (subject_id) do update
    set track = excluded.track,
        min_grade = excluded.min_grade,
        max_grade = excluded.max_grade,
        independent_allowed = excluded.independent_allowed;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'superadmin', 'create', 'subject_version', v_row.id::text,
    jsonb_build_object(
      'subject_id', v_subject_id,
      'slug', v_slug,
      'version', v_version,
      'title', v_title,
      'track', v_track
    )
  );

  return jsonb_build_object(
    'subject_id', v_subject_id,
    'subject_slug', v_slug,
    'subject_version_id', v_row.id,
    'subject_version', v_row.version,
    'subject_title', v_row.title,
    'subject_title_ur', v_row.title_ur,
    'subject_summary', v_row.summary,
    'world_color_hex', v_row.world_color_hex,
    'subject_status', v_row.status,
    'track', v_track,
    'min_grade', p_min_grade,
    'max_grade', p_max_grade,
    'independent_allowed', coalesce(p_independent_allowed, true),
    'topics', '[]'::jsonb
  );
end;
$fn$;

revoke all on function public.create_subject_draft(
  text, text, text, text, text, text, integer, integer, boolean, uuid
) from public, anon;
grant execute on function public.create_subject_draft(
  text, text, text, text, text, text, integer, integer, boolean, uuid
) to authenticated, service_role;

create or replace function public.publish_subject_version(p_version_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_row public.subject_versions%rowtype;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NL010',
      message = 'Only platform admins can publish Learning Stack content.';
  end if;

  select * into v_row from public.subject_versions
  where id = p_version_id for update;

  if not found then
    raise exception using errcode = 'NL014', message = 'Unknown subject version.';
  end if;

  if v_row.status = 'published' then
    return jsonb_build_object(
      'subject_version_id', v_row.id,
      'subject_status', v_row.status,
      'subject_id', v_row.subject_id
    );
  end if;

  if v_row.status <> 'draft' then
    raise exception using
      errcode = 'NL016',
      message = 'Only drafts can be published.';
  end if;

  if btrim(v_row.title) = '' then
    raise exception using
      errcode = 'NL011',
      message = 'Subject title is required before publish.';
  end if;

  update public.subject_versions
  set status = 'archived', updated_at = timezone('utc', now())
  where subject_id = v_row.subject_id
    and status = 'published'
    and id <> p_version_id;

  update public.subject_versions
  set status = 'published',
      published_at = timezone('utc', now()),
      updated_at = timezone('utc', now())
  where id = p_version_id
  returning * into v_row;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'superadmin', 'update', 'subject_version', v_row.id::text,
    jsonb_build_object('status', 'published', 'subject_id', v_row.subject_id)
  );

  return jsonb_build_object(
    'subject_version_id', v_row.id,
    'subject_status', v_row.status,
    'subject_id', v_row.subject_id,
    'subject_published_at', v_row.published_at
  );
end;
$fn$;

revoke all on function public.publish_subject_version(uuid) from public, anon;
grant execute on function public.publish_subject_version(uuid)
  to authenticated, service_role;

create or replace function public.archive_subject_version(p_version_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_row public.subject_versions%rowtype;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NL010',
      message = 'Only platform admins can archive Learning Stack content.';
  end if;

  select * into v_row from public.subject_versions
  where id = p_version_id for update;

  if not found then
    raise exception using errcode = 'NL014', message = 'Unknown subject version.';
  end if;

  if v_row.status = 'archived' then
    return jsonb_build_object(
      'subject_version_id', v_row.id,
      'subject_status', v_row.status
    );
  end if;

  if v_row.status <> 'published' then
    raise exception using
      errcode = 'NL017',
      message = 'Only published subjects can be archived.';
  end if;

  update public.subject_versions
  set status = 'archived', updated_at = timezone('utc', now())
  where id = p_version_id
  returning * into v_row;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'superadmin', 'update', 'subject_version', v_row.id::text,
    jsonb_build_object('status', 'archived', 'subject_id', v_row.subject_id)
  );

  return jsonb_build_object(
    'subject_version_id', v_row.id,
    'subject_status', v_row.status,
    'subject_id', v_row.subject_id
  );
end;
$fn$;

revoke all on function public.archive_subject_version(uuid) from public, anon;
grant execute on function public.archive_subject_version(uuid)
  to authenticated, service_role;

create or replace function public.create_topic_draft(
  p_subject_id uuid,
  p_slug text,
  p_title text,
  p_title_ur text default null,
  p_objectives text[] default '{}',
  p_estimated_minutes integer default 10,
  p_duration_seconds integer default 300,
  p_video_provider text default 'fixture',
  p_video_ref text default 'draft://pending',
  p_resources jsonb default '[]'::jsonb,
  p_requires_topic_id uuid default null,
  p_topic_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_topic_id uuid;
  v_version integer;
  v_subject_version_id uuid;
  v_row public.topic_versions%rowtype;
  v_slug text := lower(btrim(coalesce(p_slug, '')));
  v_title text := btrim(coalesce(p_title, ''));
  v_provider text := nullif(btrim(coalesce(p_video_provider, '')), '');
  v_ref text := nullif(btrim(coalesce(p_video_ref, '')), '');
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NL010',
      message = 'Only platform admins can author Learning Stack content.';
  end if;

  if v_slug = '' or v_title = '' then
    raise exception using
      errcode = 'NL011',
      message = 'Topic slug and title are required.';
  end if;

  if p_estimated_minutes is null
     or p_estimated_minutes < 1
     or p_estimated_minutes > 240 then
    raise exception using
      errcode = 'NL018',
      message = 'Estimated minutes must be between 1 and 240.';
  end if;

  if p_duration_seconds is null
     or p_duration_seconds < 30
     or p_duration_seconds > 14400 then
    raise exception using
      errcode = 'NL019',
      message = 'Duration must be between 30 and 14400 seconds.';
  end if;

  select sv.id into v_subject_version_id
  from public.subject_versions sv
  where sv.subject_id = p_subject_id
  order by
    case sv.status when 'draft' then 1 when 'published' then 2 else 3 end,
    sv.version desc
  limit 1;

  if v_subject_version_id is null then
    raise exception using errcode = 'NL014', message = 'Unknown subject.';
  end if;

  if p_topic_id is null then
    insert into public.topics (subject_id, slug, sort_order)
    values (
      p_subject_id,
      v_slug,
      coalesce(
        (select max(sort_order) + 1 from public.topics where subject_id = p_subject_id),
        1
      )
    )
    returning id into v_topic_id;
    v_version := 1;
  else
    if not exists (
      select 1 from public.topics
      where id = p_topic_id and subject_id = p_subject_id
    ) then
      raise exception using errcode = 'NL014', message = 'Unknown topic.';
    end if;
    if exists (
      select 1 from public.topic_versions
      where topic_id = p_topic_id and status = 'draft'
    ) then
      raise exception using
        errcode = 'NL015',
        message = 'This topic already has a draft. Publish or archive it first.';
    end if;
    v_topic_id := p_topic_id;
    select coalesce(max(version), 0) + 1 into v_version
    from public.topic_versions
    where topic_id = v_topic_id;
  end if;

  insert into public.topic_versions (
    topic_id, subject_version_id, version, title, title_ur, objectives,
    estimated_minutes, resources, status, duration_seconds,
    video_provider, video_ref
  ) values (
    v_topic_id, v_subject_version_id, v_version, v_title, p_title_ur,
    coalesce(p_objectives, '{}'), p_estimated_minutes,
    coalesce(p_resources, '[]'::jsonb), 'draft', p_duration_seconds,
    v_provider, v_ref
  )
  returning * into v_row;

  if p_requires_topic_id is not null then
    if p_requires_topic_id = v_topic_id then
      raise exception using
        errcode = 'NL020',
        message = 'A topic cannot require itself.';
    end if;
    insert into public.topic_prerequisites (topic_id, requires_topic_id)
    values (v_topic_id, p_requires_topic_id)
    on conflict do nothing;
  end if;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'superadmin', 'create', 'topic_version', v_row.id::text,
    jsonb_build_object(
      'topic_id', v_topic_id,
      'subject_id', p_subject_id,
      'slug', v_slug,
      'version', v_version
    )
  );

  return jsonb_build_object(
    'topic_id', v_topic_id,
    'topic_slug', v_slug,
    'topic_version_id', v_row.id,
    'topic_version', v_row.version,
    'title', v_row.title,
    'title_ur', v_row.title_ur,
    'status', v_row.status,
    'estimated_minutes', v_row.estimated_minutes,
    'duration_seconds', v_row.duration_seconds,
    'video_provider', v_row.video_provider,
    'video_ref', v_row.video_ref,
    'objectives', v_row.objectives,
    'subject_version_id', v_subject_version_id
  );
end;
$fn$;

revoke all on function public.create_topic_draft(
  uuid, text, text, text, text[], integer, integer, text, text, jsonb, uuid, uuid
) from public, anon;
grant execute on function public.create_topic_draft(
  uuid, text, text, text, text[], integer, integer, text, text, jsonb, uuid, uuid
) to authenticated, service_role;

create or replace function public.publish_topic_version(p_version_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_row public.topic_versions%rowtype;
  v_subject_status text;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NL010',
      message = 'Only platform admins can publish Learning Stack content.';
  end if;

  select * into v_row from public.topic_versions
  where id = p_version_id for update;

  if not found then
    raise exception using errcode = 'NL014', message = 'Unknown topic version.';
  end if;

  if v_row.status = 'published' then
    return jsonb_build_object(
      'topic_version_id', v_row.id,
      'status', v_row.status
    );
  end if;

  if v_row.status <> 'draft' then
    raise exception using
      errcode = 'NL016',
      message = 'Only drafts can be published.';
  end if;

  select status into v_subject_status
  from public.subject_versions
  where id = v_row.subject_version_id;

  if v_subject_status <> 'published' then
    raise exception using
      errcode = 'NL021',
      message = 'Publish the subject version before publishing its topics.';
  end if;

  if btrim(v_row.title) = ''
     or nullif(btrim(coalesce(v_row.video_provider, '')), '') is null
     or nullif(btrim(coalesce(v_row.video_ref, '')), '') is null then
    raise exception using
      errcode = 'NL022',
      message = 'Topic publish requires title and valid video media metadata.';
  end if;

  update public.topic_versions
  set status = 'archived', updated_at = timezone('utc', now())
  where topic_id = v_row.topic_id
    and status = 'published'
    and id <> p_version_id;

  update public.topic_versions
  set status = 'published',
      published_at = timezone('utc', now()),
      updated_at = timezone('utc', now())
  where id = p_version_id
  returning * into v_row;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'superadmin', 'update', 'topic_version', v_row.id::text,
    jsonb_build_object('status', 'published', 'topic_id', v_row.topic_id)
  );

  return jsonb_build_object(
    'topic_version_id', v_row.id,
    'status', v_row.status,
    'topic_id', v_row.topic_id,
    'published_at', v_row.published_at
  );
end;
$fn$;

revoke all on function public.publish_topic_version(uuid) from public, anon;
grant execute on function public.publish_topic_version(uuid)
  to authenticated, service_role;

create or replace function public.archive_topic_version(p_version_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_row public.topic_versions%rowtype;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NL010',
      message = 'Only platform admins can archive Learning Stack content.';
  end if;

  select * into v_row from public.topic_versions
  where id = p_version_id for update;

  if not found then
    raise exception using errcode = 'NL014', message = 'Unknown topic version.';
  end if;

  if v_row.status = 'archived' then
    return jsonb_build_object(
      'topic_version_id', v_row.id,
      'status', v_row.status
    );
  end if;

  if v_row.status <> 'published' then
    raise exception using
      errcode = 'NL017',
      message = 'Only published topics can be archived.';
  end if;

  update public.topic_versions
  set status = 'archived', updated_at = timezone('utc', now())
  where id = p_version_id
  returning * into v_row;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'superadmin', 'update', 'topic_version', v_row.id::text,
    jsonb_build_object('status', 'archived', 'topic_id', v_row.topic_id)
  );

  return jsonb_build_object(
    'topic_version_id', v_row.id,
    'status', v_row.status,
    'topic_id', v_row.topic_id
  );
end;
$fn$;

revoke all on function public.archive_topic_version(uuid) from public, anon;
grant execute on function public.archive_topic_version(uuid)
  to authenticated, service_role;
