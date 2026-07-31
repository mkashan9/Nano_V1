-- LRN-01 adversarial checks: drafts stay invisible, eligibility and
-- prerequisite locks are decided server-side, and progress is owner-only.

-- Ali as a junior grade 3 learner.
begin;
set local role authenticated;
set local request.jwt.claims = '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

insert into public.student_onboarding (user_id, current_step, experience_track, self_reported_grade_level)
values (auth.uid(), 'ready', 'junior', 3)
on conflict (user_id) do update
set experience_track = 'junior', self_reported_grade_level = 3;

select 'junior_visible_subjects' as check, count(*) from public.learning_subjects;
select 'junior_draft_rows' as check, count(*)
from public.learning_catalog where subject_slug = 'coding';
select 'junior_senior_only_rows' as check, count(*)
from public.learning_catalog where subject_slug = 'science';
select 'junior_math_topic_version' as check, topic_version_id::text
from public.learning_catalog where topic_slug = 'counting';
select 'junior_addition_locked' as check, is_locked::text, coalesce(array_to_string(blocking_titles, ','), '')
from public.learning_catalog where topic_slug = 'addition';

do $$
begin
  -- No client write path into curated content.
  begin
    update public.subject_versions set title = 'Hacked'
    where id = '20000000-0000-0000-0000-000000000001';
    if found then
      raise exception 'FAIL: learner edited a published subject version';
    end if;
  exception when insufficient_privilege then null;
  end;

  -- Progress belongs to its owner only.
  begin
    insert into public.learning_progress (user_id, topic_version_id, status)
    values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
            '40000000-0000-0000-0000-000000000001', 'completed');
    raise exception 'FAIL: wrote progress for another learner';
  exception when insufficient_privilege then null;
  end;
end $$;

-- Completing the prerequisite unlocks the next topic (service role: clients
-- cannot write completion after LRN-02).
reset role;
insert into public.learning_progress (user_id, topic_version_id, status, progress, completed_at)
values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        '40000000-0000-0000-0000-000000000001', 'completed', 1, timezone('utc', now()))
on conflict (user_id, topic_version_id) do update set status = 'completed', progress = 1;

set local role authenticated;
set local request.jwt.claims = '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

select 'junior_addition_unlocked' as check, is_locked::text
from public.learning_catalog where topic_slug = 'addition';
rollback;

-- The same learner as senior grade 8 gains the senior-only subject and still
-- reads the identical version IDs.
begin;
set local role authenticated;
set local request.jwt.claims = '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

insert into public.student_onboarding (user_id, current_step, experience_track, self_reported_grade_level)
values (auth.uid(), 'ready', 'senior', 8)
on conflict (user_id) do update
set experience_track = 'senior', self_reported_grade_level = 8;

select 'senior_visible_subjects' as check, count(*) from public.learning_subjects;
select 'senior_science_rows' as check, count(*)
from public.learning_catalog where subject_slug = 'science';
select 'senior_math_topic_version' as check, topic_version_id::text
from public.learning_catalog where topic_slug = 'counting';
select 'senior_draft_rows' as check, count(*)
from public.learning_catalog where subject_slug = 'coding';
rollback;

-- A grade 2 senior claim still fails the grade window on the senior subject.
begin;
set local role authenticated;
set local request.jwt.claims = '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

insert into public.student_onboarding (user_id, current_step, experience_track, self_reported_grade_level)
values (auth.uid(), 'ready', 'senior', 2)
on conflict (user_id) do update
set experience_track = 'senior', self_reported_grade_level = 2;

select 'grade2_science_rows' as check, count(*)
from public.learning_catalog where subject_slug = 'science';
rollback;

-- Platform admin previews drafts against the same version IDs.
begin;
set local role authenticated;
set local request.jwt.claims = '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';
select 'admin_draft_rows' as check, count(*)
from public.learning_catalog where subject_slug = 'coding';
select 'admin_math_topic_version' as check, topic_version_id::text
from public.learning_catalog where topic_slug = 'counting';
rollback;

-- A teacher browsing the catalog still cannot see drafts.
begin;
set local role authenticated;
set local request.jwt.claims = '{"sub":"cccccccc-cccc-cccc-cccc-cccccccccccc","role":"authenticated"}';
select 'teacher_draft_rows' as check, count(*)
from public.learning_catalog where subject_slug = 'coding';
rollback;

-- Anonymous callers see no catalog at all.
begin;
set local role anon;
select 'anon_catalog_rows' as check, count(*) from public.learning_catalog;
select 'anon_subject_rows' as check, count(*) from public.learning_subjects;
rollback;
