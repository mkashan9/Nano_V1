-- MED-06 a way to put a hand-made picture into the catalog.
--
-- Every image Nano has generated came from Pollinations, and Pollinations now
-- serves exactly one model to callers without a token. That model cannot hold a
-- clean edge. Asked for a flat vector companion it returns a blur; asked for a
-- mascot it returns a photograph of a child. The first real companion image was
-- rejected on sight for precisely that reason, and no rewording fixes it,
-- because the fault is the model rather than the prompt.
--
-- There are two ways out and they are not exclusive. Buy a provider that can
-- draw, which is a purchase, a key, and somebody's decision. Or let a person
-- supply the picture. This is the second, and it earns its place either way:
-- the handbook's asset ladder begins at Tier 0 static art, and static art is
-- drawn by a human far more often than it is generated.
--
-- Nothing here weakens the gate MED-05 built. Curated art is registered
-- `unreviewed` like anything else, joins the same queue, and stays invisible to
-- every learner until a reviewer approves it. The only thing that changes is
-- where the bytes came from, and that is recorded rather than hidden.

-- ---------------------------------------------------------------------------
-- A provider that does not generate
-- ---------------------------------------------------------------------------
-- Calling a human a "provider" is a small lie that buys a large simplicity:
-- `generated_assets.provider_id` is a foreign key, every reader already knows
-- how to display a provider, and a reviewer looking at the queue learns where
-- the picture came from in the column they already read.
--
-- It must never be the default. An unqualified request for an image is a
-- request to generate one, and a default that cannot generate would turn every
-- such request into a failure nobody asked for.
insert into public.generation_providers
  (id, kind, is_enabled, is_default, requires_key, composes_from_art, notes)
values (
  'curated_upload',
  'image',
  true,
  false,
  false,
  false,
  'MED-06 art supplied by a person rather than generated. No endpoint and no '
  'key: the bytes arrive by upload and the row is registered afterwards. Never '
  'the default, because asking for an image means asking to generate one.'
)
on conflict (id) do update
set
  is_enabled = excluded.is_enabled,
  requires_key = excluded.requires_key,
  notes = excluded.notes,
  updated_at = timezone('utc', now());

-- ---------------------------------------------------------------------------
-- Letting a reviewer put a file in the bucket
-- ---------------------------------------------------------------------------
-- Until now only the service role could write here, because until now only the
-- Edge Function had anything to write. A curated picture has no Edge Function
-- behind it, so the person supplying it needs to be able to place the file.
--
-- This grants less than it looks like it does. A file in this bucket is inert:
-- learners read through `asset_object_is_published`, which is a lookup from the
-- object's name to a `generated_assets` row that is both ready and approved. An
-- uploaded file with no row is unreachable by every learner in the system, and
-- the row that would reach it cannot be created without passing the function
-- below and then a human reviewer. A platform admin can already approve
-- anything into a child's hands; being able to place bytes adds no authority
-- they did not already hold.
drop policy if exists generated_assets_bucket_write_curated on storage.objects;
create policy generated_assets_bucket_write_curated
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'generated-assets'
    and nano_internal.is_platform_admin()
  );

-- ---------------------------------------------------------------------------
-- Registering it
-- ---------------------------------------------------------------------------
-- The upload and the row are deliberately two steps. Storage either has the
-- bytes or it does not, and the row asserts `ready`, which the table's own
-- constraint reads as a promise that a file exists. Checking the object is
-- present before making that promise is what stops the catalog advertising
-- something storage cannot serve.
create or replace function public.register_curated_asset(
  p_slot text,
  p_description text,
  p_storage_path text,
  p_content_type text,
  p_byte_size bigint,
  p_checksum text,
  p_rights text,
  p_aspect_ratio text default '1:1',
  p_locale text default 'en',
  p_feature text default 'companion'
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal, storage
as $$
declare
  v_actor uuid := auth.uid();
  v_slot text := btrim(coalesce(p_slot, ''));
  v_description text := btrim(coalesce(p_description, ''));
  v_path text := btrim(coalesce(p_storage_path, ''));
  v_rights text := btrim(coalesce(p_rights, ''));
  v_aspect text := btrim(coalesce(p_aspect_ratio, '1:1'));
  v_locale text := btrim(coalesce(p_locale, 'en'));
  v_checksum text := btrim(coalesce(p_checksum, ''));
  v_hash text;
  v_id uuid;
begin
  if v_actor is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NM001',
      message = 'Only platform admins can register curated art.';
  end if;

  if v_slot = '' or v_description = '' or v_path = '' then
    raise exception using
      errcode = 'NM004',
      message = 'Curated art needs a slot, a description, and a file.';
  end if;

  -- Rights are not paperwork. A picture with no stated origin is a picture
  -- nobody can defend when a school asks where it came from, and by then it is
  -- already on a child's screen.
  if v_rights = '' then
    raise exception using
      errcode = 'NM004',
      message = 'Curated art needs its rights recorded.';
  end if;

  if coalesce(p_byte_size, 0) <= 0 or v_checksum = '' then
    raise exception using
      errcode = 'NM004',
      message = 'Curated art needs a size and a checksum.';
  end if;

  if not exists (
    select 1
    from storage.objects
    where bucket_id = 'generated-assets'
      and name = v_path
  ) then
    raise exception using
      errcode = 'NM004',
      message = 'That file is not in the generated-assets bucket.';
  end if;

  -- The same hash a generated asset gets, so curated art obeys the same reuse
  -- rule: registering the identical picture for the identical slot twice is one
  -- row, and a rejected one steps out of the way for a better attempt.
  -- `curated` as the prompt version is what keeps a described picture and a
  -- generated one from colliding when the words happen to match.
  v_hash := nano_internal.generated_asset_hash(
    'image', v_slot, v_locale, v_aspect, v_description, 'curated', null
  );

  begin
    insert into public.generated_assets (
      kind, slot, locale, aspect_ratio,
      prompt, prompt_version, prompt_hash,
      provider_id, status, moderation,
      storage_bucket, storage_path, content_type, byte_size, checksum,
      cost_micros, rights, provenance,
      feature, requested_by, requested_at, completed_at
    )
    values (
      'image', v_slot, v_locale, v_aspect,
      v_description, 'curated', v_hash,
      'curated_upload', 'ready', 'unreviewed',
      'generated-assets', v_path, coalesce(nullif(btrim(coalesce(p_content_type, '')), ''), 'application/octet-stream'),
      p_byte_size, v_checksum,
      -- No provider was paid, and a budget that counts an unspent zero as spend
      -- would refuse tomorrow's generation for a picture that cost nothing.
      0, v_rights,
      jsonb_build_object(
        'source', 'curated',
        'supplied_by', v_actor,
        'registered_at', timezone('utc', now())
      ),
      btrim(coalesce(p_feature, 'companion')), v_actor,
      timezone('utc', now()), timezone('utc', now())
    )
    returning id into v_id;
  exception when unique_violation then
    raise exception using
      errcode = 'NM004',
      message = 'That picture is already registered for this slot.';
  end;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id,
     previous_value, new_value, reason)
  values (
    v_actor,
    'superadmin',
    'create',
    'generated_asset',
    v_id::text,
    null,
    jsonb_build_object(
      'source', 'curated',
      'kind', 'image',
      'slot', v_slot,
      'locale', v_locale,
      'aspect_ratio', v_aspect,
      'moderation', 'unreviewed'
    ),
    'Curated art registered; awaiting review.'
  );

  return jsonb_build_object(
    'id', v_id,
    'slot', v_slot,
    'aspect_ratio', v_aspect,
    'status', 'ready',
    'moderation', 'unreviewed'
  );
end;
$$;

comment on function public.register_curated_asset(
  text, text, text, text, bigint, text, text, text, text, text
) is
  'MED-06 register a picture a person supplied. Enters the catalog ready and '
  'unreviewed, so a curated image faces the same reviewer as a generated one.';

revoke all on function public.register_curated_asset(
  text, text, text, text, bigint, text, text, text, text, text
) from public, anon;
grant execute on function public.register_curated_asset(
  text, text, text, text, bigint, text, text, text, text, text
) to authenticated, service_role;
