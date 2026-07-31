-- AUTH-02: bind Ms Khan teacher profile UUID to auth.users
-- Development password documented in docs/modules/AUTH-02/MANUAL_TEST.md

insert into auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  recovery_token,
  email_change_token_new,
  email_change,
  is_sso_user,
  is_anonymous
) values (
  '00000000-0000-0000-0000-000000000000',
  'cccccccc-cccc-cccc-cccc-cccccccccccc',
  'authenticated',
  'authenticated',
  'teacher@alpha.nano.dev',
  crypt('NanoTeacherDev1!', gen_salt('bf')),
  timezone('utc', now()),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"display_name":"Ms. Khan"}'::jsonb,
  timezone('utc', now()),
  timezone('utc', now()),
  '',
  '',
  '',
  '',
  false,
  false
)
on conflict (id) do update set
  email = excluded.email,
  encrypted_password = excluded.encrypted_password,
  email_confirmed_at = coalesce(auth.users.email_confirmed_at, excluded.email_confirmed_at),
  updated_at = timezone('utc', now());

insert into auth.identities (
  id,
  user_id,
  identity_data,
  provider,
  provider_id,
  last_sign_in_at,
  created_at,
  updated_at
)
select
  gen_random_uuid(),
  'cccccccc-cccc-cccc-cccc-cccccccccccc',
  jsonb_build_object(
    'sub', 'cccccccc-cccc-cccc-cccc-cccccccccccc',
    'email', 'teacher@alpha.nano.dev',
    'email_verified', true
  ),
  'email',
  'cccccccc-cccc-cccc-cccc-cccccccccccc',
  timezone('utc', now()),
  timezone('utc', now()),
  timezone('utc', now())
where not exists (
  select 1 from auth.identities i
  where i.user_id = 'cccccccc-cccc-cccc-cccc-cccccccccccc'
    and i.provider = 'email'
);

update public.app_health
set notes = 'AUTH-02 teacher fixture Ms Khan bound',
    updated_at = timezone('utc', now())
where id = 'default';
