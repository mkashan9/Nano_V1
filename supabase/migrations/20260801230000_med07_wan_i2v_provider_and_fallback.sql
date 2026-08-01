-- MED-07: character animation, and somewhere to fall when it is unavailable.
--
-- The owner rejected MED-06's first composed clip as looking very fake. It was:
-- json2video panned a camera across a still and nothing in the picture moved.
-- Wan 2.2 image-to-video animates the character instead.
--
-- The awkward part is what it costs in reliability. Wan runs on a public
-- Hugging Face Space with no agreement behind it, which can sleep, queue behind
-- strangers, or disappear, and which cannot be collected from later — the
-- worker must hold the connection for the whole render or lose it. json2video
-- is worse-looking but dependable and already paid for, so it stays as the
-- place to fall rather than being deleted.
--
-- Fallback is a column rather than a branch in the worker, for the same reason
-- the provider itself is: swapping who covers for whom should be a row, not a
-- redeploy.

alter table public.generation_providers
  add column if not exists fallback_provider_id text
    references public.generation_providers (id);

comment on column public.generation_providers.fallback_provider_id is
  'MED-07: who serves this request when this provider is unusable. Same kind, '
  'one hop only, never itself. Null means a failure here is simply a failure.';

-- One hop, same kind, never itself. A chain would let a single bad row send a
-- request wandering, and a cross-kind fallback would answer a clip with a
-- recording.
create or replace function nano_internal.generation_provider_fallback_is_sane()
returns trigger
language plpgsql
as $$
declare
  v_kind public.generated_asset_kind;
  v_onward text;
begin
  if new.fallback_provider_id is null then
    return new;
  end if;

  if new.fallback_provider_id = new.id then
    raise exception 'NM012: A provider cannot fall back to itself.'
      using errcode = 'check_violation';
  end if;

  select kind, fallback_provider_id
    into v_kind, v_onward
  from public.generation_providers
  where id = new.fallback_provider_id;

  if not found then
    raise exception 'NM012: Fallback provider % does not exist.',
      new.fallback_provider_id
      using errcode = 'foreign_key_violation';
  end if;

  if v_kind <> new.kind then
    raise exception 'NM012: Fallback provider % serves %, not %.',
      new.fallback_provider_id, v_kind, new.kind
      using errcode = 'check_violation';
  end if;

  if v_onward is not null then
    raise exception 'NM012: Fallback chains are not allowed (% already falls back to %).',
      new.fallback_provider_id, v_onward
      using errcode = 'check_violation';
  end if;

  return new;
end $$;

drop trigger if exists generation_providers_fallback_guard
  on public.generation_providers;

create trigger generation_providers_fallback_guard
  before insert or update of fallback_provider_id, kind
  on public.generation_providers
  for each row
  execute function nano_internal.generation_provider_fallback_is_sane();

insert into public.generation_providers
  (id, kind, is_enabled, is_default, requires_key, composes_from_art,
   fallback_provider_id, notes)
values (
  'wan_i2v_space',
  'video',
  true,
  false,
  -- No key. It is a public Space, which is precisely why it has no SLA and
  -- needs somewhere to fall.
  false,
  -- Still composes from approved art. The gate MED-06 built is unchanged: the
  -- model animates a picture a reviewer signed off, it does not invent one.
  true,
  'json2video_compose',
  'MED-07: Wan 2.2 image-to-video on a public Hugging Face Space. Animates the '
  || 'character rather than panning a camera. Not resumable — the worker holds '
  || 'the connection for the whole render — and unmetered, so cost is recorded '
  || 'as zero. Falls back to json2video_compose when the Space is unusable. An '
  || 'i2v model can invent, so the MED-05 review gate is load-bearing here.'
)
on conflict (id) do update set
  is_enabled = excluded.is_enabled,
  requires_key = excluded.requires_key,
  composes_from_art = excluded.composes_from_art,
  fallback_provider_id = excluded.fallback_provider_id,
  notes = excluded.notes,
  updated_at = timezone('utc', now());

-- Two statements, because the unique index on the default admits no moment
-- where two providers of a kind both claim it (learned in MED-03).
update public.generation_providers
set is_default = false, updated_at = timezone('utc', now())
where kind = 'video' and is_default;

update public.generation_providers
set is_default = true, updated_at = timezone('utc', now())
where id = 'wan_i2v_space';

-- Recording who actually made the file.
--
-- The asset row names a provider at request time. When the primary is down the
-- bytes come from somewhere else, and a review queue that still shows the
-- provider we asked is a review queue that lies about what a reviewer is
-- looking at. This corrects the row and leaves the reason behind it.
create or replace function public.record_generated_asset_provider_swap(
  p_asset_id uuid,
  p_provider_id text,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public, nano_internal, pg_temp
as $$
declare
  v_previous text;
begin
  if not nano_internal.is_generation_worker() then
    raise exception 'NM003: Only the generation worker can record a result.'
      using errcode = 'insufficient_privilege';
  end if;

  select provider_id into v_previous
  from public.generated_assets
  where id = p_asset_id
  for update;

  if not found then
    raise exception 'NM004: No such asset.' using errcode = 'no_data_found';
  end if;

  if v_previous is not distinct from p_provider_id then
    return;
  end if;

  update public.generated_assets
  set
    provider_id = p_provider_id,
    provenance = coalesce(provenance, '{}'::jsonb) || jsonb_build_object(
      'provider_id', p_provider_id,
      'fell_back_from', v_previous,
      'fallback_reason', p_reason
    ),
    updated_at = timezone('utc', now())
  where id = p_asset_id;
end $$;

comment on function public.record_generated_asset_provider_swap(uuid, text, text) is
  'MED-07: the primary provider was unusable and another made the file. Keeps '
  'provider_id honest for the reviewer and records what was tried first.';

revoke all on function public.record_generated_asset_provider_swap(uuid, text, text)
  from public, anon, authenticated;

grant execute on function public.record_generated_asset_provider_swap(uuid, text, text)
  to service_role;
