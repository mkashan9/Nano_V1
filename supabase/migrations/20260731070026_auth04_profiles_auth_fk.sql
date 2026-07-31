-- AUTH-04: profiles must not outlive their auth identity.
-- Bina is an RLS fixture that predates AUTH-01; give her an auth user first.
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at, confirmation_token, recovery_token,
  email_change_token_new, email_change, is_sso_user, is_anonymous
) values (
  '00000000-0000-0000-0000-000000000000',
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  'authenticated', 'authenticated',
  'bina@beta.nano.dev',
  crypt('NanoBinaDev1!', gen_salt('bf')),
  timezone('utc', now()),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"display_name":"Bina Beta","account_kind":"school_student"}'::jsonb,
  timezone('utc', now()), timezone('utc', now()),
  '', '', '', '', false, false
)
on conflict (id) do nothing;

insert into auth.identities (
  id, user_id, identity_data, provider, provider_id,
  last_sign_in_at, created_at, updated_at
)
select
  gen_random_uuid(),
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  jsonb_build_object(
    'sub', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    'email', 'bina@beta.nano.dev',
    'email_verified', true
  ),
  'email',
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  timezone('utc', now()), timezone('utc', now()), timezone('utc', now())
where not exists (
  select 1 from auth.identities i
  where i.user_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
    and i.provider = 'email'
);

alter table public.profiles
  drop constraint if exists profiles_id_auth_users_fkey;

alter table public.profiles
  add constraint profiles_id_auth_users_fkey
  foreign key (id) references auth.users (id) on delete cascade;
