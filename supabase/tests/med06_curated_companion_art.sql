-- MED-06 adversarial checks for art a person supplied rather than a model.
--
-- The worry with a curated path is that it becomes a side door. Generated art
-- has to survive a budget, a provider, a worker, and a reviewer; if a human can
-- put a picture straight into the catalog, every one of those checks becomes
-- optional for anyone who can upload. So the blocks below are almost all
-- attempts to use the door as a way around the review gate rather than a way
-- into the queue.
--
-- The storage object is planted as a bare row. The function only asks whether
-- storage knows about the name, and a test that uploads real bytes would be
-- testing the storage service instead of this rule.
--
-- Every block rolls back, so the fixtures survive the run.
--   dddddddd-… platform admin      ffffffff-… school admin      aaaaaaaa-… learner

-- ---------------------------------------------------------------------------
-- The provider is a row, and it is not the one generation reaches for
-- ---------------------------------------------------------------------------
do $curated$
declare
  v public.generation_providers;
begin
  select * into v from public.generation_providers where id = 'curated_upload';
  if v.id is null then
    raise exception 'FAIL: there is no curated provider';
  end if;
  -- The whole point is that no key and no endpoint are involved.
  if v.requires_key then
    raise exception 'FAIL: the curated provider claims to need a key';
  end if;
  -- If this ever became the default, every ordinary request for an image would
  -- reach a provider that cannot generate one.
  if v.is_default then
    raise exception 'FAIL: curated upload is the default image provider';
  end if;
  if (select id from public.generation_providers where kind = 'image' and is_default)
     <> 'pollinations_image' then
    raise exception 'FAIL: the default image provider was displaced';
  end if;
end $curated$;

-- ---------------------------------------------------------------------------
-- Only a platform admin may register
-- ---------------------------------------------------------------------------
begin;
  set local role authenticated;
  set local request.jwt.claims = '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';
  do $curated$
  begin
    perform public.register_curated_asset(
      'guide_greeting_staticArt', 'A learner smuggling a picture in',
      'image/guide_greeting_staticArt/en/smuggled.jpg', 'image/jpeg',
      1000, 'deadbeef', 'none'
    );
    raise exception 'FAIL: a learner registered curated art';
  exception
    when sqlstate 'NM001' then null;
  end $curated$;
rollback;

-- A school admin runs a school, not the platform catalog. Their art would be
-- every school's art, which is exactly the tenancy mistake worth refusing.
begin;
  set local role authenticated;
  set local request.jwt.claims = '{"sub":"ffffffff-ffff-ffff-ffff-ffffffffffff","role":"authenticated"}';
  do $curated$
  begin
    perform public.register_curated_asset(
      'guide_greeting_staticArt', 'A school admin supplying platform art',
      'image/guide_greeting_staticArt/en/school.jpg', 'image/jpeg',
      1000, 'deadbeef', 'school owned'
    );
    raise exception 'FAIL: a school admin registered platform art';
  exception
    when sqlstate 'NM001' then null;
  end $curated$;
rollback;

-- ---------------------------------------------------------------------------
-- What a registration must say about itself
-- ---------------------------------------------------------------------------
begin;
  reset role;
  insert into storage.objects (bucket_id, name)
  values ('generated-assets', 'image/curated_test_slot/en/present.jpg');

  set local role authenticated;
  set local request.jwt.claims = '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

  -- Rights, because a picture nobody can account for is a picture that cannot be
  -- defended when a school asks where it came from.
  do $curated$
  begin
    perform public.register_curated_asset(
      'curated_test_slot', 'A companion waving',
      'image/curated_test_slot/en/present.jpg', 'image/jpeg',
      1000, 'deadbeef', '   '
    );
    raise exception 'FAIL: art with no rights was registered';
  exception
    when sqlstate 'NM004' then null;
  end $curated$;

  -- A checksum, because `ready` is a promise that a specific file is there.
  do $curated$
  begin
    perform public.register_curated_asset(
      'curated_test_slot', 'A companion waving',
      'image/curated_test_slot/en/present.jpg', 'image/jpeg',
      1000, '', 'platform owned'
    );
    raise exception 'FAIL: art with no checksum was registered';
  exception
    when sqlstate 'NM004' then null;
  end $curated$;

  -- And the file itself. Without this the catalog would advertise a picture
  -- storage cannot serve, and a learner would get a broken image rather than
  -- the local art the fallback exists to show.
  do $curated$
  begin
    perform public.register_curated_asset(
      'curated_test_slot', 'A companion waving',
      'image/curated_test_slot/en/absent.jpg', 'image/jpeg',
      1000, 'deadbeef', 'platform owned'
    );
    raise exception 'FAIL: a row was registered for a file that is not there';
  exception
    when sqlstate 'NM004' then null;
  end $curated$;
rollback;

-- ---------------------------------------------------------------------------
-- A registered picture is a queued picture, not a published one
-- ---------------------------------------------------------------------------
begin;
  reset role;
  insert into storage.objects (bucket_id, name)
  values ('generated-assets', 'image/curated_test_slot/en/good.jpg');

  set local role authenticated;
  set local request.jwt.claims = '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

  do $curated$
  declare
    v_result jsonb;
    v_asset public.generated_assets;
  begin
    v_result := public.register_curated_asset(
      'curated_test_slot', 'A small round violet companion waving hello',
      'image/curated_test_slot/en/good.jpg', 'image/jpeg',
      25618, '065bc202', 'Made for Nano; no third-party source'
    );

    select * into v_asset
    from public.generated_assets
    where id = (v_result->>'id')::uuid;

    -- Ready, because the file exists. Unreviewed, because that is the entire
    -- point: curated art meets the same reviewer as generated art.
    if v_asset.status <> 'ready' then
      raise exception 'FAIL: curated art registered as %', v_asset.status;
    end if;
    if v_asset.moderation <> 'unreviewed' then
      raise exception 'FAIL: curated art registered as %', v_asset.moderation;
    end if;
    if v_asset.reviewed_by is not null or v_asset.reviewed_at is not null then
      raise exception 'FAIL: curated art arrived pre-reviewed';
    end if;

    -- Nothing was bought, and a budget that counts an unspent zero would refuse
    -- tomorrow's real generation on behalf of a picture that cost nothing.
    if v_asset.cost_micros <> 0 then
      raise exception 'FAIL: curated art was billed % micros', v_asset.cost_micros;
    end if;

    -- Where it came from is recorded rather than disguised as a generation.
    if v_asset.provider_id <> 'curated_upload'
       or v_asset.provenance->>'source' <> 'curated' then
      raise exception 'FAIL: curated provenance was not recorded';
    end if;

    -- Invisible until somebody decides otherwise.
    if nano_internal.asset_object_is_published(v_asset.storage_path) then
      raise exception 'FAIL: unreviewed curated art is readable by learners';
    end if;

    -- Registering is a decision worth being able to trace back to a person.
    if not exists (
      select 1 from public.audit_events
      where target_type = 'generated_asset' and target_id = v_asset.id::text
    ) then
      raise exception 'FAIL: the registration never reached the audit log';
    end if;

    -- The same picture for the same slot is one row, exactly as it is for a
    -- generated asset. Otherwise a retried upload silently doubles the queue.
    begin
      perform public.register_curated_asset(
        'curated_test_slot', 'A small round violet companion waving hello',
        'image/curated_test_slot/en/good.jpg', 'image/jpeg',
        25618, '065bc202', 'Made for Nano; no third-party source'
      );
      raise exception 'FAIL: the same picture was registered twice';
    exception
      when sqlstate 'NM004' then null;
    end;

    -- Approval is still the only thing that publishes it, and it still works
    -- through the ordinary review path rather than a curated shortcut.
    perform public.review_generated_asset(v_asset.id, 'approved', 'Looks right.');
    if not nano_internal.asset_object_is_published(v_asset.storage_path) then
      raise exception 'FAIL: approved curated art is still unreadable';
    end if;
  end $curated$;
rollback;

-- ---------------------------------------------------------------------------
-- The bucket door itself
-- ---------------------------------------------------------------------------
-- The policy is what lets a reviewer place the file at all. It has to open for
-- exactly one kind of person, because a bucket anyone can write to is a bucket
-- that will eventually hold something nobody chose.
begin;
  set local role authenticated;
  set local request.jwt.claims = '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';
  do $curated$
  begin
    insert into storage.objects (bucket_id, name)
    values ('generated-assets', 'image/curated_test_slot/en/learner.jpg');
    raise exception 'FAIL: a learner wrote into the generated assets bucket';
  exception
    when insufficient_privilege then null;
  end $curated$;
rollback;

begin;
  set local role authenticated;
  set local request.jwt.claims = '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';
  do $curated$
  begin
    insert into storage.objects (bucket_id, name)
    values ('generated-assets', 'image/curated_test_slot/en/admin.jpg');
  exception
    when insufficient_privilege then
      raise exception 'FAIL: a platform admin cannot place curated art';
  end $curated$;
rollback;
