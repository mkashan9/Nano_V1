-- MED-05 adversarial checks: who may publish, what publication actually changes
-- for a learner, and the two things that only bite once rejection exists --
-- a refused asset must stop being served, and it must stop occupying its slot.
--
-- Assets are planted as service_role rather than driven through the worker,
-- because `authenticated` has no write privilege on generated_assets and a test
-- that grants itself one is testing the wrong database. The hash is computed
-- with the real function so request_generated_asset still finds these rows.
--
-- Every block rolls back, so the fixtures survive the run.

-- ---------------------------------------------------------------------------
-- Approval is the whole difference between invisible and visible
-- ---------------------------------------------------------------------------
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

select public.request_generated_asset(
  'image', 'med05_publish_slot', 'A calm round companion waving.', 'v1'
) is not null as requested;

reset role;
set local role service_role;
set local request.jwt.claims = '{"role":"service_role"}';

update public.generated_assets
set status = 'ready',
    storage_bucket = 'generated-assets',
    storage_path = 'image/med05_publish_slot/en/hash.png',
    content_type = 'image/png',
    byte_size = 24576,
    checksum = 'sha256:med05-publish',
    completed_at = timezone('utc', now())
where slot = 'med05_publish_slot';

-- A learner sees nothing while the asset is only unreviewed, which is the state
-- every asset MED-01 through MED-04 produces.
reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

do $med05$
begin
  if exists (
    select 1 from public.list_generated_assets('image', 'en', 'med05_publish_slot')
  ) then
    raise exception 'FAIL: an unreviewed asset was delivered to a learner';
  end if;
  if nano_internal.asset_object_is_published(
    'image/med05_publish_slot/en/hash.png'
  ) then
    raise exception 'FAIL: an unreviewed file was readable from storage';
  end if;
end $med05$;

reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $med05$
declare
  v_id uuid;
  v_out jsonb;
begin
  select id into v_id from public.generated_assets where slot = 'med05_publish_slot';

  v_out := public.review_generated_asset(v_id, 'approved', 'Looks right.');
  if (v_out->>'reviewed')::integer <> 1 then
    raise exception 'FAIL: approval reported % changes', v_out->>'reviewed';
  end if;
  if v_out->'assets'->0->>'moderation' <> 'approved' then
    raise exception 'FAIL: the returned asset was not approved';
  end if;

  -- Who decided is part of the decision, not a nice-to-have.
  if (select reviewed_by from public.generated_assets where id = v_id)
     <> 'dddddddd-dddd-dddd-dddd-dddddddddddd'::uuid then
    raise exception 'FAIL: the decision has nobody attached to it';
  end if;
  if (select reviewed_at from public.generated_assets where id = v_id) is null then
    raise exception 'FAIL: the decision has no time attached to it';
  end if;
end $med05$;

reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

do $med05$
begin
  if not exists (
    select 1 from public.list_generated_assets('image', 'en', 'med05_publish_slot')
  ) then
    raise exception 'FAIL: an approved asset never reached the learner';
  end if;
  -- Both gates have to open, not just the catalog: a row a learner can see but
  -- whose bytes they cannot fetch is a broken image, not a published asset.
  if not nano_internal.asset_object_is_published(
    'image/med05_publish_slot/en/hash.png'
  ) then
    raise exception 'FAIL: an approved file is still unreadable';
  end if;
end $med05$;

-- Un-publishing has to be as immediate as publishing.
reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $med05$
declare
  v_id uuid;
begin
  select id into v_id from public.generated_assets where slot = 'med05_publish_slot';
  perform public.review_generated_asset(v_id, 'rejected', 'Wrong expression.');
end $med05$;

reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

select 'approval_publishes_and_rejection_unpublishes' as check_name,
  not exists (
    select 1 from public.list_generated_assets('image', 'en', 'med05_publish_slot')
  )
  and not nano_internal.asset_object_is_published(
    'image/med05_publish_slot/en/hash.png'
  ) as ok;
rollback;

-- ---------------------------------------------------------------------------
-- A rejection frees the slot instead of poisoning it
-- ---------------------------------------------------------------------------
-- Before MED-05 the reuse key ignored moderation, so a refused asset was handed
-- back to every later ask and the slot could never be regenerated.
begin;
set local role service_role;
set local request.jwt.claims = '{"role":"service_role"}';

insert into public.generated_assets
  (kind, slot, locale, aspect_ratio, prompt, prompt_version, prompt_hash,
   provider_id, feature, status, moderation, storage_bucket, storage_path,
   content_type, byte_size, checksum, completed_at)
values
  ('image', 'med05_reuse_slot', 'en', '1:1', 'A companion mid-wave.', 'v1',
   nano_internal.generated_asset_hash(
     'image', 'med05_reuse_slot', 'en', '1:1', 'A companion mid-wave.', 'v1', null
   ),
   'pollinations_image', 'companion', 'ready', 'unreviewed',
   'generated-assets', 'image/med05_reuse_slot/en/old.png', 'image/png',
   2048, 'sha256:med05-reuse-old', timezone('utc', now()));

reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $med05$
declare
  v_id uuid;
  v_again jsonb;
  v_replacement jsonb;
begin
  select id into v_id from public.generated_assets where slot = 'med05_reuse_slot';

  -- While it is merely unreviewed it is still the answer, so putting an asset
  -- through review does not cost a second generation.
  v_again := public.request_generated_asset(
    'image', 'med05_reuse_slot', 'A companion mid-wave.', 'v1'
  );
  if not (v_again->>'reused')::boolean then
    raise exception 'FAIL: an unreviewed asset was regenerated';
  end if;
  if (v_again->'asset'->>'id')::uuid <> v_id then
    raise exception 'FAIL: reuse returned a different row';
  end if;

  perform public.review_generated_asset(v_id, 'rejected', 'Six fingers.');

  -- The same ask now has to produce a new job, not the refused output.
  v_replacement := public.request_generated_asset(
    'image', 'med05_reuse_slot', 'A companion mid-wave.', 'v1'
  );
  if (v_replacement->>'reused')::boolean then
    raise exception 'FAIL: a rejected asset was handed back as a reuse';
  end if;
  if (v_replacement->'asset'->>'id')::uuid = v_id then
    raise exception 'FAIL: the replacement is the rejected row';
  end if;
  if v_replacement->'asset'->>'moderation' <> 'unreviewed' then
    raise exception 'FAIL: the replacement did not start in the queue';
  end if;

  -- The rejected row stays, because the decision is a record.
  if not exists (
    select 1 from public.generated_assets
    where id = v_id and moderation = 'rejected'
  ) then
    raise exception 'FAIL: rejecting deleted the evidence';
  end if;
end $med05$;

-- Two rows for one ask, which the pre-MED-05 unique index would have refused.
select 'a_rejection_frees_the_slot' as check_name,
  (select count(*) from public.generated_assets where slot = 'med05_reuse_slot') = 2
  and (select count(*) from public.generated_assets
       where slot = 'med05_reuse_slot' and moderation = 'unreviewed') = 1 as ok;
rollback;

-- ---------------------------------------------------------------------------
-- What cannot be decided
-- ---------------------------------------------------------------------------
begin;
set local role service_role;
set local request.jwt.claims = '{"role":"service_role"}';

-- One asset that never produced bytes, one that did.
insert into public.generated_assets
  (kind, slot, locale, aspect_ratio, prompt, prompt_version, prompt_hash,
   provider_id, feature, status, moderation)
values
  ('image', 'med05_pending_slot', 'en', '1:1', 'Not generated yet.', 'v1',
   nano_internal.generated_asset_hash(
     'image', 'med05_pending_slot', 'en', '1:1', 'Not generated yet.', 'v1', null
   ),
   'pollinations_image', 'companion', 'requested', 'unreviewed');

insert into public.generated_assets
  (kind, slot, locale, aspect_ratio, prompt, prompt_version, prompt_hash,
   provider_id, feature, status, moderation, storage_bucket, storage_path,
   content_type, byte_size, checksum, completed_at)
values
  ('image', 'med05_ready_slot', 'en', '1:1', 'Generated already.', 'v1',
   nano_internal.generated_asset_hash(
     'image', 'med05_ready_slot', 'en', '1:1', 'Generated already.', 'v1', null
   ),
   'pollinations_image', 'companion', 'ready', 'unreviewed',
   'generated-assets', 'image/med05_ready_slot/en/hash.png', 'image/png',
   2048, 'sha256:med05-ready', timezone('utc', now()));

reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $med05$
declare
  v_pending uuid;
  v_ready uuid;
  v_out jsonb;
begin
  select id into v_pending from public.generated_assets where slot = 'med05_pending_slot';
  select id into v_ready from public.generated_assets where slot = 'med05_ready_slot';

  -- Approving something with no bytes would publish a filename.
  begin
    perform public.review_generated_asset(v_pending, 'approved', 'Fine.');
    raise exception 'FAIL: an asset with no file was approved';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlstate <> 'NM010' then
      raise exception 'FAIL: unexpected error % %', sqlstate, sqlerrm;
    end if;
  end;

  -- A rejection without a reason leaves whoever regenerates guessing.
  begin
    perform public.review_generated_asset(v_ready, 'rejected', '   ');
    raise exception 'FAIL: a rejection was accepted with no reason';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlstate <> 'NM010' then
      raise exception 'FAIL: unexpected rejection error % %', sqlstate, sqlerrm;
    end if;
  end;
  if (select moderation from public.generated_assets where id = v_ready)
     <> 'unreviewed' then
    raise exception 'FAIL: a refused decision changed the asset anyway';
  end if;

  begin
    perform public.review_generated_asset(v_ready, 'looks-good', '');
    raise exception 'FAIL: a nonsense decision was accepted';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlstate <> 'NM010' then
      raise exception 'FAIL: unexpected decision error % %', sqlstate, sqlerrm;
    end if;
  end;

  begin
    perform public.review_generated_assets(array[]::uuid[], 'approved', '');
    raise exception 'FAIL: an empty batch was accepted';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlstate <> 'NM010' then
      raise exception 'FAIL: unexpected empty-batch error % %', sqlstate, sqlerrm;
    end if;
  end;

  -- Confirming a decision that is already in force is not an error and not a
  -- second entry in the history.
  perform public.review_generated_asset(v_ready, 'approved', 'Good.');
  v_out := public.review_generated_asset(v_ready, 'approved', 'Still good.');
  if (v_out->>'reviewed')::integer <> 0
     or (v_out->>'unchanged')::integer <> 1 then
    raise exception 'FAIL: re-approving counted as a decision (%)', v_out;
  end if;
  if (select count(*) from public.asset_review_events where asset_id = v_ready) <> 1 then
    raise exception 'FAIL: re-approving wrote a second history row';
  end if;
end $med05$;

select 'refused_decisions_and_repeat_decisions' as check_name, true as ok;
rollback;

-- ---------------------------------------------------------------------------
-- A batch is all or nothing
-- ---------------------------------------------------------------------------
begin;
set local role service_role;
set local request.jwt.claims = '{"role":"service_role"}';

insert into public.generated_assets
  (kind, slot, locale, aspect_ratio, prompt, prompt_version, prompt_hash,
   provider_id, feature, status, moderation, storage_bucket, storage_path,
   content_type, byte_size, checksum, completed_at)
select
  'image', s.slot, 'en', '1:1', 'One of a pair.', 'v1',
  nano_internal.generated_asset_hash(
    'image', s.slot, 'en', '1:1', 'One of a pair.', 'v1', null
  ),
  'pollinations_image', 'companion', 'ready', 'unreviewed',
  'generated-assets', 'image/' || s.slot || '/en/hash.png', 'image/png',
  2048, 'sha256:' || s.slot, timezone('utc', now())
from (values ('med05_batch_a'), ('med05_batch_b')) as s(slot);

reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $med05$
declare
  v_a uuid;
  v_b uuid;
begin
  select id into v_a from public.generated_assets where slot = 'med05_batch_a';
  select id into v_b from public.generated_assets where slot = 'med05_batch_b';

  -- Both are publishable, but one unknown id in the list means nothing is
  -- published: a half-applied batch is the worst outcome to explain.
  begin
    perform public.review_generated_assets(
      array[v_a, v_b, '00000000-0000-0000-0000-0000000000ff'::uuid],
      'approved',
      'Batch.'
    );
    raise exception 'FAIL: a batch with an unknown asset was applied';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlstate <> 'NM010' then
      raise exception 'FAIL: unexpected batch error % %', sqlstate, sqlerrm;
    end if;
  end;

  if exists (
    select 1 from public.generated_assets
    where id in (v_a, v_b) and moderation <> 'unreviewed'
  ) then
    raise exception 'FAIL: a failed batch still published something';
  end if;
  if exists (select 1 from public.asset_review_events where asset_id in (v_a, v_b)) then
    raise exception 'FAIL: a failed batch left history behind';
  end if;

  -- The same batch without the bad id publishes both in one go.
  if (public.review_generated_assets(array[v_a, v_b], 'approved', 'Batch.')
      ->>'reviewed')::integer <> 2 then
    raise exception 'FAIL: a good batch did not publish both';
  end if;
end $med05$;

select 'a_batch_is_all_or_nothing' as check_name, true as ok;
rollback;

-- ---------------------------------------------------------------------------
-- Un-rejecting cannot resurrect a slot somebody else has filled
-- ---------------------------------------------------------------------------
begin;
set local role service_role;
set local request.jwt.claims = '{"role":"service_role"}';

insert into public.generated_assets
  (kind, slot, locale, aspect_ratio, prompt, prompt_version, prompt_hash,
   provider_id, feature, status, moderation, storage_bucket, storage_path,
   content_type, byte_size, checksum, completed_at)
values
  ('image', 'med05_undo_slot', 'en', '1:1', 'A first attempt.', 'v1',
   nano_internal.generated_asset_hash(
     'image', 'med05_undo_slot', 'en', '1:1', 'A first attempt.', 'v1', null
   ),
   'pollinations_image', 'companion', 'ready', 'unreviewed',
   'generated-assets', 'image/med05_undo_slot/en/old.png', 'image/png',
   2048, 'sha256:med05-undo-old', timezone('utc', now()));

reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $med05$
declare
  v_old uuid;
  v_new uuid;
begin
  select id into v_old from public.generated_assets where slot = 'med05_undo_slot';

  perform public.review_generated_asset(v_old, 'rejected', 'Try again.');

  v_new := (public.request_generated_asset(
    'image', 'med05_undo_slot', 'A first attempt.', 'v1'
  )->'asset'->>'id')::uuid;

  -- Changing one's mind now would give the slot two live answers, so it is
  -- refused with an explanation rather than a constraint name.
  begin
    perform public.review_generated_asset(v_old, 'unreviewed', 'Second look.');
    raise exception 'FAIL: a superseded rejection was undone';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlstate <> 'NM010' then
      raise exception 'FAIL: unexpected undo error % %', sqlstate, sqlerrm;
    end if;
    if sqlerrm not like '%newer asset%' then
      raise exception 'FAIL: unhelpful undo message %', sqlerrm;
    end if;
  end;

  -- Rejecting the replacement first is the documented way out.
  perform public.review_generated_asset(v_new, 'rejected', 'Worse.');
  perform public.review_generated_asset(v_old, 'approved', 'The first one was fine.');

  if (select moderation from public.generated_assets where id = v_old) <> 'approved' then
    raise exception 'FAIL: the way out does not work';
  end if;
end $med05$;

select 'un_rejecting_respects_the_replacement' as check_name, true as ok;
rollback;

-- ---------------------------------------------------------------------------
-- Nobody but a platform admin
-- ---------------------------------------------------------------------------
begin;
set local role service_role;
set local request.jwt.claims = '{"role":"service_role"}';

insert into public.generated_assets
  (kind, slot, locale, aspect_ratio, prompt, prompt_version, prompt_hash,
   provider_id, feature, status, moderation, storage_bucket, storage_path,
   content_type, byte_size, checksum, completed_at)
values
  ('image', 'med05_perm_slot', 'en', '1:1', 'A companion.', 'v1',
   nano_internal.generated_asset_hash(
     'image', 'med05_perm_slot', 'en', '1:1', 'A companion.', 'v1', null
   ),
   'pollinations_image', 'companion', 'ready', 'unreviewed',
   'generated-assets', 'image/med05_perm_slot/en/hash.png', 'image/png',
   2048, 'sha256:med05-perm', timezone('utc', now()));

reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"ffffffff-ffff-ffff-ffff-ffffffffffff","role":"authenticated"}';

do $med05$
declare
  v_id uuid;
begin
  -- The table is admin-only, so a school admin cannot even find the id. They
  -- are refused on the strength of who they are, not on a lookup miss.
  select id into v_id from public.generated_assets where slot = 'med05_perm_slot';
  if v_id is not null then
    raise exception 'FAIL: a school admin can read the asset table';
  end if;
  v_id := '00000000-0000-0000-0000-0000000000aa'::uuid;

  begin
    perform public.review_generated_asset(v_id, 'approved', 'Mine now.');
    raise exception 'FAIL: a school admin published an asset';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlstate <> 'NM010' then
      raise exception 'FAIL: unexpected school admin error % %', sqlstate, sqlerrm;
    end if;
  end;

  -- Refused, not silently empty: an empty queue would read as "no work to do".
  begin
    perform * from public.list_assets_for_review();
    raise exception 'FAIL: a school admin read the review queue';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlstate <> 'NM010' then
      raise exception 'FAIL: unexpected queue error % %', sqlstate, sqlerrm;
    end if;
  end;

  begin
    perform * from public.asset_review_history(v_id);
    raise exception 'FAIL: a school admin read review history';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlstate <> 'NM010' then
      raise exception 'FAIL: unexpected history error % %', sqlstate, sqlerrm;
    end if;
  end;
end $med05$;

reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

do $med05$
begin
  begin
    perform public.review_generated_asset(
      '00000000-0000-0000-0000-0000000000aa'::uuid, 'approved', ''
    );
    raise exception 'FAIL: a learner published an asset';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlstate <> 'NM010' then
      raise exception 'FAIL: unexpected learner error % %', sqlstate, sqlerrm;
    end if;
  end;

  if exists (select 1 from public.asset_review_events) then
    raise exception 'FAIL: a learner can read the decision record';
  end if;
  if exists (select 1 from public.generated_assets) then
    raise exception 'FAIL: a learner can read the asset table';
  end if;
end $med05$;

select 'only_a_platform_admin_may_review' as check_name, true as ok;
rollback;

-- ---------------------------------------------------------------------------
-- The record cannot be rewritten
-- ---------------------------------------------------------------------------
begin;
set local role service_role;
set local request.jwt.claims = '{"role":"service_role"}';

insert into public.generated_assets
  (kind, slot, locale, aspect_ratio, prompt, prompt_version, prompt_hash,
   provider_id, feature, status, moderation, storage_bucket, storage_path,
   content_type, byte_size, checksum, completed_at)
values
  ('image', 'med05_history_slot', 'en', '1:1', 'A companion.', 'v1',
   nano_internal.generated_asset_hash(
     'image', 'med05_history_slot', 'en', '1:1', 'A companion.', 'v1', null
   ),
   'pollinations_image', 'companion', 'ready', 'unreviewed',
   'generated-assets', 'image/med05_history_slot/en/hash.png', 'image/png',
   2048, 'sha256:med05-history', timezone('utc', now()));

reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $med05$
declare
  v_id uuid;
  v_row record;
begin
  select id into v_id from public.generated_assets where slot = 'med05_history_slot';

  -- Both decisions land in one transaction, which is exactly the case that
  -- ordering by timestamp alone got wrong.
  perform public.review_generated_asset(v_id, 'approved', 'First call.');
  perform public.review_generated_asset(v_id, 'rejected', 'Changed my mind.');

  if (select count(*) from public.asset_review_history(v_id)) <> 2 then
    raise exception 'FAIL: the history lost a decision';
  end if;

  select * into v_row from public.asset_review_history(v_id) limit 1;
  if v_row.decision <> 'rejected' then
    raise exception 'FAIL: the history is in the wrong order';
  end if;
  if v_row.previous_moderation <> 'approved' then
    raise exception 'FAIL: the history does not say what it changed from';
  end if;
  if v_row.note <> 'Changed my mind.' then
    raise exception 'FAIL: the history lost the reason';
  end if;
  if v_row.reviewer_name <> 'Platform Admin' then
    raise exception 'FAIL: the history does not say who decided';
  end if;
end $med05$;

-- Even a caller with table privileges cannot revise what was decided.
reset role;
set local role service_role;
set local request.jwt.claims = '{"role":"service_role"}';

do $med05$
begin
  begin
    update public.asset_review_events set note = 'Something kinder.';
    raise exception 'FAIL: review history was edited';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlstate <> 'NM010' then
      raise exception 'FAIL: unexpected edit error % %', sqlstate, sqlerrm;
    end if;
  end;

  begin
    delete from public.asset_review_events;
    raise exception 'FAIL: review history was deleted';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlstate <> 'NM010' then
      raise exception 'FAIL: unexpected delete error % %', sqlstate, sqlerrm;
    end if;
  end;
end $med05$;

-- Append-only must not mean the asset becomes undeletable. Removing the asset
-- takes its per-asset detail with it, as the foreign key says, and the durable
-- record in audit_events is untouched by any of it.
do $med05$
declare
  v_id uuid;
  v_audit bigint;
begin
  select id into v_id from public.generated_assets where slot = 'med05_history_slot';

  select count(*) into v_audit
  from public.audit_events
  where target_type = 'generated_asset' and target_id = v_id::text;
  if v_audit = 0 then
    raise exception 'FAIL: the decision never reached the audit log';
  end if;

  delete from public.generated_assets where id = v_id;

  if exists (select 1 from public.asset_review_events where asset_id = v_id) then
    raise exception 'FAIL: deleting the asset left orphaned history';
  end if;
  if (
    select count(*) from public.audit_events
    where target_type = 'generated_asset' and target_id = v_id::text
  ) <> v_audit then
    raise exception 'FAIL: the durable record did not survive the asset';
  end if;
end $med05$;

select 'the_record_cannot_be_rewritten' as check_name, true as ok;
rollback;

-- ---------------------------------------------------------------------------
-- The queue is ordered by what can actually be done, and reaches the audit log
-- ---------------------------------------------------------------------------
begin;
set local role service_role;
set local request.jwt.claims = '{"role":"service_role"}';

-- Asked for first, but it never produced bytes, so it cannot be decided.
insert into public.generated_assets
  (kind, slot, locale, aspect_ratio, prompt, prompt_version, prompt_hash,
   provider_id, feature, status, moderation, requested_at)
values
  ('image', 'med05_queue_stuck', 'en', '1:1', 'Never finished.', 'v1',
   nano_internal.generated_asset_hash(
     'image', 'med05_queue_stuck', 'en', '1:1', 'Never finished.', 'v1', null
   ),
   'pollinations_image', 'companion', 'requested', 'unreviewed',
   timezone('utc', now()) - interval '2 hours');

insert into public.generated_assets
  (kind, slot, locale, aspect_ratio, prompt, prompt_version, prompt_hash,
   provider_id, feature, status, moderation, storage_bucket, storage_path,
   content_type, byte_size, checksum, requested_at, completed_at)
values
  ('image', 'med05_queue_ready', 'en', '1:1', 'Finished.', 'v1',
   nano_internal.generated_asset_hash(
     'image', 'med05_queue_ready', 'en', '1:1', 'Finished.', 'v1', null
   ),
   'pollinations_image', 'companion', 'ready', 'unreviewed',
   'generated-assets', 'image/med05_queue_ready/en/hash.png', 'image/png',
   2048, 'sha256:med05-queue',
   timezone('utc', now()) - interval '1 hour', timezone('utc', now()));

reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $med05$
declare
  v_ready uuid;
  v_first record;
begin
  select id into v_ready from public.generated_assets where slot = 'med05_queue_ready';

  -- Asked for later than the stuck one, but it is the only one anybody can act
  -- on, so it leads.
  select * into v_first from public.list_assets_for_review() limit 1;
  if v_first.id <> v_ready then
    raise exception 'FAIL: the queue does not lead with reviewable work';
  end if;
  -- Provenance is the point of the queue: a reviewer needs to know what was
  -- asked for and from whom.
  if v_first.prompt <> 'Finished.' or v_first.provider_id <> 'pollinations_image' then
    raise exception 'FAIL: the queue hides the provenance a reviewer needs';
  end if;

  if (select count(*) from public.list_assets_for_review('unreviewed')) < 2 then
    raise exception 'FAIL: filtering by state lost rows';
  end if;
  if exists (
    select 1 from public.list_assets_for_review(null, 'video')
    where slot like 'med05[_]%'
  ) then
    raise exception 'FAIL: filtering by kind returned an image';
  end if;

  begin
    perform * from public.list_assets_for_review('mostly-fine');
    raise exception 'FAIL: a nonsense filter was accepted';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlstate <> 'NM010' then
      raise exception 'FAIL: unexpected filter error % %', sqlstate, sqlerrm;
    end if;
  end;

  perform public.review_generated_asset(v_ready, 'approved', 'Ship it.');

  -- Publication is a platform act, so it belongs in the SEC-03 trail as well as
  -- in the module's own history.
  if not exists (
    select 1 from public.audit_events
    where target_type = 'generated_asset'
      and target_id = v_ready::text
      and action = 'update'
      and new_value->>'moderation' = 'approved'
      and previous_value->>'moderation' = 'unreviewed'
      and reason = 'Ship it.'
  ) then
    raise exception 'FAIL: the decision never reached the audit trail';
  end if;

  if not exists (
    select 1 from public.list_assets_for_review('approved') where id = v_ready
  ) then
    raise exception 'FAIL: the approved filter does not find it afterwards';
  end if;
end $med05$;

select 'the_queue_leads_with_work_and_is_audited' as check_name, true as ok;
rollback;

-- ---------------------------------------------------------------------------
-- Nothing from this run survived
-- ---------------------------------------------------------------------------
select 'no_test_rows_left_behind' as check_name,
  not exists (
    select 1 from public.generated_assets where slot like 'med05[_]%'
  )
  and not exists (
    select 1 from public.asset_review_events
  ) as ok;
