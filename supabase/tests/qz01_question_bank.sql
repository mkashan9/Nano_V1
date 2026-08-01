-- QZ-01 adversarial checks: platform-admin authorship, learner isolation,
-- duplicate warnings, and published immutability.

-- Learners see nothing and cannot author.
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

select 'learner_questions' as check, count(*) as rows from public.questions;
select 'learner_bank' as check, count(*) as rows from public.question_bank;

do $$
begin
  begin
    perform public.create_question_draft(
      'learner-attempt',
      'Should a learner author questions?',
      '[{"id":"a","label":"No","is_correct":true},{"id":"b","label":"Yes","is_correct":false}]'::jsonb
    );
    raise exception 'FAIL: learner authored a question';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
  end;
end $$;
select 'learner_cannot_author' as check, true as ok;
rollback;

-- School staff also cannot author.
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"ffffffff-ffff-ffff-ffff-ffffffffffff","role":"authenticated"}';
do $$
begin
  begin
    perform public.create_question_draft(
      'staff-attempt',
      'Should school staff author platform questions?',
      '[{"id":"a","label":"No","is_correct":true},{"id":"b","label":"Yes","is_correct":false}]'::jsonb
    );
    raise exception 'FAIL: staff authored a question';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
  end;
end $$;
select 'staff_cannot_author' as check, true as ok;
rollback;

-- Platform admin sees the bank, gets duplicate warnings, and can publish.
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

select 'admin_bank' as check, count(*) as rows from public.question_bank;

select 'duplicate_warning' as check,
       jsonb_array_length((
         public.create_question_draft(
           'dup-counting',
           '  HOW many   apples are in the basket if you count to five?  ',
           '[{"id":"a","label":"Three","is_correct":false},{"id":"b","label":"Five","is_correct":true}]'::jsonb
         )->'duplicates'
       )) as matches;

do $$
declare
  v_id uuid;
begin
  select (public.create_question_draft(
    'immutable-check',
    'Can a published stem be rewritten?',
    '[{"id":"a","label":"No","is_correct":true},{"id":"b","label":"Yes","is_correct":false}]'::jsonb
  )->>'question_version_id')::uuid into v_id;

  perform public.publish_question_version(v_id);

  begin
    update public.question_versions set stem = 'hacked' where id = v_id;
    raise exception 'FAIL: published version mutated';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
  end;

  if not exists (
    select 1 from public.audit_events
    where target_type = 'question_version'
      and target_id = v_id::text
      and action = 'update'
  ) then
    raise exception 'FAIL: publish was not audited';
  end if;
end $$;
select 'published_immutable_and_audited' as check, true as ok;

-- Retiring keeps the row.
do $$
declare
  v_id uuid;
begin
  select question_version_id into v_id
  from public.question_bank
  where slug = 'counting-how-many';

  perform public.retire_question_version(v_id);

  if not exists (
    select 1 from public.question_versions
    where id = v_id and status = 'retired'
  ) then
    raise exception 'FAIL: retire deleted or skipped the row';
  end if;
end $$;
select 'retire_keeps_history' as check, true as ok;
rollback;

-- Options must have exactly one correct answer.
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';
do $$
begin
  begin
    perform public.create_question_draft(
      'bad-options',
      'Broken options?',
      '[{"id":"a","label":"A","is_correct":true},{"id":"b","label":"B","is_correct":true}]'::jsonb
    );
    raise exception 'FAIL: accepted two correct options';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
  end;
end $$;
select 'options_require_one_correct' as check, true as ok;
rollback;
