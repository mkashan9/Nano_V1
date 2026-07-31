-- STU-01 adversarial checks: onboarding progress is per-learner and
-- students-only. Run against the development project.

-- Ali owns his row and cannot write anyone else's.
begin;
set local role authenticated;
set local request.jwt.claims = '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

insert into public.student_onboarding (user_id, current_step)
values (auth.uid(), 'experience');
select 'ali_visible_rows' as check, count(*) from public.student_onboarding;

do $$
begin
  begin
    insert into public.student_onboarding (user_id, current_step)
    values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'welcome');
    raise exception 'FAIL: wrote onboarding for another user';
  exception when insufficient_privilege then null;
  end;
end $$;
rollback;

-- Ms Khan is a teacher: no onboarding row, no visibility into student rows.
begin;
set local role authenticated;
set local request.jwt.claims = '{"sub":"cccccccc-cccc-cccc-cccc-cccccccccccc","role":"authenticated"}';
do $$
begin
  begin
    insert into public.student_onboarding (user_id, current_step)
    values (auth.uid(), 'welcome');
    raise exception 'FAIL: teacher created onboarding row';
  exception when insufficient_privilege then null;
  end;
end $$;
select 'teacher_visible_rows' as check, count(*) from public.student_onboarding;
rollback;
