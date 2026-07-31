-- AUTH-04: signup is not a login, so the trigger only provisions the profile.
create or replace function nano_internal.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_kind text := coalesce(new.raw_user_meta_data ->> 'account_kind', '');
  v_name text := coalesce(nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''), 'Student');
begin
  -- Only self-service independent students are auto-provisioned; privileged
  -- kinds stay owned by admin flows even if the client forges metadata.
  if v_kind <> 'independent_student' then
    return new;
  end if;

  insert into public.profiles (id, display_name, account_kind, status)
  values (new.id, v_name, 'independent_student'::public.account_kind, 'active'::public.membership_status)
  on conflict (id) do nothing;

  return new;
end;
$$;

delete from public.login_events where user_agent = 'auth04-signup';

-- Session telemetry must not outlive the account it describes.
alter table public.login_events
  drop constraint if exists login_events_user_id_fkey;
alter table public.login_events
  add constraint login_events_user_id_fkey
  foreign key (user_id) references public.profiles (id) on delete cascade;

alter table public.device_sessions
  drop constraint if exists device_sessions_user_id_fkey;
alter table public.device_sessions
  add constraint device_sessions_user_id_fkey
  foreign key (user_id) references public.profiles (id) on delete cascade;
