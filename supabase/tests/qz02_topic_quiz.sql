-- QZ-02 adversarial checks: platform-admin quiz authorship, learner strip of
-- correctness, school staff isolation, and published immutability.

-- Learners can see catalog quizzes without is_correct, and cannot author.
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

select 'learner_quiz_rows' as check, count(*) as rows from public.learner_quiz;

do $$
declare
  v_opts jsonb;
begin
  select items->0->'options' into v_opts
  from public.learner_quiz
  where quiz_version_id = '60000000-0000-0000-0000-000000000001';

  if v_opts is null then
    raise exception 'FAIL: learner cannot see counting quiz';
  end if;
  if v_opts->0 ? 'is_correct' then
    raise exception 'FAIL: learner_quiz leaked is_correct';
  end if;
end $$;
select 'learner_quiz_strips_correctness' as check, true as ok;

do $$
begin
  begin
    perform public.create_quiz_draft(
      '40000000-0000-0000-0000-000000000006'::uuid,
      'Learner should not author',
      '[{"question_version_id":"51000000-0000-0000-0000-000000000001","sort_order":1}]'::jsonb
    );
    raise exception 'FAIL: learner authored a quiz';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
  end;
end $$;
select 'learner_cannot_author' as check, true as ok;
rollback;

-- School staff cannot author.
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"ffffffff-ffff-ffff-ffff-ffffffffffff","role":"authenticated"}';
do $$
begin
  begin
    perform public.create_quiz_draft(
      '40000000-0000-0000-0000-000000000006'::uuid,
      'Staff should not author',
      '[{"question_version_id":"51000000-0000-0000-0000-000000000001","sort_order":1}]'::jsonb
    );
    raise exception 'FAIL: staff authored a quiz';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
  end;
end $$;
select 'staff_cannot_author' as check, true as ok;
rollback;

-- Platform admin can author, publish, and immutability holds.
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

select 'admin_authoring' as check, count(*) as rows from public.quiz_authoring;

do $$
declare
  v_id uuid;
begin
  select (public.create_quiz_draft(
    '40000000-0000-0000-0000-000000000006'::uuid,
    'Ecosystems immutability check',
    '[{"question_version_id":"51000000-0000-0000-0000-000000000001","sort_order":1}]'::jsonb,
    'ماحول'
  )->>'quiz_version_id')::uuid into v_id;

  perform public.publish_quiz_version(v_id);

  begin
    update public.quiz_versions set title = 'hacked' where id = v_id;
    raise exception 'FAIL: published quiz mutated';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
  end;

  begin
    update public.quiz_items set sort_order = 99 where quiz_version_id = v_id;
    raise exception 'FAIL: published quiz items mutated';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
  end;

  if not exists (
    select 1 from public.audit_events
    where target_type = 'quiz_version'
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
  select quiz_version_id into v_id
  from public.quiz_authoring
  where topic_slug = 'counting'
    and status = 'published';

  perform public.retire_quiz_version(v_id);

  if not exists (
    select 1 from public.quiz_versions
    where id = v_id and status = 'retired'
  ) then
    raise exception 'FAIL: retire deleted or skipped the row';
  end if;
end $$;
select 'retire_keeps_history' as check, true as ok;
rollback;

-- Only published question versions can be attached.
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';
do $$
declare
  v_draft uuid;
begin
  select (public.create_question_draft(
    'qz02-unpublished',
    'Unpublished attachment probe?',
    '[{"id":"a","label":"No","is_correct":true},{"id":"b","label":"Yes","is_correct":false}]'::jsonb
  )->>'question_version_id')::uuid into v_draft;

  begin
    perform public.create_quiz_draft(
      '40000000-0000-0000-0000-000000000006'::uuid,
      'Should reject draft question',
      jsonb_build_array(
        jsonb_build_object(
          'question_version_id', v_draft,
          'sort_order', 1
        )
      )
    );
    raise exception 'FAIL: attached unpublished question';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
  end;
end $$;
select 'only_published_questions_attach' as check, true as ok;
rollback;
