-- MED-06 adversarial checks for the record of what a clip was made of.
--
-- The compose gate guarantees that a clip is only ever made from art a reviewer
-- approved. That guarantee is worth very little if the finished clip cannot say
-- which picture that was — a reviewer looking at a moving companion has no way
-- back to the still one, and nobody auditing later can tell whether the gate
-- actually held.
--
-- It did not survive the first live render. A composed job spans two
-- invocations, only the first knows the source art, and the second wrote its
-- own ignorance over the top. So these blocks attack the record rather than the
-- gate: they try to produce a finished clip that has forgotten its origin.
--
-- Every block rolls back, so the fixtures survive the run.
--   dddddddd-… platform admin

-- ---------------------------------------------------------------------------
-- Asking for a clip writes down what it will be made of
-- ---------------------------------------------------------------------------
-- The stamp happens in the function that already resolved the picture in order
-- to refuse without one. Anywhere later would be a second resolution, and a
-- second resolution answers "what is approved now" rather than "what was used".
begin;
  set local role authenticated;
  set local request.jwt.claims = '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';
  do $prov$
  declare
    v_result jsonb;
    v_asset public.generated_assets;
    v_art public.generated_assets;
  begin
    v_art := nano_internal.approved_companion_art('guide_greeting', '1:1');
    if v_art.id is null then
      raise exception 'SKIP-AS-FAIL: the fixture has no approved companion art';
    end if;

    v_result := public.request_reaction_clip('guide_greeting', '1:1');
    select * into v_asset
    from public.generated_assets
    where id = (v_result->'asset'->>'id')::uuid;

    -- The authored movement, not a default and not a guess.
    if v_asset.provenance->>'motion' <> 'driftIn' then
      raise exception 'FAIL: the clip recorded motion %',
        coalesce(v_asset.provenance->>'motion', '<null>');
    end if;

    -- And the exact picture, by id, so a reviewer can open it.
    if (v_asset.provenance->>'composed_from_asset_id')::uuid <> v_art.id then
      raise exception 'FAIL: the clip points at % rather than the approved art %',
        coalesce(v_asset.provenance->>'composed_from_asset_id', '<null>'), v_art.id;
    end if;
  end $prov$;
rollback;

-- ---------------------------------------------------------------------------
-- Finishing the clip cannot erase them
-- ---------------------------------------------------------------------------
-- This is the actual regression. The worker that collects a finished render has
-- no idea what the source art was — by design, so that a reviewer changing
-- their mind mid-queue cannot throw away a paid render — and it reports
-- `motion: null`. That is a statement of ignorance, and ignorance must not
-- overwrite knowledge.
begin;
  set local role authenticated;
  set local request.jwt.claims = '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';
  do $prov$
  declare
    v_result jsonb;
    v_id uuid;
  begin
    v_result := public.request_reaction_clip('guide_greeting', '1:1');
    v_id := (v_result->'asset'->>'id')::uuid;

    -- Put it back in flight so the recorder will accept it. Done directly
    -- rather than through a claim because the claim path is MED-02's test, not
    -- this one.
    reset role;
    update public.generated_assets set status = 'generating' where id = v_id;

    -- The worker is a JWT claim rather than a Postgres role, so this is what
    -- actually makes the recorder accept the call.
    perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
    perform public.record_generated_asset_result(
      p_asset_id => v_id,
      p_storage_bucket => 'generated-assets',
      p_storage_path => 'video/guide_greeting_shortClip/en/provenance_probe.mp4',
      p_content_type => 'video/mp4',
      p_byte_size => 1234,
      p_checksum => 'abc123',
      p_provider_reference => 'probe',
      p_cost_micros => 0,
      p_latency_ms => 1,
      p_rights => null,
      -- Exactly what the deployed worker sends when it collects a job it did
      -- not start.
      p_provenance => jsonb_build_object(
        'motion', null,
        'composed_from_asset_id', null,
        'provider_id', 'json2video_compose'
      )
    );

    if (select provenance->>'motion' from public.generated_assets where id = v_id)
       is distinct from 'driftIn' then
      raise exception 'FAIL: finishing the clip erased the motion';
    end if;
    if (select provenance->>'composed_from_asset_id' from public.generated_assets where id = v_id)
       is null then
      raise exception 'FAIL: finishing the clip erased the source art';
    end if;
    -- The worker still gets to add what it does know.
    if (select provenance->>'provider_id' from public.generated_assets where id = v_id)
       <> 'json2video_compose' then
      raise exception 'FAIL: the worker''s own account was dropped';
    end if;
  end $prov$;
rollback;

-- A worker that does know better still wins. Merging must not freeze the first
-- value in place, or a re-composed clip would keep pointing at the picture it
-- used to be made from.
begin;
  set local role authenticated;
  set local request.jwt.claims = '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';
  do $prov$
  declare
    v_result jsonb;
    v_id uuid;
  begin
    v_result := public.request_reaction_clip('guide_greeting', '1:1');
    v_id := (v_result->'asset'->>'id')::uuid;

    reset role;
    update public.generated_assets set status = 'generating' where id = v_id;

    perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
    perform public.record_generated_asset_result(
      p_asset_id => v_id,
      p_storage_bucket => 'generated-assets',
      p_storage_path => 'video/guide_greeting_shortClip/en/provenance_probe2.mp4',
      p_content_type => 'video/mp4',
      p_byte_size => 1234,
      p_checksum => 'abc123',
      p_provenance => jsonb_build_object('motion', 'pushIn')
    );

    if (select provenance->>'motion' from public.generated_assets where id = v_id) <> 'pushIn' then
      raise exception 'FAIL: a worker that knew the motion could not record it';
    end if;
  end $prov$;
rollback;
