-- MED-01: generated asset provider adapters.
--
-- Generation is an administration workflow, never something a learner's screen
-- triggers (handbook 10.5). So a request is superadmin-only, the provider is
-- chosen from a registry the database owns rather than from whatever a caller
-- names, and the only writer of a result is a worker holding the service role.
--
-- Every request is hashed over the things that change the output — kind, slot,
-- language, aspect ratio, prompt, prompt version — so asking twice reuses the
-- first answer instead of paying a provider twice. Failed rows are excluded from
-- that uniqueness, which is what makes a retry possible without a second table.
--
-- Learners read `public.generated_asset_catalog`, which carries the file and
-- nothing about how it was made: no prompt, no provider, no cost.

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
do $$ begin
  create type public.generated_asset_kind as enum ('image', 'voice', 'video');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.generated_asset_status as enum (
    'requested',
    'generating',
    'ready',
    'failed'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.generated_asset_moderation as enum (
    'unreviewed',
    'approved',
    'rejected'
  );
exception when duplicate_object then null;
end $$;

-- ---------------------------------------------------------------------------
-- Provider registry
-- ---------------------------------------------------------------------------
-- Mirrors docs/provider-registry/providers.yaml so a provider can be disabled
-- without a deploy, and so an adapter id in a row always means something.
create table if not exists public.generation_providers (
  id text primary key,
  kind public.generated_asset_kind not null,
  is_enabled boolean not null default true,
  is_default boolean not null default false,
  requires_key boolean not null default true,
  notes text not null default '',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.generation_providers is
  'MED-01 adapter registry: which provider may serve which asset kind. '
  'Superadmin-readable; changed by migration or superadmin, never by a client.';

comment on column public.generation_providers.requires_key is
  'True when the adapter needs a provider key from Edge Function env. Keys never '
  'appear in this table or in any client.';

-- One default per kind, so a request without a named provider is unambiguous.
create unique index if not exists generation_providers_default_idx
  on public.generation_providers (kind)
  where is_default;

drop trigger if exists generation_providers_set_updated_at
  on public.generation_providers;
create trigger generation_providers_set_updated_at
  before update on public.generation_providers
  for each row execute function public.set_updated_at();

insert into public.generation_providers
  (id, kind, is_enabled, is_default, requires_key, notes)
values
  (
    'pollinations_image',
    'image',
    true,
    true,
    false,
    'Primary image path; host image.pollinations.ai needs no privileged key.'
  ),
  (
    'configured_voice',
    'voice',
    true,
    true,
    true,
    'Learning Guide voice Aoede; VOICE_PROVIDER_API_KEY in Edge Function env.'
  ),
  (
    'configured_video',
    'video',
    true,
    true,
    true,
    'Short companion clips; VIDEO_PROVIDER_API_KEY in Edge Function env.'
  )
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- Generated assets
-- ---------------------------------------------------------------------------
create table if not exists public.generated_assets (
  id uuid primary key default gen_random_uuid(),
  kind public.generated_asset_kind not null,
  slot text not null check (btrim(slot) <> ''),
  locale text not null default 'en' check (locale in ('en', 'ur')),
  aspect_ratio text not null default '1:1'
    check (aspect_ratio ~ '^[0-9]{1,2}:[0-9]{1,2}$'),
  prompt text not null check (btrim(prompt) <> ''),
  prompt_version text not null check (btrim(prompt_version) <> ''),
  prompt_hash text not null,
  provider_id text not null references public.generation_providers (id),
  status public.generated_asset_status not null default 'requested',
  moderation public.generated_asset_moderation not null default 'unreviewed',
  storage_bucket text,
  storage_path text,
  content_type text,
  byte_size bigint check (byte_size is null or byte_size > 0),
  checksum text,
  provider_reference text,
  cost_micros integer not null default 0 check (cost_micros >= 0),
  rights text,
  provenance jsonb not null default '{}'::jsonb,
  error_code text,
  error_message text,
  attempts_count integer not null default 0 check (attempts_count >= 0),
  requested_by uuid references public.profiles (id),
  requested_at timestamptz not null default timezone('utc', now()),
  claimed_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint generated_assets_ready_has_file check (
    status <> 'ready'
    or (storage_bucket is not null and storage_path is not null
        and byte_size is not null and checksum is not null)
  ),
  constraint generated_assets_failed_has_reason check (
    status <> 'failed' or error_code is not null
  )
);

comment on table public.generated_assets is
  'MED-01 one row per distinct generation request: prompt provenance, provider, '
  'status, and the stored file. Written only by the MED-01 RPCs.';

comment on column public.generated_assets.slot is
  'Where the asset is used, for example a companion asset key. Part of the hash, '
  'so the same prompt for a different slot is a different asset.';

comment on column public.generated_assets.moderation is
  'Review outcome. MED-01 only records it as unreviewed; MED-05 owns transitions.';

-- Reuse key: asking for the same thing twice returns the first row. Failed rows
-- are excluded so a failure can be retried rather than blocking the slot.
create unique index if not exists generated_assets_reuse_idx
  on public.generated_assets (kind, prompt_hash)
  where status <> 'failed';

create index if not exists generated_assets_slot_idx
  on public.generated_assets (slot, locale, status);
create index if not exists generated_assets_status_idx
  on public.generated_assets (status, requested_at desc);

drop trigger if exists generated_assets_set_updated_at on public.generated_assets;
create trigger generated_assets_set_updated_at
  before update on public.generated_assets
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Attempts: provenance for retries and provider switches
-- ---------------------------------------------------------------------------
create table if not exists public.generation_attempts (
  id uuid primary key default gen_random_uuid(),
  asset_id uuid not null references public.generated_assets (id) on delete cascade,
  provider_id text not null references public.generation_providers (id),
  attempt_number integer not null check (attempt_number > 0),
  outcome text not null default 'started'
    check (outcome in ('started', 'succeeded', 'failed')),
  error_code text,
  error_message text,
  latency_ms integer check (latency_ms is null or latency_ms >= 0),
  cost_micros integer not null default 0 check (cost_micros >= 0),
  started_at timestamptz not null default timezone('utc', now()),
  finished_at timestamptz,
  constraint generation_attempts_unique unique (asset_id, attempt_number)
);

comment on table public.generation_attempts is
  'MED-01 one row per provider call: which adapter ran, how long it took, what it '
  'cost, and why it failed. Kept even when a later attempt succeeds.';

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------
alter table public.generation_providers enable row level security;
alter table public.generated_assets enable row level security;
alter table public.generation_attempts enable row level security;

drop policy if exists generation_providers_select on public.generation_providers;
create policy generation_providers_select on public.generation_providers
  for select to authenticated
  using (nano_internal.is_platform_admin());

drop policy if exists generated_assets_select on public.generated_assets;
create policy generated_assets_select on public.generated_assets
  for select to authenticated
  using (nano_internal.is_platform_admin());

drop policy if exists generation_attempts_select on public.generation_attempts;
create policy generation_attempts_select on public.generation_attempts
  for select to authenticated
  using (nano_internal.is_platform_admin());

-- Prompts, costs, and statuses are written by the RPCs below and by nothing else.
revoke insert, update, delete on public.generation_providers from authenticated;
revoke insert, update, delete on public.generated_assets from authenticated;
revoke insert, update, delete on public.generation_attempts from authenticated;

-- ---------------------------------------------------------------------------
-- Learner-facing projection
-- ---------------------------------------------------------------------------
-- The file and the identity of the slot; nothing about how it was made. This is
-- the only generated-asset surface a learner client may read.
-- Published companion assets are shared platform content, not tenant data, so
-- this projection intentionally runs with the view owner's rights (as
-- public.learner_quiz does) and carries only columns that are safe for everyone.
create or replace view public.generated_asset_catalog
with (security_invoker = false)
as
select
  ga.id,
  ga.kind,
  ga.slot,
  ga.locale,
  ga.aspect_ratio,
  ga.storage_bucket,
  ga.storage_path,
  ga.content_type,
  ga.byte_size,
  ga.checksum,
  ga.completed_at
from public.generated_assets ga
where ga.status = 'ready'
  and ga.moderation = 'approved';

comment on view public.generated_asset_catalog is
  'MED-01 published generated assets for clients: file identity only, no prompt, '
  'provider, or cost. Approval is MED-05, so this view is empty until then.';

grant select on public.generated_asset_catalog to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Hashing
-- ---------------------------------------------------------------------------
create or replace function nano_internal.normalize_generation_prompt(p_prompt text)
returns text
language sql
immutable
set search_path = pg_catalog, public
as $$
  select lower(regexp_replace(btrim(coalesce(p_prompt, '')), '\s+', ' ', 'g'));
$$;

revoke all on function nano_internal.normalize_generation_prompt(text)
  from public, anon;
grant execute on function nano_internal.normalize_generation_prompt(text)
  to authenticated, service_role;

-- Handbook 10.5: hash the script, the visual mode, the language, and the aspect
-- ratio, so an identical ask reuses an existing output.
create or replace function nano_internal.generated_asset_hash(
  p_kind public.generated_asset_kind,
  p_slot text,
  p_locale text,
  p_aspect_ratio text,
  p_prompt text,
  p_prompt_version text
)
returns text
language sql
immutable
set search_path = pg_catalog, public, nano_internal, extensions
as $$
  select encode(
    extensions.digest(
      concat_ws(
        '|',
        p_kind::text,
        lower(btrim(coalesce(p_slot, ''))),
        lower(btrim(coalesce(p_locale, ''))),
        btrim(coalesce(p_aspect_ratio, '')),
        btrim(coalesce(p_prompt_version, '')),
        nano_internal.normalize_generation_prompt(p_prompt)
      ),
      'sha256'
    ),
    'hex'
  );
$$;

revoke all on function nano_internal.generated_asset_hash(
  public.generated_asset_kind, text, text, text, text, text
) from public, anon;
grant execute on function nano_internal.generated_asset_hash(
  public.generated_asset_kind, text, text, text, text, text
) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Worker identity
-- ---------------------------------------------------------------------------
-- Results are recorded by the Edge Function holding the service role. A signed-in
-- person, superadmin included, cannot claim a job or declare a file ready.
create or replace function nano_internal.is_generation_worker()
returns boolean
language sql
stable
set search_path = pg_catalog, public
as $$
  select coalesce(auth.jwt() ->> 'role', '') = 'service_role';
$$;

revoke all on function nano_internal.is_generation_worker() from public, anon;
grant execute on function nano_internal.is_generation_worker()
  to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Row shape shared by every RPC return
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
    'completed_at', ga.completed_at
  )
  from public.generated_assets ga
  where ga.id = p_asset_id;
$$;

revoke all on function nano_internal.generated_asset_json(uuid) from public, anon;
grant execute on function nano_internal.generated_asset_json(uuid)
  to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Request: superadmin only, deduplicated by hash
-- ---------------------------------------------------------------------------
create or replace function public.request_generated_asset(
  p_kind public.generated_asset_kind,
  p_slot text,
  p_prompt text,
  p_prompt_version text,
  p_locale text default 'en',
  p_aspect_ratio text default '1:1',
  p_provider_id text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_provider public.generation_providers;
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

  v_hash := nano_internal.generated_asset_hash(
    p_kind, p_slot, p_locale, p_aspect_ratio, p_prompt, p_prompt_version
  );

  select * into v_existing
  from public.generated_assets
  where kind = p_kind and prompt_hash = v_hash and status <> 'failed';

  if v_existing.id is not null then
    return jsonb_build_object(
      'reused', true,
      'asset', nano_internal.generated_asset_json(v_existing.id)
    );
  end if;

  insert into public.generated_assets
    (kind, slot, locale, aspect_ratio, prompt, prompt_version, prompt_hash,
     provider_id, requested_by)
  values
    (p_kind, btrim(p_slot), p_locale, p_aspect_ratio, btrim(p_prompt),
     btrim(p_prompt_version), v_hash, v_provider.id, auth.uid())
  returning id into v_id;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'superadmin', 'create', 'generated_asset', v_id::text,
    jsonb_build_object(
      'kind', p_kind,
      'slot', p_slot,
      'locale', p_locale,
      'provider_id', v_provider.id,
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
  public.generated_asset_kind, text, text, text, text, text, text
) is
  'MED-01 superadmin request for a generated asset. Returns the existing row when '
  'the same ask already exists, so a provider is never paid twice for one output.';

revoke all on function public.request_generated_asset(
  public.generated_asset_kind, text, text, text, text, text, text
) from public, anon;
grant execute on function public.request_generated_asset(
  public.generated_asset_kind, text, text, text, text, text, text
) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Claim: single flight for the worker
-- ---------------------------------------------------------------------------
create or replace function public.claim_generated_asset(p_asset_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_asset public.generated_assets;
  v_attempt integer;
begin
  if not nano_internal.is_generation_worker() then
    raise exception using
      errcode = 'NM003',
      message = 'Only the generation worker can claim an asset.';
  end if;

  -- The status predicate is the lock: two workers cannot both win this update.
  update public.generated_assets
  set status = 'generating',
      claimed_at = timezone('utc', now()),
      attempts_count = attempts_count + 1,
      error_code = null,
      error_message = null
  where id = p_asset_id and status = 'requested'
  returning * into v_asset;

  if v_asset.id is null then
    raise exception using
      errcode = 'NM004',
      message = 'That asset is not waiting for generation.';
  end if;

  v_attempt := v_asset.attempts_count;

  insert into public.generation_attempts
    (asset_id, provider_id, attempt_number)
  values (v_asset.id, v_asset.provider_id, v_attempt);

  return jsonb_build_object(
    'attempt_number', v_attempt,
    'asset', nano_internal.generated_asset_json(v_asset.id)
  );
end;
$$;

comment on function public.claim_generated_asset(uuid) is
  'MED-01 worker claim. The status predicate makes it single flight, so a retried '
  'invocation cannot start a second provider call for the same asset.';

revoke all on function public.claim_generated_asset(uuid) from public, anon;
grant execute on function public.claim_generated_asset(uuid) to service_role;

-- ---------------------------------------------------------------------------
-- Result: worker only
-- ---------------------------------------------------------------------------
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
      provenance = coalesce(p_provenance, '{}'::jsonb),
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

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    null, 'service_role', 'update', 'generated_asset', v_asset.id::text,
    jsonb_build_object(
      'status', 'ready',
      'provider_id', v_asset.provider_id,
      'byte_size', p_byte_size,
      'checksum', p_checksum,
      'cost_micros', p_cost_micros
    )
  );

  return nano_internal.generated_asset_json(v_asset.id);
end;
$$;

comment on function public.record_generated_asset_result(
  uuid, text, text, text, bigint, text, text, integer, integer, text, jsonb
) is
  'MED-01 worker result. Marks the asset ready with its file identity and closes '
  'the open attempt. Approval for clients is a separate step (MED-05).';

revoke all on function public.record_generated_asset_result(
  uuid, text, text, text, bigint, text, text, integer, integer, text, jsonb
) from public, anon;
grant execute on function public.record_generated_asset_result(
  uuid, text, text, text, bigint, text, text, integer, integer, text, jsonb
) to service_role;

-- ---------------------------------------------------------------------------
-- Failure: worker only, and never fatal for a learner
-- ---------------------------------------------------------------------------
create or replace function public.record_generated_asset_failure(
  p_asset_id uuid,
  p_error_code text,
  p_error_message text default null,
  p_latency_ms integer default null
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
      message = 'Only the generation worker can record a failure.';
  end if;

  if coalesce(btrim(p_error_code), '') = '' then
    raise exception using
      errcode = 'NM005',
      message = 'A failure needs an error code.';
  end if;

  update public.generated_assets
  set status = 'failed',
      error_code = btrim(p_error_code),
      error_message = left(coalesce(p_error_message, ''), 500),
      completed_at = timezone('utc', now())
  where id = p_asset_id and status in ('requested', 'generating')
  returning * into v_asset;

  if v_asset.id is null then
    raise exception using
      errcode = 'NM004',
      message = 'That asset is not open for a result.';
  end if;

  update public.generation_attempts
  set outcome = 'failed',
      error_code = btrim(p_error_code),
      error_message = left(coalesce(p_error_message, ''), 500),
      latency_ms = p_latency_ms,
      finished_at = timezone('utc', now())
  where asset_id = v_asset.id and attempt_number = v_asset.attempts_count;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    null, 'service_role', 'update', 'generated_asset', v_asset.id::text,
    jsonb_build_object(
      'status', 'failed',
      'provider_id', v_asset.provider_id,
      'error_code', btrim(p_error_code)
    )
  );

  return nano_internal.generated_asset_json(v_asset.id);
end;
$$;

comment on function public.record_generated_asset_failure(uuid, text, text, integer) is
  'MED-01 worker failure. A failed row keeps its provenance and is excluded from '
  'the reuse index, so the same ask can be retried as a fresh row.';

revoke all on function public.record_generated_asset_failure(
  uuid, text, text, integer
) from public, anon;
grant execute on function public.record_generated_asset_failure(
  uuid, text, text, integer
) to service_role;

-- ---------------------------------------------------------------------------
-- Storage
-- ---------------------------------------------------------------------------
-- Private bucket: the worker writes with the service role, superadmins can read
-- for review, and learner delivery goes through signed URLs (MED-02).
insert into storage.buckets (id, name, public)
values ('generated-assets', 'generated-assets', false)
on conflict (id) do nothing;

drop policy if exists generated_assets_bucket_read on storage.objects;
create policy generated_assets_bucket_read on storage.objects
  for select to authenticated
  using (
    bucket_id = 'generated-assets' and nano_internal.is_platform_admin()
  );
