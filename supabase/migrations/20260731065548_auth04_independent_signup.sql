-- AUTH-04: server-side profile bootstrap for independent student signup.
-- Clients never insert profiles directly; the trigger owns that write.

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
  -- Only self-service independent students are auto-provisioned.
  if v_kind <> 'independent_student' then
    return new;
  end if;

  insert into public.profiles (id, display_name, account_kind, status)
  values (new.id, v_name, 'independent_student'::public.account_kind, 'active'::public.membership_status)
  on conflict (id) do nothing;

  insert into public.login_events (user_id, event_kind, user_agent)
  values (new.id, 'success'::public.login_event_kind, 'auth04-signup')
  on conflict do nothing;

  return new;
end;
$$;

revoke all on function nano_internal.handle_new_auth_user() from public, anon, authenticated;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function nano_internal.handle_new_auth_user();

-- Independent fixture (profile already seeded in SEC-02).
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at, confirmation_token, recovery_token,
  email_change_token_new, email_change, is_sso_user, is_anonymous
) values (
  '00000000-0000-0000-0000-000000000000',
  'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
  'authenticated', 'authenticated',
  'indie@nano.dev',
  crypt('NanoIndieDev1!', gen_salt('bf')),
  timezone('utc', now()),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"display_name":"Indie Ali","account_kind":"independent_student"}'::jsonb,
  timezone('utc', now()), timezone('utc', now()),
  '', '', '', '', false, false
)
on conflict (id) do update set
  email = excluded.email,
  encrypted_password = excluded.encrypted_password,
  email_confirmed_at = coalesce(auth.users.email_confirmed_at, excluded.email_confirmed_at),
  updated_at = timezone('utc', now());

insert into auth.identities (
  id, user_id, identity_data, provider, provider_id,
  last_sign_in_at, created_at, updated_at
)
select
  gen_random_uuid(),
  'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
  jsonb_build_object(
    'sub', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
    'email', 'indie@nano.dev',
    'email_verified', true
  ),
  'email',
  'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
  timezone('utc', now()), timezone('utc', now()), timezone('utc', now())
where not exists (
  select 1 from auth.identities i
  where i.user_id = 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee'
    and i.provider = 'email'
);

update public.app_health
set schema_version = 'AUTH-04',
    notes = 'Independent signup trigger + indie fixture',
    updated_at = timezone('utc', now())
where id = 'default';
