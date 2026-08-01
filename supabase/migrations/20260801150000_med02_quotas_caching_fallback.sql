-- MED-02: generation budgets, cached delivery, and the fallback contract.
--
-- MED-01 made a repeat request free. This module makes a *new* request finite:
-- every ask is counted against a per-day budget for the platform, for the feature
-- that asked, and for the school it was asked on behalf of, and the request is
-- refused before a provider is reached rather than after the money is spent.
--
-- Two properties are worth stating because they are easy to get backwards:
--
--   * A reused ask consumes no budget. Deduplication happens before the quota
--     check, so a caching client that asks again is not punished for asking.
--   * Cost is counted when it is known, not when it is guessed. The request adds
--     one to a request counter; the worker's result adds the real cost.
--
-- Delivery: an approved asset's file becomes readable by any signed-in client, so
-- the client can mint its own signed URL and let the CDN cache it. Unapproved and
-- failed files stay admin-only, which is the same gate the catalog uses.

-- ---------------------------------------------------------------------------
-- What a request was for
-- ---------------------------------------------------------------------------
-- The feature and the school are budget dimensions, not identity: they are
-- deliberately outside the reuse hash, so two features asking for the same
-- picture still share one file and pay once.
alter table public.generated_assets
  add column if not exists feature text not null default 'companion';

alter table public.generated_assets
  add column if not exists school_id uuid references public.schools (id);

comment on column public.generated_assets.feature is
  'MED-02 which part of the product asked, for per-feature budgets. Outside the '
  'reuse hash on purpose: two features asking for one output still pay once.';

comment on column public.generated_assets.school_id is
  'MED-02 the school a request was made on behalf of, or null for platform-wide '
  'assets. Used for per-school budgets, not for access control.';

create index if not exists generated_assets_feature_idx
  on public.generated_assets (feature, requested_at desc);

-- ---------------------------------------------------------------------------
-- Budgets
-- ---------------------------------------------------------------------------
do $$ begin
  create type public.generation_quota_scope as enum (
    'platform',
    'feature',
    'school'
  );
exception when duplicate_object then null;
end $$;

create table if not exists public.generation_quotas (
  id uuid primary key default gen_random_uuid(),
  scope public.generation_quota_scope not null,
  -- Empty for the platform scope, the feature name, or the school id as text.
  scope_key text not null default '',
  -- Null means the budget covers every kind together.
  kind public.generated_asset_kind,
  max_requests_per_day integer not null default 0
    check (max_requests_per_day >= 0),
  max_cost_micros_per_day bigint not null default 0
    check (max_cost_micros_per_day >= 0),
  is_enabled boolean not null default true,
  notes text not null default '',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.generation_quotas is
  'MED-02 per-day generation budgets by scope. A zero limit means blocked, which '
  'is how a kind or a feature is switched off without a deploy.';

-- One row per scope, key, and kind. `nulls not distinct` is what makes the
-- "every kind" row a slot of its own rather than an unlimited number of them.
create unique index if not exists generation_quotas_unique_idx
  on public.generation_quotas (scope, scope_key, kind) nulls not distinct;

drop trigger if exists generation_quotas_set_updated_at on public.generation_quotas;
create trigger generation_quotas_set_updated_at
  before update on public.generation_quotas
  for each row execute function public.set_updated_at();

-- Deliberately conservative: generation is an administration workflow, so these
-- are curator-sized numbers, not traffic-sized ones.
insert into public.generation_quotas
  (scope, scope_key, kind, max_requests_per_day, max_cost_micros_per_day, notes)
values
  ('platform', '', null, 200, 5000000, 'Whole platform, every kind, per day.'),
  ('platform', '', 'video', 20, 3000000, 'Clips are the expensive kind.'),
  ('platform', '', 'voice', 100, 1500000, 'Narration lines per day.'),
  ('feature', 'companion', null, 120, 3000000, 'Companion art and clips.')
on conflict do nothing;

create table if not exists public.generation_usage (
  usage_date date not null default (timezone('utc', now()))::date,
  scope public.generation_quota_scope not null,
  scope_key text not null default '',
  kind public.generated_asset_kind not null,
  requests_count integer not null default 0 check (requests_count >= 0),
  cost_micros bigint not null default 0 check (cost_micros >= 0),
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (usage_date, scope, scope_key, kind)
);

comment on table public.generation_usage is
  'MED-02 what has been spent today, per scope and kind. Requests are counted when '
  'a new asset is created; cost is added when the worker reports the real figure.';

alter table public.generation_quotas enable row level security;
alter table public.generation_usage enable row level security;

drop policy if exists generation_quotas_select on public.generation_quotas;
create policy generation_quotas_select on public.generation_quotas
  for select to authenticated
  using (nano_internal.is_platform_admin());

drop policy if exists generation_usage_select on public.generation_usage;
create policy generation_usage_select on public.generation_usage
  for select to authenticated
  using (nano_internal.is_platform_admin());

revoke insert, update, delete on public.generation_quotas from authenticated;
revoke insert, update, delete on public.generation_usage from authenticated;

-- ---------------------------------------------------------------------------
-- Which budgets apply to one request
-- ---------------------------------------------------------------------------
create or replace function nano_internal.generation_scopes(
  p_feature text,
  p_school_id uuid
)
returns table (scope public.generation_quota_scope, scope_key text)
language sql
immutable
set search_path = pg_catalog, public
as $$
  select 'platform'::public.generation_quota_scope, ''
  union all
  select 'feature'::public.generation_quota_scope,
         lower(btrim(coalesce(p_feature, 'companion')))
  union all
  select 'school'::public.generation_quota_scope, p_school_id::text
  where p_school_id is not null;
$$;

revoke all on function nano_internal.generation_scopes(text, uuid)
  from public, anon;
grant execute on function nano_internal.generation_scopes(text, uuid)
  to authenticated, service_role;

-- Refuse before a provider is reached. The message names the scope that ran out,
-- because "try again tomorrow" is useless without knowing which budget is spent.
create or replace function nano_internal.assert_generation_quota(
  p_kind public.generated_asset_kind,
  p_feature text,
  p_school_id uuid
)
returns void
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_row record;
begin
  for v_row in
    select
      q.scope,
      q.scope_key,
      q.kind,
      q.max_requests_per_day,
      q.max_cost_micros_per_day,
      coalesce(u.requests, 0) as requests,
      coalesce(u.cost_micros, 0) as cost_micros
    from nano_internal.generation_scopes(p_feature, p_school_id) s
    join public.generation_quotas q
      on q.scope = s.scope
     and q.scope_key = s.scope_key
     and q.is_enabled
     and (q.kind is null or q.kind = p_kind)
    left join lateral (
      select
        sum(gu.requests_count) as requests,
        sum(gu.cost_micros) as cost_micros
      from public.generation_usage gu
      where gu.usage_date = (timezone('utc', now()))::date
        and gu.scope = q.scope
        and gu.scope_key = q.scope_key
        and (q.kind is null or gu.kind = q.kind)
    ) u on true
  loop
    if v_row.requests >= v_row.max_requests_per_day then
      raise exception using
        errcode = 'NM006',
        message = format(
          'Daily generation limit reached for %s budget %s.',
          v_row.scope,
          case when v_row.scope_key = '' then 'all' else v_row.scope_key end
        );
    end if;
    if v_row.cost_micros >= v_row.max_cost_micros_per_day then
      raise exception using
        errcode = 'NM006',
        message = format(
          'Daily generation cost limit reached for %s budget %s.',
          v_row.scope,
          case when v_row.scope_key = '' then 'all' else v_row.scope_key end
        );
    end if;
  end loop;
end;
$$;

revoke all on function nano_internal.assert_generation_quota(
  public.generated_asset_kind, text, uuid
) from public, anon;
grant execute on function nano_internal.assert_generation_quota(
  public.generated_asset_kind, text, uuid
) to authenticated, service_role;

create or replace function nano_internal.record_generation_usage(
  p_kind public.generated_asset_kind,
  p_feature text,
  p_school_id uuid,
  p_requests integer,
  p_cost_micros bigint
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
begin
  insert into public.generation_usage
    (usage_date, scope, scope_key, kind, requests_count, cost_micros)
  select
    (timezone('utc', now()))::date,
    s.scope,
    s.scope_key,
    p_kind,
    greatest(coalesce(p_requests, 0), 0),
    greatest(coalesce(p_cost_micros, 0), 0)
  from nano_internal.generation_scopes(p_feature, p_school_id) s
  on conflict (usage_date, scope, scope_key, kind) do update
  set requests_count =
        generation_usage.requests_count + greatest(coalesce(p_requests, 0), 0),
      cost_micros =
        generation_usage.cost_micros + greatest(coalesce(p_cost_micros, 0), 0),
      updated_at = timezone('utc', now());
end;
$$;

revoke all on function nano_internal.record_generation_usage(
  public.generated_asset_kind, text, uuid, integer, bigint
) from public, anon;
grant execute on function nano_internal.record_generation_usage(
  public.generated_asset_kind, text, uuid, integer, bigint
) to authenticated, service_role;

-- What a curator needs to see before asking for more work.
create or replace function public.generation_budget_status()
returns table (
  scope public.generation_quota_scope,
  scope_key text,
  kind text,
  max_requests_per_day integer,
  requests_used integer,
  max_cost_micros_per_day bigint,
  cost_micros_used bigint
)
language sql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
  select
    q.scope,
    q.scope_key,
    coalesce(q.kind::text, 'all') as kind,
    q.max_requests_per_day,
    coalesce(u.requests, 0)::integer as requests_used,
    q.max_cost_micros_per_day,
    coalesce(u.cost_micros, 0)::bigint as cost_micros_used
  from public.generation_quotas q
  left join lateral (
    select
      sum(gu.requests_count) as requests,
      sum(gu.cost_micros) as cost_micros
    from public.generation_usage gu
    where gu.usage_date = (timezone('utc', now()))::date
      and gu.scope = q.scope
      and gu.scope_key = q.scope_key
      and (q.kind is null or gu.kind = q.kind)
  ) u on true
  where nano_internal.is_platform_admin()
    and q.is_enabled
  order by q.scope, q.scope_key, coalesce(q.kind::text, 'all');
$$;

comment on function public.generation_budget_status() is
  'MED-02 today''s budget and spend per scope, for platform admins. Returns no rows '
  'for anyone else rather than raising, so a dashboard degrades quietly.';

revoke all on function public.generation_budget_status() from public, anon;
grant execute on function public.generation_budget_status()
  to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Request, now budgeted
-- ---------------------------------------------------------------------------
drop function if exists public.request_generated_asset(
  public.generated_asset_kind, text, text, text, text, text, text
);

create or replace function public.request_generated_asset(
  p_kind public.generated_asset_kind,
  p_slot text,
  p_prompt text,
  p_prompt_version text,
  p_locale text default 'en',
  p_aspect_ratio text default '1:1',
  p_provider_id text default null,
  p_feature text default 'companion',
  p_school_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_provider public.generation_providers;
  v_feature text := lower(btrim(coalesce(p_feature, 'companion')));
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

  -- Reuse is checked before the budget: an ask that costs nothing must never be
  -- refused for being over a limit, or a caching client would be worse off than
  -- one that never looked.
  select * into v_existing
  from public.generated_assets
  where kind = p_kind and prompt_hash = v_hash and status <> 'failed';

  if v_existing.id is not null then
    return jsonb_build_object(
      'reused', true,
      'asset', nano_internal.generated_asset_json(v_existing.id)
    );
  end if;

  perform nano_internal.assert_generation_quota(p_kind, v_feature, p_school_id);

  insert into public.generated_assets
    (kind, slot, locale, aspect_ratio, prompt, prompt_version, prompt_hash,
     provider_id, requested_by, feature, school_id)
  values
    (p_kind, btrim(p_slot), p_locale, p_aspect_ratio, btrim(p_prompt),
     btrim(p_prompt_version), v_hash, v_provider.id, auth.uid(),
     v_feature, p_school_id)
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
      'feature', v_feature,
      'school_id', p_school_id,
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
  public.generated_asset_kind, text, text, text, text, text, text, text, uuid
) is
  'MED-01/MED-02 superadmin request. Returns an existing output when the ask has '
  'been answered before, and otherwise charges the platform, feature, and school '
  'budgets before creating the row.';

revoke all on function public.request_generated_asset(
  public.generated_asset_kind, text, text, text, text, text, text, text, uuid
) from public, anon;
grant execute on function public.request_generated_asset(
  public.generated_asset_kind, text, text, text, text, text, text, text, uuid
) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Result, now charged
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

  -- The real figure, charged once the provider has answered. The refused-second-
  -- result path above means a duplicated callback cannot charge twice either.
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

-- ---------------------------------------------------------------------------
-- Cached delivery
-- ---------------------------------------------------------------------------
-- The bucket is private and the assets table is admin-only, so a policy on
-- storage.objects cannot check publication as the caller: it would see no rows.
-- This definer helper answers the one question the policy needs.
create or replace function nano_internal.asset_object_is_published(p_name text)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
  select exists (
    select 1
    from public.generated_assets ga
    where ga.storage_path = p_name
      and ga.storage_bucket = 'generated-assets'
      and ga.status = 'ready'
      and ga.moderation = 'approved'
  );
$$;

revoke all on function nano_internal.asset_object_is_published(text)
  from public, anon;
grant execute on function nano_internal.asset_object_is_published(text)
  to authenticated, service_role;

-- Published files are readable by any signed-in client, which is what lets a
-- client mint its own signed URL and let the CDN keep the bytes. Everything else
-- in the bucket stays admin-only.
drop policy if exists generated_assets_bucket_read_published on storage.objects;
create policy generated_assets_bucket_read_published on storage.objects
  for select to authenticated
  using (
    bucket_id = 'generated-assets'
    and nano_internal.asset_object_is_published(name)
  );
