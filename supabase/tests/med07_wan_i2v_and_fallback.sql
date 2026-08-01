-- MED-07: character animation is the default, and falling back stays honest.
--
-- Adversarial checks that the Space is the default video provider, that its
-- fallback is exactly one hop to the composer, that a chain or a cross-kind
-- fallback is refused, and that a worker recording a swap leaves both the new
-- provider and the reason behind it on the row a reviewer will read.

begin;

do $$
declare
  v_default text;
  v_fallback text;
  v_count int;
  v_asset uuid;
  v_provider text;
  v_from text;
  v_reason text;
begin
  select count(*) into v_count
  from public.generation_providers
  where kind = 'video' and is_default;
  if v_count <> 1 then
    raise exception 'FAIL: expected one default video provider, found %', v_count;
  end if;

  select id, fallback_provider_id into v_default, v_fallback
  from public.generation_providers
  where kind = 'video' and is_default;

  if v_default <> 'wan_i2v_space' then
    raise exception 'FAIL: default video provider is %, expected wan_i2v_space',
      v_default;
  end if;

  if v_fallback <> 'json2video_compose' then
    raise exception 'FAIL: wan_i2v_space falls back to %, expected json2video_compose',
      v_fallback;
  end if;

  -- Still composes from art. The gate MED-06 built is load-bearing here too:
  -- an i2v model that invents its own picture would bypass the review of art.
  if not exists (
    select 1 from public.generation_providers
    where id = 'wan_i2v_space' and composes_from_art and not requires_key
  ) then
    raise exception 'FAIL: wan_i2v_space must compose from art and need no key';
  end if;

  -- Self-fallback.
  begin
    update public.generation_providers
    set fallback_provider_id = 'wan_i2v_space'
    where id = 'wan_i2v_space';
    raise exception 'FAIL: a provider was allowed to fall back to itself';
  exception
    when check_violation then null;
  end;

  -- Cross-kind fallback.
  begin
    update public.generation_providers
    set fallback_provider_id = 'fish_audio_voice'
    where id = 'wan_i2v_space';
    raise exception 'FAIL: a video provider was allowed to fall back to a voice';
  exception
    when check_violation then null;
  end;

  -- A chain.
  begin
    update public.generation_providers
    set fallback_provider_id = 'wan_i2v_space'
    where id = 'json2video_compose';
    raise exception 'FAIL: a fallback chain was allowed';
  exception
    when check_violation then null;
  end;

  -- Restore the expected fallback after the probes.
  update public.generation_providers
  set fallback_provider_id = 'json2video_compose'
  where id = 'wan_i2v_space';

  -- A worker may swap the provider on a row and leave both facts behind.
  insert into public.generated_assets (
    kind, slot, locale, aspect_ratio, prompt, prompt_version, prompt_hash,
    provider_id, status, moderation, feature
  ) values (
    'video', 'probe_fallback_swap', 'en', '1:1', 'probe', 'v1',
    'med07-fallback-swap', 'wan_i2v_space', 'requested', 'unreviewed', 'companion'
  )
  returning id into v_asset;

  perform set_config(
    'request.jwt.claims', '{"role":"service_role"}', true
  );

  perform public.record_generated_asset_provider_swap(
    v_asset, 'json2video_compose', 'PROVIDER_TIMEOUT'
  );

  select
    provider_id,
    provenance ->> 'fell_back_from',
    provenance ->> 'fallback_reason'
  into v_provider, v_from, v_reason
  from public.generated_assets
  where id = v_asset;

  if v_provider <> 'json2video_compose' then
    raise exception 'FAIL: swap left provider_id as %', v_provider;
  end if;
  if v_from <> 'wan_i2v_space' then
    raise exception 'FAIL: swap left fell_back_from as %', v_from;
  end if;
  if v_reason <> 'PROVIDER_TIMEOUT' then
    raise exception 'FAIL: swap left fallback_reason as %', v_reason;
  end if;

  -- Authenticated callers cannot rewrite the provider after the fact.
  begin
    perform set_config(
      'request.jwt.claims',
      '{"role":"authenticated","sub":"00000000-0000-0000-0000-0000000000aa"}',
      true
    );
    set local role authenticated;
    perform public.record_generated_asset_provider_swap(
      v_asset, 'gemini_veo_video', 'sneaky'
    );
    raise exception 'FAIL: an authenticated caller rewrote the provider';
  exception
    when insufficient_privilege then null;
  end;

  raise notice 'PASS: wan_i2v_space is the default with a sane one-hop fallback';
end $$;

rollback;
