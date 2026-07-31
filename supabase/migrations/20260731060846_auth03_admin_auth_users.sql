-- AUTH-03: platform + school admin auth fixtures

insert into public.profiles (id, display_name, account_kind, status)
values (
  'ffffffff-ffff-ffff-ffff-ffffffffffff',
  'Alpha School Admin',
  'school_staff',
  'active'
)
on conflict (id) do update set
  display_name = excluded.display_name,
  account_kind = excluded.account_kind,
  status = excluded.status,
  updated_at = timezone('utc', now());

insert into public.school_memberships (school_id, user_id, role, status)
select
  '11111111-1111-1111-1111-111111111111',
  'ffffffff-ffff-ffff-ffff-ffffffffffff',
  'school_admin',
  'active'
where not exists (
  select 1 from public.school_memberships sm
  where sm.school_id = '11111111-1111-1111-1111-111111111111'
    and sm.user_id = 'ffffffff-ffff-ffff-ffff-ffffffffffff'
    and sm.role = 'school_admin'
);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at, confirmation_token, recovery_token,
  email_change_token_new, email_change, is_sso_user, is_anonymous
) values (
  '00000000-0000-0000-0000-000000000000',
  'dddddddd-dddd-dddd-dddd-dddddddddddd',
  'authenticated', 'authenticated',
  'platform@nano.dev',
  crypt('NanoPlatformDev1!', gen_salt('bf')),
  timezone('utc', now()),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"display_name":"Platform Admin"}'::jsonb,
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
  'dddddddd-dddd-dddd-dddd-dddddddddddd',
  jsonb_build_object(
    'sub', 'dddddddd-dddd-dddd-dddd-dddddddddddd',
    'email', 'platform@nano.dev',
    'email_verified', true
  ),
  'email',
  'dddddddd-dddd-dddd-dddd-dddddddddddd',
  timezone('utc', now()), timezone('utc', now()), timezone('utc', now())
where not exists (
  select 1 from auth.identities i
  where i.user_id = 'dddddddd-dddd-dddd-dddd-dddddddddddd'
    and i.provider = 'email'
);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at, confirmation_token, recovery_token,
  email_change_token_new, email_change, is_sso_user, is_anonymous
) values (
  '00000000-0000-0000-0000-000000000000',
  'ffffffff-ffff-ffff-ffff-ffffffffffff',
  'authenticated', 'authenticated',
  'admin@alpha.nano.dev',
  crypt('NanoSchoolAdminDev1!', gen_salt('bf')),
  timezone('utc', now()),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"display_name":"Alpha School Admin"}'::jsonb,
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
  'ffffffff-ffff-ffff-ffff-ffffffffffff',
  jsonb_build_object(
    'sub', 'ffffffff-ffff-ffff-ffff-ffffffffffff',
    'email', 'admin@alpha.nano.dev',
    'email_verified', true
  ),
  'email',
  'ffffffff-ffff-ffff-ffff-ffffffffffff',
  timezone('utc', now()), timezone('utc', now()), timezone('utc', now())
where not exists (
  select 1 from auth.identities i
  where i.user_id = 'ffffffff-ffff-ffff-ffff-ffffffffffff'
    and i.provider = 'email'
);

update public.app_health
set notes = 'AUTH-03 platform + school admin fixtures',
    updated_at = timezone('utc', now())
where id = 'default';
