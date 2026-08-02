-- SAFE-03: rate limits, restricted terms, and link allowlist (server-side).

create table if not exists public.safety_rate_limits (
  action_key text primary key,
  window_seconds integer not null check (window_seconds > 0),
  max_count integer not null check (max_count >= 0),
  is_enabled boolean not null default true,
  notes text,
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.safety_rate_limits is
  'SAFE-03 per-action flood limits. max_count 0 disables the action.';

create table if not exists public.safety_rate_usage (
  user_id uuid not null references public.profiles (id) on delete cascade,
  action_key text not null references public.safety_rate_limits (action_key)
    on delete cascade,
  window_start timestamptz not null,
  hit_count integer not null default 0 check (hit_count >= 0),
  primary key (user_id, action_key, window_start)
);

create index if not exists safety_rate_usage_window_idx
  on public.safety_rate_usage (action_key, window_start);

create table if not exists public.restricted_terms (
  id uuid primary key default gen_random_uuid(),
  term text not null,
  match_mode text not null default 'contains'
    check (match_mode in ('exact', 'contains')),
  is_enabled boolean not null default true,
  notes text,
  constraint restricted_terms_term_len check (char_length(term) between 2 and 80)
);

create unique index if not exists restricted_terms_term_uidx
  on public.restricted_terms (lower(term), match_mode);

create table if not exists public.link_allowlist_hosts (
  host text primary key,
  is_enabled boolean not null default true,
  notes text,
  constraint link_allowlist_host_lower check (host = lower(host))
);

alter table public.safety_rate_limits enable row level security;
alter table public.safety_rate_usage enable row level security;
alter table public.restricted_terms enable row level security;
alter table public.link_allowlist_hosts enable row level security;

drop policy if exists safety_rate_limits_select on public.safety_rate_limits;
create policy safety_rate_limits_select on public.safety_rate_limits
  for select to authenticated
  using (nano_internal.is_platform_admin());

drop policy if exists restricted_terms_select on public.restricted_terms;
create policy restricted_terms_select on public.restricted_terms
  for select to authenticated
  using (nano_internal.is_platform_admin());

drop policy if exists link_allowlist_hosts_select on public.link_allowlist_hosts;
create policy link_allowlist_hosts_select on public.link_allowlist_hosts
  for select to authenticated
  using (nano_internal.is_platform_admin());

-- Usage is internal-only; no authenticated policies.
revoke all on table public.safety_rate_limits from public, anon;
revoke all on table public.safety_rate_usage from public, anon;
revoke all on table public.restricted_terms from public, anon;
revoke all on table public.link_allowlist_hosts from public, anon;
grant select on table public.safety_rate_limits to authenticated;
grant select on table public.restricted_terms to authenticated;
grant select on table public.link_allowlist_hosts to authenticated;
grant all on table public.safety_rate_limits to service_role;
grant all on table public.safety_rate_usage to service_role;
grant all on table public.restricted_terms to service_role;
grant all on table public.link_allowlist_hosts to service_role;
revoke insert, update, delete on table public.safety_rate_limits from authenticated;
revoke insert, update, delete on table public.restricted_terms from authenticated;
revoke insert, update, delete on table public.link_allowlist_hosts from authenticated;

insert into public.safety_rate_limits
  (action_key, window_seconds, max_count, notes)
values
  ('friend_request', 3600, 20, 'New friend requests per hour.'),
  ('user_report', 3600, 10, 'New reports per hour (per-target 24h still applies).'),
  ('community_message', 3600, 30, 'Future COM-04 message flood limit.')
on conflict (action_key) do nothing;

insert into public.restricted_terms (term, match_mode, notes)
select * from (values
  ('nano_banned_phrase_test', 'contains', 'Fixture term for SAFE-03 tests.'),
  ('kill yourself', 'contains', 'Self-harm phrase block.'),
  ('kys', 'exact', 'Self-harm acronym.')
) as v(term, match_mode, notes)
where not exists (
  select 1 from public.restricted_terms r
  where lower(r.term) = lower(v.term) and r.match_mode = v.match_mode
);

-- Empty allowlist rejects all URLs; seed learning hosts only.
insert into public.link_allowlist_hosts (host, notes)
values
  ('youtube.com', 'Learning video embeds'),
  ('www.youtube.com', 'Learning video embeds'),
  ('youtu.be', 'Learning video short links')
on conflict (host) do nothing;

create or replace function nano_internal.assert_rate_limit(
  p_user_id uuid,
  p_action_key text
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $fn$
declare
  v_limit public.safety_rate_limits%rowtype;
  v_window_start timestamptz;
  v_count integer;
begin
  if p_user_id is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  select * into v_limit
  from public.safety_rate_limits
  where action_key = p_action_key;

  if not found or not v_limit.is_enabled then
    return;
  end if;

  if v_limit.max_count = 0 then
    raise exception using errcode = 'NS060',
      message = 'This action is temporarily disabled.';
  end if;

  v_window_start := to_timestamp(
    floor(
      extract(epoch from timezone('utc', now())) / v_limit.window_seconds
    ) * v_limit.window_seconds
  );

  insert into public.safety_rate_usage (user_id, action_key, window_start, hit_count)
  values (p_user_id, p_action_key, v_window_start, 1)
  on conflict (user_id, action_key, window_start)
  do update set hit_count = public.safety_rate_usage.hit_count + 1
  returning hit_count into v_count;

  if v_count > v_limit.max_count then
    raise exception using errcode = 'NS061',
      message = 'Too many attempts. Please wait and try again.';
  end if;
end;
$fn$;

create or replace function nano_internal.extract_url_hosts(p_text text)
returns text[]
language plpgsql
immutable
set search_path = pg_catalog, public
as $fn$
declare
  v_text text := coalesce(p_text, '');
  v_matches text[];
  v_hosts text[] := '{}';
  v_m text;
  v_host text;
begin
  if v_text = '' then
    return v_hosts;
  end if;

  select coalesce(array_agg(m[1]), '{}')
  into v_matches
  from regexp_matches(
    v_text,
    '(?i)(?:https?://|www\.)([^[:space:]<>]+)',
    'g'
  ) as m;

  if v_matches is null then
    return '{}';
  end if;

  foreach v_m in array v_matches loop
    v_host := lower(split_part(split_part(v_m, '/', 1), '?', 1));
    v_host := regexp_replace(v_host, ':\d+$', '');
    if v_host <> '' then
      v_hosts := array_append(v_hosts, v_host);
    end if;
  end loop;

  return v_hosts;
end;
$fn$;

create or replace function nano_internal.assert_text_allowed(p_text text)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $fn$
declare
  v_text text := coalesce(p_text, '');
  v_norm text := lower(v_text);
  v_term public.restricted_terms%rowtype;
  v_hosts text[];
  v_host text;
  v_allowed boolean;
begin
  if btrim(v_text) = '' then
    return;
  end if;

  for v_term in
    select * from public.restricted_terms where is_enabled
  loop
    if v_term.match_mode = 'exact' then
      if v_norm = lower(v_term.term) then
        raise exception using errcode = 'NS062',
          message = 'That message contains restricted content.';
      end if;
    elsif position(lower(v_term.term) in v_norm) > 0 then
      raise exception using errcode = 'NS062',
        message = 'That message contains restricted content.';
    end if;
  end loop;

  v_hosts := nano_internal.extract_url_hosts(v_text);
  foreach v_host in array v_hosts loop
    select exists (
      select 1 from public.link_allowlist_hosts h
      where h.is_enabled
        and (
          h.host = v_host
          or v_host like '%.' || h.host
        )
    ) into v_allowed;

    if not v_allowed then
      raise exception using errcode = 'NS063',
        message = 'That link is not allowed.';
    end if;
  end loop;
end;
$fn$;

create or replace function nano_internal.assert_community_message_allowed(
  p_user_id uuid,
  p_text text
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
begin
  perform nano_internal.assert_rate_limit(p_user_id, 'community_message');
  perform nano_internal.assert_text_allowed(p_text);
end;
$fn$;

-- Authenticated preview helper for clients / tests (no usage increment).
create or replace function public.check_safety_text(p_text text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
begin
  if auth.uid() is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  begin
    perform nano_internal.assert_text_allowed(p_text);
  exception
    when others then
      return jsonb_build_object(
        'allowed', false,
        'code', sqlstate,
        'message', sqlerrm
      );
  end;

  return jsonb_build_object('allowed', true);
end;
$fn$;

create or replace function public.my_safety_rate_status(p_action_key text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $fn$
declare
  v_uid uuid := auth.uid();
  v_limit public.safety_rate_limits%rowtype;
  v_window_start timestamptz;
  v_count integer := 0;
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  select * into v_limit
  from public.safety_rate_limits
  where action_key = p_action_key;

  if not found then
    return jsonb_build_object(
      'action_key', p_action_key,
      'configured', false
    );
  end if;

  v_window_start := to_timestamp(
    floor(
      extract(epoch from timezone('utc', now())) / v_limit.window_seconds
    ) * v_limit.window_seconds
  );

  select coalesce(u.hit_count, 0) into v_count
  from public.safety_rate_usage u
  where u.user_id = v_uid
    and u.action_key = p_action_key
    and u.window_start = v_window_start;

  return jsonb_build_object(
    'action_key', p_action_key,
    'configured', true,
    'is_enabled', v_limit.is_enabled,
    'window_seconds', v_limit.window_seconds,
    'max_count', v_limit.max_count,
    'used', coalesce(v_count, 0),
    'remaining', greatest(v_limit.max_count - coalesce(v_count, 0), 0)
  );
end;
$fn$;

-- Gate friend requests (only when creating a new pending row).
create or replace function public.send_friend_request(p_query text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_uid uuid := auth.uid();
  v_target uuid;
  v_privacy public.privacy_settings%rowtype;
  v_row public.friend_requests%rowtype;
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  v_target := nano_internal.resolve_social_target(p_query);
  if v_target is null or v_target = v_uid then
    raise exception using errcode = 'NS024', message = 'No discoverable profile found.';
  end if;

  if nano_internal.are_blocked(v_uid, v_target) then
    raise exception using errcode = 'NS024', message = 'No discoverable profile found.';
  end if;

  if nano_internal.are_friends(v_uid, v_target) then
    raise exception using errcode = 'NS030', message = 'Already friends.';
  end if;

  select * into v_privacy from public.privacy_settings where user_id = v_target;
  if found and (
       not coalesce(v_privacy.discoverable, true)
    or not coalesce(v_privacy.allow_friend_requests, true)
  ) then
    raise exception using errcode = 'NS031', message = 'This learner is not accepting requests.';
  end if;

  if exists (
    select 1 from public.friend_requests
    where from_user_id = v_target and to_user_id = v_uid and status = 'pending'
  ) then
    raise exception using errcode = 'NS032',
      message = 'They already sent you a request — open Friends to respond.';
  end if;

  if exists (
    select 1 from public.friend_requests
    where from_user_id = v_uid and to_user_id = v_target and status = 'pending'
  ) then
    select * into v_row
    from public.friend_requests
    where from_user_id = v_uid and to_user_id = v_target and status = 'pending';
    return nano_internal.friend_request_projection(v_row, v_uid);
  end if;

  perform nano_internal.assert_rate_limit(v_uid, 'friend_request');

  insert into public.friend_requests (from_user_id, to_user_id, status)
  values (v_uid, v_target, 'pending')
  returning * into v_row;

  return nano_internal.friend_request_projection(v_row, v_uid);
end;
$fn$;

-- Gate reports: flood limit + details text/link policy.
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

  perform nano_internal.assert_rate_limit(p_reporter, 'user_report');
  perform nano_internal.assert_text_allowed(coalesce(v_details, ''));

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

revoke all on function nano_internal.assert_rate_limit(uuid, text) from public, anon;
revoke all on function nano_internal.assert_text_allowed(text) from public, anon;
revoke all on function nano_internal.assert_community_message_allowed(uuid, text)
  from public, anon;
revoke all on function public.check_safety_text(text) from public, anon;
revoke all on function public.my_safety_rate_status(text) from public, anon;

grant execute on function nano_internal.assert_rate_limit(uuid, text)
  to authenticated, service_role;
grant execute on function nano_internal.assert_text_allowed(text)
  to authenticated, service_role;
grant execute on function nano_internal.assert_community_message_allowed(uuid, text)
  to authenticated, service_role;
grant execute on function public.check_safety_text(text)
  to authenticated, service_role;
grant execute on function public.my_safety_rate_status(text)
  to authenticated, service_role;
grant execute on function public.send_friend_request(text)
  to authenticated, service_role;
