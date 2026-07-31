-- STU-02 adversarial checks: personal preferences are owner-only.
-- Platform admins have no read path; blank companion names are rejected.

begin;
set local role authenticated;
set local request.jwt.claims = '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

insert into public.student_preferences (user_id, companion_name, locale)
values (auth.uid(), 'Tara', 'ur');

do $$
begin
  begin
    insert into public.student_preferences (user_id, companion_name)
    values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Sneaky');
    raise exception 'FAIL: wrote preferences for another learner';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.student_preferences (user_id, companion_name)
    values (auth.uid(), '   ');
    raise exception 'FAIL: blank companion name accepted';
  exception when check_violation or unique_violation then null;
  end;
end $$;

select 'ali_rows' as check, count(*) from public.student_preferences;
rollback;

begin;
set local role authenticated;
set local request.jwt.claims = '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';
select 'platform_admin_visible_rows' as check, count(*) from public.student_preferences;
rollback;
