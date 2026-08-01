-- MED-05: the review queue, the history, and teaching reuse about rejection.

-- ---------------------------------------------------------------------------
-- The queue
-- ---------------------------------------------------------------------------
-- Refuses rather than returning nothing, so a school admin who reaches this is
-- told they may not, instead of being shown an empty queue and concluding
-- there is no work.
create or replace function public.list_assets_for_review(
  p_moderation text default null,
  p_kind text default null,
  p_limit integer default 100
)
returns table (
  id uuid,
  kind public.generated_asset_kind,
  slot text,
  locale text,
  aspect_ratio text,
  prompt text,
  prompt_version text,
  provider_id text,
  feature text,
  status public.generated_asset_status,
  moderation public.generated_asset_moderation,
  storage_bucket text,
  storage_path text,
  content_type text,
  byte_size bigint,
  checksum text,
  cost_micros integer,
  error_code text,
  requested_at timestamptz,
  completed_at timestamptz,
  reviewed_at timestamptz,
  review_note text,
  reviewer_name text
)
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_moderation public.generated_asset_moderation;
  v_kind public.generated_asset_kind;
  v_limit integer := least(greatest(coalesce(p_limit, 100), 1), 500);
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NM010',
      message = 'Only platform admins can see the review queue.';
  end if;

  begin
    v_moderation := nullif(lower(btrim(coalesce(p_moderation, ''))), '')
      ::public.generated_asset_moderation;
    v_kind := nullif(lower(btrim(coalesce(p_kind, ''))), '')
      ::public.generated_asset_kind;
  exception when invalid_text_representation then
    raise exception using
      errcode = 'NM010',
      message = 'Unknown moderation state or asset kind.';
  end;

  return query
  select
    ga.id,
    ga.kind,
    ga.slot,
    ga.locale,
    ga.aspect_ratio,
    ga.prompt,
    ga.prompt_version,
    ga.provider_id,
    ga.feature,
    ga.status,
    ga.moderation,
    ga.storage_bucket,
    ga.storage_path,
    ga.content_type,
    ga.byte_size,
    ga.checksum,
    ga.cost_micros,
    ga.error_code,
    ga.requested_at,
    ga.completed_at,
    ga.reviewed_at,
    ga.review_note,
    p.display_name
  from public.generated_assets ga
  left join public.profiles p on p.id = ga.reviewed_by
  where (v_moderation is null or ga.moderation = v_moderation)
    and (v_kind is null or ga.kind = v_kind)
  -- Work first: things that can be decided right now, oldest ask at the top so
  -- nothing waits forever behind a busy day.
  order by
    (ga.moderation = 'unreviewed' and ga.status = 'ready') desc,
    ga.requested_at asc
  limit v_limit;
end;
$$;

comment on function public.list_assets_for_review(text, text, integer) is
  'MED-05 the review queue with full provenance. Superadmin only; refuses '
  'anyone else rather than showing them an empty list.';

revoke all on function public.list_assets_for_review(text, text, integer)
  from public, anon;
grant execute on function public.list_assets_for_review(text, text, integer)
  to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- What happened to one asset
-- ---------------------------------------------------------------------------
create or replace function public.asset_review_history(p_asset_id uuid)
returns table (
  id uuid,
  previous_moderation public.generated_asset_moderation,
  decision public.generated_asset_moderation,
  note text,
  reviewer_name text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NM010',
      message = 'Only platform admins can see review history.';
  end if;

  return query
  select
    e.id,
    e.previous_moderation,
    e.decision,
    e.note,
    p.display_name,
    e.created_at
  from public.asset_review_events e
  left join public.profiles p on p.id = e.reviewer_id
  where e.asset_id = p_asset_id
  order by e.created_at desc;
end;
$$;

revoke all on function public.asset_review_history(uuid) from public, anon;
grant execute on function public.asset_review_history(uuid)
  to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- The asset row now carries its decision
-- ---------------------------------------------------------------------------
create or replace function nano_internal.generated_asset_json(p_asset_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
  select jsonb_build_object(
    'id', ga.id,
    'kind', ga.kind,
    'slot', ga.slot,
    'locale', ga.locale,
    'aspect_ratio', ga.aspect_ratio,
    'prompt', ga.prompt,
    'prompt_version', ga.prompt_version,
    'prompt_hash', ga.prompt_hash,
    'provider_id', ga.provider_id,
    'provider_job_id', ga.provider_job_id,
    'voice_id', ga.voice_id,
    'feature', ga.feature,
    'status', ga.status,
    'moderation', ga.moderation,
    'storage_bucket', ga.storage_bucket,
    'storage_path', ga.storage_path,
    'content_type', ga.content_type,
    'byte_size', ga.byte_size,
    'checksum', ga.checksum,
    'cost_micros', ga.cost_micros,
    'attempts_count', ga.attempts_count,
    'error_code', ga.error_code,
    'error_message', ga.error_message,
    'requested_at', ga.requested_at,
    'completed_at', ga.completed_at,
    'reviewed_at', ga.reviewed_at,
    'review_note', ga.review_note
  )
  from public.generated_assets ga
  where ga.id = p_asset_id;
$$;

revoke all on function nano_internal.generated_asset_json(uuid) from public, anon;
grant execute on function nano_internal.generated_asset_json(uuid)
  to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Reuse learns about rejection
-- ---------------------------------------------------------------------------
-- Identical to the MED-04 definition except that a rejected row is no longer a
-- reuse candidate, so asking again after a rejection generates a replacement
-- instead of handing back the output that was just refused.
create or replace function public.request_generated_asset(
  p_kind public.generated_asset_kind,
  p_slot text,
  p_prompt text,
  p_prompt_version text,
  p_locale text default 'en',
  p_aspect_ratio text default '1:1',
  p_provider_id text default null,
  p_feature text default 'companion',
  p_school_id uuid default null,
  p_voice_id text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_provider public.generation_providers;
  v_feature text := lower(btrim(coalesce(p_feature, 'companion')));
  v_voice_id text := nullif(lower(btrim(coalesce(p_voice_id, ''))), '');
  v_hash text;
  v_existing public.generated_assets;
  v_id uuid;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NM001',
      message = 'Only platform admins can request generated assets.';
  end if;

  if p_provider_id is null then
    select * into v_provider
    from public.generation_providers
    where kind = p_kind and is_default;
  else
    select * into v_provider
    from public.generation_providers
    where id = p_provider_id;
  end if;

  if v_provider.id is null then
    raise exception using
      errcode = 'NM002',
      message = 'No provider is registered for this asset kind.';
  end if;
  if v_provider.kind <> p_kind then
    raise exception using
      errcode = 'NM002',
      message = 'That provider does not serve this asset kind.';
  end if;
  if not v_provider.is_enabled then
    raise exception using
      errcode = 'NM002',
      message = 'That provider is disabled.';
  end if;

  if v_voice_id is not null then
    if p_kind <> 'voice' then
      raise exception using
        errcode = 'NM002',
        message = 'Only a voice asset may name a voice.';
    end if;
    if not exists (
      select 1 from public.narration_voices
      where id = v_voice_id and is_enabled
    ) then
      raise exception using
        errcode = 'NM002',
        message = 'That voice is not available.';
    end if;
  end if;

  v_hash := nano_internal.generated_asset_hash(
    p_kind, p_slot, p_locale, p_aspect_ratio, p_prompt, p_prompt_version,
    v_voice_id
  );

  -- Reuse is checked before the budget: an ask that costs nothing must never be
  -- refused for being over a limit (MED-02). A rejected row is skipped, which is
  -- what lets a refused generation be replaced (MED-05).
  select * into v_existing
  from public.generated_assets
  where kind = p_kind and prompt_hash = v_hash
    and status <> 'failed' and moderation <> 'rejected';

  if v_existing.id is not null then
    -- An abandoned job is put back in the queue here rather than anywhere else,
    -- because this is the moment somebody has asked for the thing again.
    if nano_internal.release_stale_generation(v_existing.id) then
      return jsonb_build_object(
        'reused', true,
        'asset', nano_internal.generated_asset_json(v_existing.id)
      );
    end if;

    -- If releasing failed it, the row is no longer a reuse candidate and this ask
    -- becomes a fresh job, charged accordingly.
    select * into v_existing
    from public.generated_assets
    where kind = p_kind and prompt_hash = v_hash
      and status <> 'failed' and moderation <> 'rejected';

    if v_existing.id is not null then
      return jsonb_build_object(
        'reused', true,
        'asset', nano_internal.generated_asset_json(v_existing.id)
      );
    end if;
  end if;

  perform nano_internal.assert_generation_quota(p_kind, v_feature, p_school_id);

  insert into public.generated_assets
    (kind, slot, locale, aspect_ratio, prompt, prompt_version, prompt_hash,
     provider_id, requested_by, feature, school_id, voice_id)
  values
    (p_kind, btrim(p_slot), p_locale, p_aspect_ratio, btrim(p_prompt),
     btrim(p_prompt_version), v_hash, v_provider.id, auth.uid(),
     v_feature, p_school_id, v_voice_id)
  returning id into v_id;

  perform nano_internal.record_generation_usage(
    p_kind, v_feature, p_school_id, 1, 0
  );

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'superadmin', 'create', 'generated_asset', v_id::text,
    jsonb_build_object(
      'kind', p_kind,
      'slot', p_slot,
      'locale', p_locale,
      'aspect_ratio', p_aspect_ratio,
      'feature', v_feature,
      'school_id', p_school_id,
      'provider_id', v_provider.id,
      'voice_id', v_voice_id,
      'prompt_version', p_prompt_version,
      'prompt_hash', v_hash
    )
  );

  return jsonb_build_object(
    'reused', false,
    'asset', nano_internal.generated_asset_json(v_id)
  );
end;
$$;

comment on function public.request_generated_asset(
  public.generated_asset_kind, text, text, text, text, text, text, text, uuid, text
) is
  'MED-01/02/03/04/05 superadmin request. Reuse first, then budget, then the row. '
  'An abandoned job is returned to the queue and a rejected one is replaced '
  'rather than blocking its slot.';

revoke all on function public.request_generated_asset(
  public.generated_asset_kind, text, text, text, text, text, text, text, uuid, text
) from public, anon;
grant execute on function public.request_generated_asset(
  public.generated_asset_kind, text, text, text, text, text, text, text, uuid, text
) to authenticated, service_role;
