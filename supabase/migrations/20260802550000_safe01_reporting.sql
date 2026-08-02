-- SAFE-01: learner reports + optional block. Moderation queue stays SAFE-02.

create table if not exists public.user_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles (id) on delete cascade,
  reported_id uuid not null references public.profiles (id) on delete cascade,
  category text not null
    check (category in (
      'harassment', 'spam', 'inappropriate', 'impersonation', 'other'
    )),
  details text,
  status text not null default 'open'
    check (status in ('open', 'under_review', 'resolved', 'dismissed')),
  also_blocked boolean not null default false,
  evidence jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint user_reports_not_self check (reporter_id <> reported_id),
  constraint user_reports_details_len check (
    details is null or char_length(details) <= 500
  )
);

create index if not exists user_reports_reporter_idx
  on public.user_reports (reporter_id, created_at desc);

create index if not exists user_reports_reported_idx
  on public.user_reports (reported_id, created_at desc);

create index if not exists user_reports_open_idx
  on public.user_reports (status, created_at desc)
  where status in ('open', 'under_review');

alter table public.user_reports enable row level security;

revoke all on table public.user_reports from public, anon, authenticated;
grant all on table public.user_reports to service_role;

-- Peek peer token without consuming (remove/unblock still work).
create or replace function nano_internal.lookup_friend_peer_token(
  p_owner uuid,
  p_token text,
  p_purposes text[]
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $fn$
declare
  v_peer uuid;
begin
  delete from public.friend_peer_tokens
  where expires_at <= timezone('utc', now());

  select peer_id into v_peer
  from public.friend_peer_tokens
  where token = p_token
    and owner_id = p_owner
    and purpose = any (p_purposes)
    and expires_at > timezone('utc', now());

  return v_peer;
end;
$fn$;

create or replace function nano_internal.user_report_projection(
  p_row public.user_reports
)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_username text;
begin
  select si.username into v_username
  from public.social_identities si
  where si.user_id = p_row.reported_id;

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
    'username', coalesce(p_row.evidence ->> 'username', v_username),
    'created_at', p_row.created_at
  );
end;
$fn$;

create or replace function nano_internal.insert_user_report(
  p_reporter uuid,
  p_reported uuid,
  p_category text,
  p_details text,
  p_also_block boolean
)
returns public.user_reports
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_cat text := lower(btrim(coalesce(p_category, '')));
  v_details text := nullif(btrim(coalesce(p_details, '')), '');
  v_username text;
  v_label text;
  v_row public.user_reports;
begin
  if v_cat not in (
    'harassment', 'spam', 'inappropriate', 'impersonation', 'other'
  ) then
    raise exception using errcode = 'NS040',
      message = 'Choose a valid report reason.';
  end if;

  if p_reported is null or p_reported = p_reporter then
    raise exception using errcode = 'NS024',
      message = 'No discoverable profile found.';
  end if;

  if exists (
    select 1 from public.user_reports
    where reporter_id = p_reporter
      and reported_id = p_reported
      and status in ('open', 'under_review')
      and created_at > timezone('utc', now()) - interval '24 hours'
  ) then
    raise exception using errcode = 'NS041',
      message = 'You already reported this learner recently.';
  end if;

  select si.username into v_username
  from public.social_identities si
  where si.user_id = p_reported;
  v_label := nano_internal.social_label_for(p_reported);

  insert into public.user_reports (
    reporter_id, reported_id, category, details, also_blocked, evidence
  ) values (
    p_reporter,
    p_reported,
    v_cat,
    v_details,
    coalesce(p_also_block, false),
    jsonb_build_object(
      'peer_label', v_label,
      'username', v_username,
      'context', 'user'
    )
  )
  returning * into v_row;

  if coalesce(p_also_block, false) then
    insert into public.blocks (blocker_id, blocked_id)
    values (p_reporter, p_reported)
    on conflict do nothing;

    delete from public.friendships
    where user_low = least(p_reporter, p_reported)
      and user_high = greatest(p_reporter, p_reported);

    update public.friend_requests
    set status = 'cancelled', responded_at = timezone('utc', now())
    where status = 'pending'
      and (
        (from_user_id = p_reporter and to_user_id = p_reported)
        or (from_user_id = p_reported and to_user_id = p_reporter)
      );
  end if;

  insert into public.audit_events (
    actor_user_id, actor_role, school_id, action, target_type, target_id,
    new_value, reason
  ) values (
    p_reporter,
    'student',
    null,
    'create'::public.audit_action_kind,
    'user_reports',
    v_row.id::text,
    jsonb_build_object(
      'category', v_cat,
      'also_blocked', coalesce(p_also_block, false)
    ),
    'submit_user_report'
  );

  return v_row;
end;
$fn$;

create or replace function public.submit_user_report(
  p_query text,
  p_category text,
  p_details text default null,
  p_also_block boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_uid uuid := auth.uid();
  v_target uuid;
  v_row public.user_reports;
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  v_target := nano_internal.resolve_social_target(p_query);
  if v_target is null or v_target = v_uid then
    raise exception using errcode = 'NS024', message = 'No discoverable profile found.';
  end if;

  v_row := nano_internal.insert_user_report(
    v_uid, v_target, p_category, p_details, p_also_block
  );
  return nano_internal.user_report_projection(v_row);
end;
$fn$;

create or replace function public.submit_user_report_for_peer(
  p_peer_token text,
  p_category text,
  p_details text default null,
  p_also_block boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_uid uuid := auth.uid();
  v_target uuid;
  v_row public.user_reports;
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  v_target := nano_internal.lookup_friend_peer_token(
    v_uid, p_peer_token, array['friend', 'block']
  );
  if v_target is null then
    raise exception using errcode = 'NS036',
      message = 'Report action expired. Refresh the list.';
  end if;

  v_row := nano_internal.insert_user_report(
    v_uid, v_target, p_category, p_details, p_also_block
  );
  return nano_internal.user_report_projection(v_row);
end;
$fn$;

create or replace function public.my_user_reports()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_uid uuid := auth.uid();
  v_items jsonb := '[]'::jsonb;
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  select coalesce(
    jsonb_agg(nano_internal.user_report_projection(r) order by r.created_at desc),
    '[]'::jsonb
  )
  into v_items
  from public.user_reports r
  where r.reporter_id = v_uid;

  return jsonb_build_object('reports', v_items);
end;
$fn$;

revoke all on function public.submit_user_report(text, text, text, boolean)
  from public, anon;
revoke all on function public.submit_user_report_for_peer(text, text, text, boolean)
  from public, anon;
revoke all on function public.my_user_reports() from public, anon;

grant execute on function public.submit_user_report(text, text, text, boolean)
  to authenticated, service_role;
grant execute on function public.submit_user_report_for_peer(text, text, text, boolean)
  to authenticated, service_role;
grant execute on function public.my_user_reports()
  to authenticated, service_role;
