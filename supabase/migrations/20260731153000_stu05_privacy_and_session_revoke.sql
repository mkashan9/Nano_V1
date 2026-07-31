-- STU-05: privacy settings owned by the learner, plus a server-backed,
-- audited path for revoking one of your own device sessions.

create table if not exists public.privacy_settings (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  discoverable boolean not null default true,
  show_achievements boolean not null default true,
  allow_friend_requests boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.privacy_settings is
  'STU-05 learner privacy controls. Owner-only writes; social modules read '
  'through a safe projection, never the raw profile.';

alter table public.privacy_settings enable row level security;

drop trigger if exists privacy_settings_set_updated_at on public.privacy_settings;
create trigger privacy_settings_set_updated_at
  before update on public.privacy_settings
  for each row execute function public.set_updated_at();

drop policy if exists privacy_settings_select_self on public.privacy_settings;
create policy privacy_settings_select_self on public.privacy_settings
  for select to authenticated
  using (user_id = auth.uid());

drop policy if exists privacy_settings_insert_self on public.privacy_settings;
create policy privacy_settings_insert_self on public.privacy_settings
  for insert to authenticated
  with check (user_id = auth.uid() and nano_internal.is_student());

drop policy if exists privacy_settings_update_self on public.privacy_settings;
create policy privacy_settings_update_self on public.privacy_settings
  for update to authenticated
  using (user_id = auth.uid() and nano_internal.is_student())
  with check (user_id = auth.uid() and nano_internal.is_student());

-- device_sessions has no client write policy (SEC-03), so revocation goes
-- through this function. It lives in public because it is the first
-- client-callable RPC; nano_internal is deliberately not exposed over REST.
-- It only ever touches the caller's own active session and audits the result.
create or replace function public.revoke_device_session(p_session_id uuid)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_school_id uuid;
begin
  if not nano_internal.profile_is_active() then
    raise exception 'not permitted to revoke sessions'
      using errcode = 'insufficient_privilege';
  end if;

  update public.device_sessions ds
  set revoked_at = timezone('utc', now())
  where ds.id = p_session_id
    and ds.user_id = auth.uid()
    and ds.revoked_at is null
  returning ds.school_id into v_school_id;

  if not found then
    raise exception 'session not found or not yours'
      using errcode = 'insufficient_privilege';
  end if;

  insert into public.login_events (user_id, school_id, event_kind, user_agent)
  values (auth.uid(), v_school_id, 'revoke'::public.login_event_kind, 'stu05-self-revoke');
end;
$$;

comment on function public.revoke_device_session(uuid) is
  'STU-05 self-service device session revocation. Owner-only and audited to '
  'login_events; never revokes another user''s session.';

revoke all on function public.revoke_device_session(uuid) from public, anon;
grant execute on function public.revoke_device_session(uuid) to authenticated, service_role;

update public.app_health
set schema_version = 'STU-05',
    notes = 'Privacy settings + audited self-service session revoke',
    updated_at = timezone('utc', now())
where id = 'default';
