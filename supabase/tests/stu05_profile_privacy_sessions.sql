-- STU-05 adversarial checks: privacy rows are owner-only, and session
-- revocation only ever touches your own session and leaves an audit row.

-- Ali (school student) owns his privacy row and can revoke his own session.
begin;
set local role authenticated;
set local request.jwt.claims = '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

insert into public.privacy_settings (user_id, discoverable)
values (auth.uid(), false)
on conflict (user_id) do update set discoverable = false;

do $$
begin
  begin
    insert into public.privacy_settings (user_id, discoverable)
    values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', false);
    raise exception 'FAIL: wrote privacy settings for another learner';
  exception when insufficient_privilege then null;
  end;

  -- device_sessions has no client write policy; a direct update must fail.
  begin
    update public.device_sessions
    set revoked_at = timezone('utc', now())
    where id = 'f1111111-1111-1111-1111-111111111111';
    if found then
      raise exception 'FAIL: revoked a session by direct table write';
    end if;
  exception when insufficient_privilege then null;
  end;

  -- Already-revoked sessions are not revocable again.
  begin
    perform public.revoke_device_session('f2222222-2222-2222-2222-222222222222');
    raise exception 'FAIL: re-revoked an already revoked session';
  exception when insufficient_privilege then null;
  end;
end $$;

-- The supported path works and audits.
select public.revoke_device_session('f1111111-1111-1111-1111-111111111111');

select 'ali_active_sessions' as check, count(*)
from public.device_sessions
where user_id = auth.uid() and revoked_at is null;

select 'ali_revoke_audit_rows' as check, count(*)
from public.login_events
where user_id = auth.uid() and event_kind = 'revoke';

rollback;

-- Bina (another school student) cannot revoke Ali's session.
begin;
set local role authenticated;
set local request.jwt.claims = '{"sub":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","role":"authenticated"}';

do $$
begin
  begin
    perform public.revoke_device_session('f1111111-1111-1111-1111-111111111111');
    raise exception 'FAIL: revoked another learner session';
  exception when insufficient_privilege then null;
  end;
end $$;

select 'bina_visible_privacy_rows' as check, count(*) from public.privacy_settings;
rollback;

-- Ms Khan (teacher) has no revoke path into a student session either.
begin;
set local role authenticated;
set local request.jwt.claims = '{"sub":"cccccccc-cccc-cccc-cccc-cccccccccccc","role":"authenticated"}';

do $$
begin
  begin
    perform public.revoke_device_session('f1111111-1111-1111-1111-111111111111');
    raise exception 'FAIL: teacher revoked a student session';
  exception when insufficient_privilege then null;
  end;
end $$;
rollback;

-- Platform admin can read sessions for support but has no privacy read path.
begin;
set local role authenticated;
set local request.jwt.claims = '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';
select 'platform_admin_visible_privacy_rows' as check, count(*)
from public.privacy_settings;
rollback;
