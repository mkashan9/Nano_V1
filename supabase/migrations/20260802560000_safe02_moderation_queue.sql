-- SAFE-02: platform moderation queue + evidence access for user_reports.

alter table public.user_reports
  add column if not exists resolution_action text
    check (
      resolution_action is null
      or resolution_action in ('dismiss', 'resolve', 'warn', 'suspend')
    ),
  add column if not exists resolution_note text
    check (
      resolution_note is null or char_length(resolution_note) <= 1000
    ),
  add column if not exists resolved_by uuid references public.profiles (id),
  add column if not exists resolved_at timestamptz;

create table if not exists public.moderation_evidence_access (
  id uuid primary key default gen_random_uuid(),
  report_id uuid not null references public.user_reports (id) on delete cascade,
  actor_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists moderation_evidence_access_report_idx
  on public.moderation_evidence_access (report_id, created_at desc);

alter table public.moderation_evidence_access enable row level security;
revoke all on table public.moderation_evidence_access
  from public, anon, authenticated;
grant all on table public.moderation_evidence_access to service_role;

create or replace function nano_internal.moderation_report_projection(
  p_row public.user_reports
)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_reported_username text;
  v_reporter_label text;
begin
  select si.username into v_reported_username
  from public.social_identities si
  where si.user_id = p_row.reported_id;

  v_reporter_label := nano_internal.social_label_for(p_row.reporter_id);

  return jsonb_build_object(
    'id', p_row.id,
    'category', p_row.category,
    'status', p_row.status,
    'details', p_row.details,
    'also_blocked', p_row.also_blocked,
    'peer_label', coalesce(
      p_row.evidence ->> 'peer_label',
      nano_internal.social_label_for(p_row.reported_id)
    ),
    'username', coalesce(p_row.evidence ->> 'username', v_reported_username),
    'reporter_label', v_reporter_label,
    'evidence', coalesce(p_row.evidence, '{}'::jsonb),
    'resolution_action', p_row.resolution_action,
    'resolution_note', p_row.resolution_note,
    'created_at', p_row.created_at,
    'updated_at', p_row.updated_at,
    'resolved_at', p_row.resolved_at
  );
end;
$fn$;

create or replace function public.list_user_reports_for_moderation(
  p_status text default null,
  p_limit integer default 50
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_status text := nullif(lower(btrim(coalesce(p_status, ''))), '');
  v_limit integer := greatest(1, least(coalesce(p_limit, 50), 100));
  v_items jsonb := '[]'::jsonb;
begin
  if not nano_internal.is_platform_admin() then
    raise exception using errcode = 'NS050',
      message = 'Moderation queue is limited to platform staff.';
  end if;

  if v_status is not null and v_status not in (
    'open', 'under_review', 'resolved', 'dismissed'
  ) then
    raise exception using errcode = 'NS051',
      message = 'Unknown report status filter.';
  end if;

  select coalesce(
    jsonb_agg(nano_internal.moderation_report_projection(r) order by r.created_at asc),
    '[]'::jsonb
  )
  into v_items
  from (
    select *
    from public.user_reports ur
    where (
      v_status is null and ur.status in ('open', 'under_review')
    ) or (
      v_status is not null and ur.status = v_status
    )
    order by ur.created_at asc
    limit v_limit
  ) r;

  return jsonb_build_object('reports', v_items);
end;
$fn$;

create or replace function public.claim_user_report(p_report_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_row public.user_reports;
begin
  if not nano_internal.is_platform_admin() then
    raise exception using errcode = 'NS050',
      message = 'Moderation queue is limited to platform staff.';
  end if;

  select * into v_row from public.user_reports where id = p_report_id for update;
  if v_row.id is null then
    raise exception using errcode = 'NS052', message = 'Report not found.';
  end if;

  if v_row.status = 'open' then
    update public.user_reports
    set status = 'under_review',
        updated_at = timezone('utc', now())
    where id = p_report_id
    returning * into v_row;
  end if;

  insert into public.moderation_evidence_access (report_id, actor_id)
  values (p_report_id, auth.uid());

  insert into public.audit_events (
    actor_user_id, actor_role, action, target_type, target_id,
    new_value, reason
  ) values (
    auth.uid(),
    'platform',
    'other'::public.audit_action_kind,
    'user_reports',
    p_report_id::text,
    jsonb_build_object('status', v_row.status, 'evidence_accessed', true),
    'claim_user_report'
  );

  return nano_internal.moderation_report_projection(v_row);
end;
$fn$;

create or replace function public.resolve_user_report(
  p_report_id uuid,
  p_action text,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_action text := lower(btrim(coalesce(p_action, '')));
  v_note text := nullif(btrim(coalesce(p_note, '')), '');
  v_row public.user_reports;
  v_next_status text;
begin
  if not nano_internal.is_platform_admin() then
    raise exception using errcode = 'NS050',
      message = 'Moderation queue is limited to platform staff.';
  end if;

  if v_action not in ('dismiss', 'resolve', 'warn', 'suspend') then
    raise exception using errcode = 'NS053',
      message = 'Choose dismiss, resolve, warn, or suspend.';
  end if;

  if v_note is null or v_note = '' then
    raise exception using errcode = 'NS054',
      message = 'A resolution note is required.';
  end if;

  select * into v_row from public.user_reports where id = p_report_id for update;
  if v_row.id is null then
    raise exception using errcode = 'NS052', message = 'Report not found.';
  end if;

  if v_row.status in ('resolved', 'dismissed') then
    raise exception using errcode = 'NS055',
      message = 'This report is already closed.';
  end if;

  v_next_status := case
    when v_action = 'dismiss' then 'dismissed'
    else 'resolved'
  end;

  if v_action = 'suspend' then
    perform public.set_profile_status(
      v_row.reported_id,
      'suspended',
      'SAFE-02 report ' || p_report_id::text || ': ' || v_note
    );
  end if;

  update public.user_reports
  set status = v_next_status,
      resolution_action = v_action,
      resolution_note = v_note,
      resolved_by = auth.uid(),
      resolved_at = timezone('utc', now()),
      updated_at = timezone('utc', now())
  where id = p_report_id
  returning * into v_row;

  insert into public.audit_events (
    actor_user_id, actor_role, action, target_type, target_id,
    new_value, reason
  ) values (
    auth.uid(),
    'platform',
    case
      when v_action = 'suspend' then 'suspend'::public.audit_action_kind
      when v_action = 'dismiss' then 'other'::public.audit_action_kind
      else 'update'::public.audit_action_kind
    end,
    'user_reports',
    p_report_id::text,
    jsonb_build_object(
      'resolution_action', v_action,
      'status', v_next_status
    ),
    v_note
  );

  return nano_internal.moderation_report_projection(v_row);
end;
$fn$;

revoke all on function public.list_user_reports_for_moderation(text, integer)
  from public, anon;
revoke all on function public.claim_user_report(uuid) from public, anon;
revoke all on function public.resolve_user_report(uuid, text, text)
  from public, anon;

grant execute on function public.list_user_reports_for_moderation(text, integer)
  to authenticated, service_role;
grant execute on function public.claim_user_report(uuid)
  to authenticated, service_role;
grant execute on function public.resolve_user_report(uuid, text, text)
  to authenticated, service_role;
