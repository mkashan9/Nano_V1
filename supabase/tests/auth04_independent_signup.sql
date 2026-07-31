-- AUTH-04 adversarial checks: self-service signup provisions exactly one
-- independent profile, never a privileged one, and never a school membership.
do $$
declare
  v_id uuid := '0a0a0a0a-0000-4000-8000-00000000a001';
  v_staff_id uuid := '0a0a0a0a-0000-4000-8000-00000000a002';
  v_kind text;
  v_name text;
  v_school_count int;
begin
  delete from auth.users where id in (v_id, v_staff_id);

  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at, confirmation_token, recovery_token,
    email_change_token_new, email_change, is_sso_user, is_anonymous
  ) values (
    '00000000-0000-0000-0000-000000000000', v_id, 'authenticated', 'authenticated',
    'trigger-probe@nano.dev', crypt('NanoProbe1!', gen_salt('bf')),
    timezone('utc', now()),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"account_kind":"independent_student","display_name":"Probe Learner"}'::jsonb,
    timezone('utc', now()), timezone('utc', now()), '', '', '', '', false, false
  );

  select account_kind::text, display_name into v_kind, v_name
  from public.profiles where id = v_id;
  select count(*) into v_school_count
  from public.school_memberships where user_id = v_id;

  if v_kind is distinct from 'independent_student' then
    raise exception 'expected independent_student profile, got %', coalesce(v_kind, 'NULL');
  end if;
  if v_name is distinct from 'Probe Learner' then
    raise exception 'expected metadata display name, got %', coalesce(v_name, 'NULL');
  end if;
  if v_school_count <> 0 then
    raise exception 'independent signup must not create memberships';
  end if;

  -- Forged metadata claiming a privileged kind must be ignored.
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at, confirmation_token, recovery_token,
    email_change_token_new, email_change, is_sso_user, is_anonymous
  ) values (
    '00000000-0000-0000-0000-000000000000', v_staff_id, 'authenticated', 'authenticated',
    'escalation-probe@nano.dev', crypt('NanoProbe1!', gen_salt('bf')),
    timezone('utc', now()),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"account_kind":"platform","display_name":"Sneaky"}'::jsonb,
    timezone('utc', now()), timezone('utc', now()), '', '', '', '', false, false
  );
  if exists (select 1 from public.profiles where id = v_staff_id) then
    raise exception 'privileged account_kind must not be auto-provisioned';
  end if;

  delete from auth.users where id in (v_id, v_staff_id);
  if exists (select 1 from public.profiles where id in (v_id, v_staff_id)) then
    raise exception 'profile should cascade with auth user';
  end if;

  raise notice 'AUTH-04 trigger OK';
end $$;
