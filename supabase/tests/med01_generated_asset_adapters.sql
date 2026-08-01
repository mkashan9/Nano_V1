-- MED-01 adversarial checks: who may ask for generation, who may declare a
-- result, what an identical ask costs the second time, and what a learner can
-- see of the machinery.
--
-- Every block rolls back, so the development project keeps no test rows.

-- ---------------------------------------------------------------------------
-- A learner is not part of this at all.
-- ---------------------------------------------------------------------------
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

select 'learner_sees_no_assets' as check, count(*) = 0 as ok
from public.generated_assets;
select 'learner_sees_no_providers' as check, count(*) = 0 as ok
from public.generation_providers;
select 'learner_sees_no_attempts' as check, count(*) = 0 as ok
from public.generation_attempts;

-- The worker RPCs are not merely refused for a learner; they are unreachable.
select 'worker_rpcs_unreachable' as check,
  not has_function_privilege(
    'authenticated', 'public.claim_generated_asset(uuid)', 'execute'
  )
  and not has_function_privilege(
    'authenticated',
    'public.record_generated_asset_result(uuid, text, text, text, bigint, text, text, integer, integer, text, jsonb)',
    'execute'
  )
  and not has_function_privilege(
    'authenticated',
    'public.record_generated_asset_failure(uuid, text, text, integer)',
    'execute'
  ) as ok;

do $$
begin
  begin
    perform public.request_generated_asset(
      'image', 'guide_greeting_shortClip', 'a friendly companion waving', 'v1'
    );
    raise exception 'FAIL: learner requested a generated asset';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
    if sqlstate not in ('NM001', '42501') then
      raise exception 'FAIL: unexpected refusal % %', sqlstate, sqlerrm;
    end if;
  end;
end $$;
select 'learner_cannot_request' as check, true as ok;

-- The catalog projection cannot carry a prompt, a provider, or a cost, so a
-- client asking for one gets an error rather than a leak.
do $$
begin
  begin
    execute 'select prompt from public.generated_asset_catalog';
    raise exception 'FAIL: prompt reachable through the catalog';
  exception when undefined_column then null;
  end;
  begin
    execute 'select cost_micros from public.generated_asset_catalog';
    raise exception 'FAIL: cost reachable through the catalog';
  exception when undefined_column then null;
  end;
  begin
    execute 'select provider_id from public.generated_asset_catalog';
    raise exception 'FAIL: provider reachable through the catalog';
  exception when undefined_column then null;
  end;
end $$;
select 'catalog_hides_provenance' as check, true as ok;
rollback;

-- ---------------------------------------------------------------------------
-- Superadmin requests; the second identical ask is free.
-- ---------------------------------------------------------------------------
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $$
declare
  v_first jsonb;
  v_second jsonb;
  v_third jsonb;
  v_id uuid;
begin
  v_first := public.request_generated_asset(
    'image', 'guide_greeting_staticArt', 'A friendly round companion waving', 'v1'
  );
  if (v_first->>'reused')::boolean then
    raise exception 'FAIL: first request reported reuse';
  end if;
  v_id := (v_first->'asset'->>'id')::uuid;

  if (v_first->'asset'->>'provider_id') <> 'pollinations_image' then
    raise exception 'FAIL: default image provider not chosen %', v_first;
  end if;
  if (v_first->'asset'->>'status') <> 'requested' then
    raise exception 'FAIL: new asset not requested %', v_first;
  end if;
  if (v_first->'asset'->>'moderation') <> 'unreviewed' then
    raise exception 'FAIL: new asset pre-approved %', v_first;
  end if;

  -- Same ask, different spacing and case: one output, not two.
  v_second := public.request_generated_asset(
    'image', 'guide_greeting_staticArt', '  a friendly   ROUND companion waving ',
    'v1'
  );
  if not (v_second->>'reused')::boolean then
    raise exception 'FAIL: identical ask created a second row';
  end if;
  if (v_second->'asset'->>'id')::uuid <> v_id then
    raise exception 'FAIL: reuse returned a different asset';
  end if;

  -- A new prompt version is a new output, because the wording changed.
  v_third := public.request_generated_asset(
    'image', 'guide_greeting_staticArt', 'A friendly round companion waving', 'v2'
  );
  if (v_third->>'reused')::boolean then
    raise exception 'FAIL: prompt version ignored by the hash';
  end if;

  if (select count(*) from public.generated_assets) <> 2 then
    raise exception 'FAIL: unexpected row count %',
      (select count(*) from public.generated_assets);
  end if;

  -- Locale and aspect ratio are part of the identity too.
  if public.request_generated_asset(
       'image', 'guide_greeting_staticArt',
       'A friendly round companion waving', 'v1', 'ur'
     )->>'reused' = 'true' then
    raise exception 'FAIL: locale ignored by the hash';
  end if;
  if public.request_generated_asset(
       'image', 'guide_greeting_staticArt',
       'A friendly round companion waving', 'v1', 'en', '16:9'
     )->>'reused' = 'true' then
    raise exception 'FAIL: aspect ratio ignored by the hash';
  end if;

  -- The request is audited with its provenance, not its output.
  if not exists (
    select 1 from public.audit_events
    where target_type = 'generated_asset'
      and target_id = v_id::text
      and new_value->>'prompt_hash' is not null
  ) then
    raise exception 'FAIL: request not audited';
  end if;
end $$;
select 'request_dedupes_by_hash' as check, true as ok;

-- A provider must serve the kind it is asked for, and must be enabled.
do $$
begin
  begin
    perform public.request_generated_asset(
      'image', 'slot_a', 'prompt', 'v1', 'en', '1:1', 'configured_voice'
    );
    raise exception 'FAIL: voice provider accepted an image request';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
    if sqlstate <> 'NM002' then
      raise exception 'FAIL: unexpected mismatch error % %', sqlstate, sqlerrm;
    end if;
  end;

  begin
    perform public.request_generated_asset(
      'image', 'slot_a', 'prompt', 'v1', 'en', '1:1', 'no_such_provider'
    );
    raise exception 'FAIL: unknown provider accepted';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
    if sqlstate <> 'NM002' then
      raise exception 'FAIL: unexpected unknown-provider error %', sqlstate;
    end if;
  end;
end $$;
select 'provider_registry_is_enforced' as check, true as ok;

-- Even a superadmin cannot claim a job or declare a file ready.
do $$
declare
  v_id uuid;
begin
  v_id := (public.request_generated_asset(
    'voice', 'aoede_intro', 'Read the welcome line warmly', 'v1'
  )->'asset'->>'id')::uuid;

  begin
    perform public.claim_generated_asset(v_id);
    raise exception 'FAIL: superadmin claimed a generation job';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
    if sqlstate not in ('NM003', '42501') then
      raise exception 'FAIL: unexpected claim refusal %', sqlstate;
    end if;
  end;

  begin
    perform public.record_generated_asset_result(
      v_id, 'generated-assets', 'voice/x.mp3', 'audio/mpeg', 1024, 'abc'
    );
    raise exception 'FAIL: superadmin declared a file ready';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
    if sqlstate not in ('NM003', '42501') then
      raise exception 'FAIL: unexpected result refusal %', sqlstate;
    end if;
  end;

  if (select status from public.generated_assets where id = v_id)
     <> 'requested' then
    raise exception 'FAIL: asset moved without a worker';
  end if;
end $$;
select 'only_the_worker_writes_results' as check, true as ok;
rollback;

-- ---------------------------------------------------------------------------
-- The worker path: claim once, record once, and stay unpublished.
-- ---------------------------------------------------------------------------
begin;
set local role service_role;
set local request.jwt.claims = '{"role":"service_role"}';

do $$
declare
  v_id uuid;
  v_claim jsonb;
  v_result jsonb;
begin
  -- Seeded directly here because requesting needs a signed-in superadmin, and
  -- this block is the worker.
  insert into public.generated_assets
    (kind, slot, locale, aspect_ratio, prompt, prompt_version, prompt_hash,
     provider_id)
  values
    ('image', 'worker_slot', 'en', '1:1', 'a companion', 'v1',
     nano_internal.generated_asset_hash(
       'image', 'worker_slot', 'en', '1:1', 'a companion', 'v1'
     ),
     'pollinations_image')
  returning id into v_id;

  v_claim := public.claim_generated_asset(v_id);
  if (v_claim->>'attempt_number')::integer <> 1 then
    raise exception 'FAIL: first claim is not attempt one %', v_claim;
  end if;
  if (v_claim->'asset'->>'status') <> 'generating' then
    raise exception 'FAIL: claim did not move the asset %', v_claim;
  end if;
  if not exists (
    select 1 from public.generation_attempts
    where asset_id = v_id and attempt_number = 1 and outcome = 'started'
  ) then
    raise exception 'FAIL: claim recorded no attempt';
  end if;

  -- Single flight: a retried invocation must not start a second provider call.
  begin
    perform public.claim_generated_asset(v_id);
    raise exception 'FAIL: asset claimed twice';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
    if sqlstate <> 'NM004' then
      raise exception 'FAIL: unexpected second-claim error %', sqlstate;
    end if;
  end;

  v_result := public.record_generated_asset_result(
    v_id, 'generated-assets', 'image/worker_slot_en.png', 'image/png',
    2048, 'sha256:abc', 'provider-ref-1', 1500, 250, 'platform-owned',
    jsonb_build_object('provider', 'pollinations_image', 'prompt_version', 'v1')
  );
  if (v_result->>'status') <> 'ready' then
    raise exception 'FAIL: result did not mark the asset ready %', v_result;
  end if;
  if (v_result->>'cost_micros')::integer <> 1500 then
    raise exception 'FAIL: cost not recorded %', v_result;
  end if;
  if not exists (
    select 1 from public.generation_attempts
    where asset_id = v_id and attempt_number = 1
      and outcome = 'succeeded' and latency_ms = 250
  ) then
    raise exception 'FAIL: attempt not closed';
  end if;

  -- Ready is not published: approval is a separate, later decision.
  if exists (
    select 1 from public.list_generated_assets() where id = v_id
  ) then
    raise exception 'FAIL: unreviewed asset appeared in the catalog';
  end if;

  -- Recording again is refused, so a duplicated callback cannot double the cost.
  begin
    perform public.record_generated_asset_result(
      v_id, 'generated-assets', 'image/worker_slot_en.png', 'image/png',
      2048, 'sha256:abc'
    );
    raise exception 'FAIL: result recorded twice';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
    if sqlstate <> 'NM004' then
      raise exception 'FAIL: unexpected second-result error %', sqlstate;
    end if;
  end;
  if (select cost_micros from public.generated_assets where id = v_id) <> 1500 then
    raise exception 'FAIL: cost changed on a refused second result';
  end if;

  -- Once approved, the same row is visible to clients, file identity only.
  update public.generated_assets set moderation = 'approved' where id = v_id;
  if not exists (
    select 1 from public.list_generated_assets()
    where id = v_id and storage_path = 'image/worker_slot_en.png'
  ) then
    raise exception 'FAIL: approved asset missing from the catalog';
  end if;
end $$;
select 'worker_claim_and_result' as check, true as ok;

-- A failure keeps its provenance and does not block the slot.
do $$
declare
  v_id uuid;
  v_hash text;
begin
  v_hash := nano_internal.generated_asset_hash(
    'video', 'celebration_clip', 'en', '16:9', 'a short celebration', 'v1'
  );
  insert into public.generated_assets
    (kind, slot, locale, aspect_ratio, prompt, prompt_version, prompt_hash,
     provider_id)
  values
    ('video', 'celebration_clip', 'en', '16:9', 'a short celebration', 'v1',
     v_hash, 'configured_video')
  returning id into v_id;

  perform public.claim_generated_asset(v_id);
  perform public.record_generated_asset_failure(
    v_id, 'PROVIDER_UNCONFIGURED', 'No video provider key in this environment', 90
  );

  if (select status from public.generated_assets where id = v_id) <> 'failed' then
    raise exception 'FAIL: failure not recorded';
  end if;
  if not exists (
    select 1 from public.generation_attempts
    where asset_id = v_id and outcome = 'failed'
      and error_code = 'PROVIDER_UNCONFIGURED'
  ) then
    raise exception 'FAIL: failed attempt not closed';
  end if;

  -- The reuse index ignores failures, so the same ask can be tried again.
  insert into public.generated_assets
    (kind, slot, locale, aspect_ratio, prompt, prompt_version, prompt_hash,
     provider_id)
  values
    ('video', 'celebration_clip', 'en', '16:9', 'a short celebration', 'v1',
     v_hash, 'configured_video');

  if (
    select count(*) from public.generated_assets
    where prompt_hash = v_hash
  ) <> 2 then
    raise exception 'FAIL: retry after failure was blocked';
  end if;

  -- A failure needs a reason.
  begin
    perform public.record_generated_asset_failure(
      (select id from public.generated_assets
       where prompt_hash = v_hash and status = 'requested'),
      '   '
    );
    raise exception 'FAIL: failure accepted without a code';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
    if sqlstate <> 'NM005' then
      raise exception 'FAIL: unexpected empty-code error %', sqlstate;
    end if;
  end;
end $$;
select 'failure_keeps_provenance_and_allows_retry' as check, true as ok;
rollback;

-- ---------------------------------------------------------------------------
-- Nothing above left anything behind.
-- ---------------------------------------------------------------------------
select 'no_test_rows_remain' as check,
  (select count(*) from public.generated_assets) = 0
  and (select count(*) from public.generation_attempts) = 0 as ok;
