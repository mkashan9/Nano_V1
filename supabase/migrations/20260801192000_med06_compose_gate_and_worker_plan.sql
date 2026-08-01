-- MED-06 the two entry points that know a clip is composed rather than invented:
-- the one a curator calls, which refuses before any money is committed, and the
-- one the worker calls, which will not describe a movie unless the picture in it
-- has been approved.

-- ---------------------------------------------------------------------------
-- Requesting a clip, when the provider composes
-- ---------------------------------------------------------------------------
-- Same body as MED-04 with one gate added. Before a composing provider is
-- reached, the reaction must have art that a reviewer approved in this shape.
-- The check lives here rather than in the adapter because this is where the
-- money is committed: a refusal at this point costs nothing, and a refusal
-- inside the adapter would already have been counted against the day's budget.
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
      -- Not a fault and not a bug: the reviewer simply has not approved a
      -- picture of this companion in this shape yet. Saying so plainly is what
      -- tells a curator the next step is the review queue, not a retry.
      raise exception using
        errcode = 'NM011',
        message = 'This reaction has no approved companion art in this shape to animate.';
    end if;
  end if;

  -- Locale is 'en' and stays 'en': a clip is silent, so a second language would
  -- be a second copy of identical frames. The client's English fallback already
  -- hands it to an Urdu learner.
  return public.request_generated_asset(
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
end;
$$;

comment on function public.request_reaction_clip(text, text) is
  'MED-06 ask for a clip of a published reaction. When the provider composes, '
  'the reaction must already have approved art in this shape, so no picture a '
  'reviewer has not seen is ever sent to a rendering service.';

revoke all on function public.request_reaction_clip(text, text) from public, anon;
grant execute on function public.request_reaction_clip(text, text)
  to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- What the worker needs to build a movie
-- ---------------------------------------------------------------------------
-- The Edge Function has the service role and could read these three tables
-- itself, but then the rule about approved art would live in TypeScript in one
-- place and in SQL in another. This returns nothing at all unless the art is
-- approved, so the worker cannot compose something the database would have
-- refused, even by accident.
create or replace function public.reaction_clip_composition(
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
  v_art public.generated_assets;
  v_aspect text := btrim(coalesce(p_aspect_ratio, '1:1'));
begin
  -- The worker only. A platform admin has no reason to ask for this: it is a
  -- rendering instruction, not something a person reviews or acts on.
  if not nano_internal.is_generation_worker() then
    raise exception using
      errcode = 'NM003',
      message = 'Only the generation worker can read a composition.';
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

  v_art := nano_internal.approved_companion_art(v_clip.slug, v_aspect);
  if v_art.id is null then
    raise exception using
      errcode = 'NM011',
      message = 'This reaction has no approved companion art in this shape to animate.';
  end if;

  return jsonb_build_object(
    'slug', v_clip.slug,
    'motion', v_version.motion,
    'duration_seconds', v_version.duration_seconds,
    'aspect_ratio', v_aspect,
    'source_bucket', v_art.storage_bucket,
    'source_path', v_art.storage_path,
    'source_asset_id', v_art.id
  );
end;
$$;

comment on function public.reaction_clip_composition(text, text) is
  'MED-06 the movie a worker should build for a reaction: the approved picture '
  'to animate and the authored motion to animate it with. Refuses unless a '
  'reviewer has approved art in this shape.';

revoke all on function public.reaction_clip_composition(text, text)
  from public, anon, authenticated;
grant execute on function public.reaction_clip_composition(text, text)
  to service_role;
