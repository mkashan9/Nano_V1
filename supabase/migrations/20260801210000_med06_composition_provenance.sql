-- MED-06 remember what a clip was actually made of.
--
-- The first composed clip rendered correctly and then recorded `motion: null`
-- and `composed_from_asset_id: null` — precisely the two facts the compose gate
-- exists to guarantee, missing from the record of the thing it guarded.
--
-- The cause is that a composed render spans two invocations. The first resolves
-- the approved picture and the authored motion, submits the job, and ends. The
-- second, minutes later, collects the file and writes the asset. Only the first
-- ever knew which picture was used, and it deliberately does not re-resolve on
-- the second, because a paid render should not be discarded merely because a
-- reviewer changed their mind while it was queued. So the worker arrives at the
-- recording step holding nulls, and `record_generated_asset_result` wrote them
-- over the top of everything.
--
-- Re-resolving at collection time would not have fixed it. That answers "what
-- is approved now", which is a different question from "what was animated", and
-- it answers nothing at all if the art has since been rejected.
--
-- So the facts are written down by the function that already established them,
-- at the moment it establishes them, and the recording step is no longer
-- allowed to erase what it does not happen to know. Both halves live in SQL for
-- the same reason the gate does: the database decides what a clip may be
-- composed from, so the database is what should remember it. A worker that
-- forgets is then merely a worker that adds nothing, rather than one that
-- destroys the record.

-- ---------------------------------------------------------------------------
-- Undo a wrong turn
-- ---------------------------------------------------------------------------
-- An earlier attempt widened this function so the worker could carry the
-- composition facts forward itself. That works, but it puts the memory in the
-- one place that demonstrably forgets, and it leaves two parameters no caller
-- passes. Dropped back to the shape MED-01 gave it.
drop function if exists public.record_generated_asset_progress(uuid, text, integer, text, uuid);

create or replace function public.record_generated_asset_progress(
  p_asset_id uuid,
  p_provider_job_id text default null,
  p_poll_after_seconds integer default 15
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_asset public.generated_assets;
begin
  if not nano_internal.is_generation_worker() then
    raise exception using
      errcode = 'NM003',
      message = 'Only the generation worker can report progress.';
  end if;

  update public.generated_assets
  set provider_job_id =
        coalesce(nullif(btrim(coalesce(p_provider_job_id, '')), ''),
                 provider_job_id),
      poll_after = timezone('utc', now())
        + make_interval(secs => greatest(coalesce(p_poll_after_seconds, 15), 1)),
      claim_expires_at =
        timezone('utc', now()) + nano_internal.generation_claim_ttl(kind)
  where id = p_asset_id and status = 'generating'
  returning * into v_asset;

  if v_asset.id is null then
    raise exception using
      errcode = 'NM004',
      message = 'That asset is not generating.';
  end if;

  return nano_internal.generated_asset_json(v_asset.id);
end;
$$;

revoke all on function public.record_generated_asset_progress(uuid, text, integer)
  from public, anon, authenticated;
grant execute on function public.record_generated_asset_progress(uuid, text, integer)
  to service_role;

-- ---------------------------------------------------------------------------
-- Write the facts down where they are known
-- ---------------------------------------------------------------------------
-- Same body as the MED-06 compose gate, with the resolved picture and motion
-- stamped onto the asset row. This function has already found both — it had to,
-- in order to refuse — so recording them costs one statement and closes the gap
-- for good. The stamp also runs on the reuse path, which quietly repairs any
-- row written before this migration.
create or replace function public.request_reaction_clip(
  p_slug text,
  p_aspect_ratio text default '1:1'
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_clip public.reaction_clips;
  v_version public.reaction_clip_versions;
  v_provider public.generation_providers;
  v_art public.generated_assets;
  v_aspect text := btrim(coalesce(p_aspect_ratio, '1:1'));
  v_result jsonb;
  v_asset_id uuid;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NM001',
      message = 'Only platform admins can request reaction clips.';
  end if;

  select * into v_clip
  from public.reaction_clips
  where slug = btrim(coalesce(p_slug, ''));

  if v_clip.id is null then
    raise exception using
      errcode = 'NM004',
      message = 'That reaction is not in the clip library.';
  end if;

  select * into v_version
  from public.reaction_clip_versions
  where clip_id = v_clip.id and status = 'published';

  if v_version.id is null then
    raise exception using
      errcode = 'NM004',
      message = 'That reaction has no published direction.';
  end if;

  -- Framing is part of the direction, not a rendering detail. A clip written for
  -- a square inline stage is not the same clip in a tall story card.
  if not (v_aspect = any (v_version.aspect_ratios)) then
    raise exception using
      errcode = 'NM009',
      message = 'That reaction is not authored for this shape.';
  end if;

  select * into v_provider
  from public.generation_providers
  where kind = 'video' and is_default;

  if v_provider.composes_from_art then
    v_art := nano_internal.approved_companion_art(v_clip.slug, v_aspect);
    if v_art.id is null then
      raise exception using
        errcode = 'NM011',
        message = 'This reaction has no approved companion art in this shape to animate.';
    end if;
  end if;

  -- Locale is 'en' and stays 'en': a clip is silent, so a second language would
  -- be a second copy of identical frames. The client's English fallback already
  -- hands it to an Urdu learner.
  v_result := public.request_generated_asset(
    p_kind => 'video',
    p_slot => nano_internal.reaction_clip_slot(v_clip.slug),
    p_prompt => v_version.direction,
    p_prompt_version => 'v' || v_version.version::text,
    p_locale => 'en',
    p_aspect_ratio => v_aspect,
    p_provider_id => null,
    p_feature => 'companion',
    p_school_id => null,
    p_voice_id => null
  );

  if v_art.id is not null then
    v_asset_id := (v_result->'asset'->>'id')::uuid;
    update public.generated_assets
    set provenance = provenance || jsonb_build_object(
          'motion', v_version.motion,
          'composed_from_asset_id', v_art.id
        )
    where id = v_asset_id;
  end if;

  return v_result;
end;
$$;

comment on function public.request_reaction_clip(text, text) is
  'MED-06 ask for a clip of a published reaction. When the provider composes, the '
  'reaction must already have approved art in this shape, and the picture and '
  'motion chosen here are recorded on the asset so the finished clip can say what '
  'it was made from.';

revoke all on function public.request_reaction_clip(text, text) from public, anon;
grant execute on function public.request_reaction_clip(text, text) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Stop the recording step from erasing them
-- ---------------------------------------------------------------------------
-- One line changes: provenance is merged rather than replaced, and null-valued
-- keys in the worker's account are dropped before merging. A worker reporting
-- `motion: null` is not asserting that there was no motion — it is saying it
-- does not know — and a claim of ignorance should never overwrite knowledge.
create or replace function public.record_generated_asset_result(
  p_asset_id uuid,
  p_storage_bucket text,
  p_storage_path text,
  p_content_type text,
  p_byte_size bigint,
  p_checksum text,
  p_provider_reference text default null,
  p_cost_micros integer default 0,
  p_latency_ms integer default null,
  p_rights text default null,
  p_provenance jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_asset public.generated_assets;
begin
  if not nano_internal.is_generation_worker() then
    raise exception using
      errcode = 'NM003',
      message = 'Only the generation worker can record a result.';
  end if;

  update public.generated_assets
  set status = 'ready',
      storage_bucket = p_storage_bucket,
      storage_path = p_storage_path,
      content_type = p_content_type,
      byte_size = p_byte_size,
      checksum = p_checksum,
      provider_reference = p_provider_reference,
      cost_micros = cost_micros + greatest(coalesce(p_cost_micros, 0), 0),
      rights = coalesce(p_rights, rights),
      provenance = provenance || jsonb_strip_nulls(coalesce(p_provenance, '{}'::jsonb)),
      error_code = null,
      error_message = null,
      completed_at = timezone('utc', now())
  where id = p_asset_id and status = 'generating'
  returning * into v_asset;

  if v_asset.id is null then
    raise exception using
      errcode = 'NM004',
      message = 'That asset is not being generated.';
  end if;

  update public.generation_attempts
  set outcome = 'succeeded',
      latency_ms = p_latency_ms,
      cost_micros = greatest(coalesce(p_cost_micros, 0), 0),
      finished_at = timezone('utc', now())
  where asset_id = v_asset.id and attempt_number = v_asset.attempts_count;

  perform nano_internal.record_generation_usage(
    v_asset.kind,
    v_asset.feature,
    v_asset.school_id,
    0,
    greatest(coalesce(p_cost_micros, 0), 0)
  );

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    null, 'service_role', 'update', 'generated_asset', v_asset.id::text,
    jsonb_build_object(
      'status', 'ready',
      'provider_id', v_asset.provider_id,
      'feature', v_asset.feature,
      'byte_size', p_byte_size,
      'checksum', p_checksum,
      'cost_micros', p_cost_micros
    )
  );

  return nano_internal.generated_asset_json(v_asset.id);
end;
$$;

revoke all on function public.record_generated_asset_result(
  uuid, text, text, text, bigint, text, text, integer, integer, text, jsonb
) from public, anon, authenticated;
grant execute on function public.record_generated_asset_result(
  uuid, text, text, text, bigint, text, text, integer, integer, text, jsonb
) to service_role;
