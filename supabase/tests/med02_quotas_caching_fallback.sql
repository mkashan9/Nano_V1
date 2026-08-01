-- MED-02 adversarial checks: what a budget refuses, what it does not charge for,
-- and who can see the spend.
--
-- Every block rolls back, including the quota rows it rewrites, so the
-- development project keeps its seeded budgets.

-- ---------------------------------------------------------------------------
-- A reused ask is free, and a new one is counted
-- ---------------------------------------------------------------------------
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $$
declare
  v_first jsonb;
  v_second jsonb;
  v_used integer;
begin
  v_first := public.request_generated_asset(
    'image', 'guide_greeting_staticArt', 'A friendly round companion', 'v1'
  );
  if (v_first->>'reused')::boolean then
    raise exception 'FAIL: first ask reported reuse';
  end if;

  select requests_count into v_used
  from public.generation_usage
  where scope = 'platform' and scope_key = '' and kind = 'image'
    and usage_date = (timezone('utc', now()))::date;
  if coalesce(v_used, 0) <> 1 then
    raise exception 'FAIL: a new ask was not counted (%)', v_used;
  end if;

  -- The same ask again: no provider, no charge.
  v_second := public.request_generated_asset(
    'image', 'guide_greeting_staticArt', '  a FRIENDLY round   companion ', 'v1'
  );
  if not (v_second->>'reused')::boolean then
    raise exception 'FAIL: identical ask was not reused';
  end if;

  select requests_count into v_used
  from public.generation_usage
  where scope = 'platform' and scope_key = '' and kind = 'image'
    and usage_date = (timezone('utc', now()))::date;
  if v_used <> 1 then
    raise exception 'FAIL: a reused ask consumed budget (%)', v_used;
  end if;

  -- Feature budgets are counted alongside the platform one.
  select requests_count into v_used
  from public.generation_usage
  where scope = 'feature' and scope_key = 'companion' and kind = 'image'
    and usage_date = (timezone('utc', now()))::date;
  if coalesce(v_used, 0) <> 1 then
    raise exception 'FAIL: feature budget not charged (%)', v_used;
  end if;
end $$;
select 'reuse_is_free_and_new_is_counted' as check, true as ok;
rollback;

-- ---------------------------------------------------------------------------
-- A spent budget refuses before a provider is reached
-- ---------------------------------------------------------------------------
begin;
-- Budgets are changed before the role switch on purpose: `authenticated` has no
-- write grant on them at all, which the last block in this file asserts.
update public.generation_quotas
set max_requests_per_day = 0
where scope = 'platform' and scope_key = '' and kind = 'video';

set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $$
declare
  v_message text;
begin
  begin
    perform public.request_generated_asset(
      'video', 'celebration_celebration_shortClip', 'a short celebration', 'v1',
      'en', '16:9'
    );
    raise exception 'FAIL: a blocked kind was generated';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
    if sqlstate <> 'NM006' then
      raise exception 'FAIL: unexpected refusal % %', sqlstate, sqlerrm;
    end if;
    v_message := sqlerrm;
  end;

  -- The message says which budget ran out, not just that something did.
  if v_message not like '%platform%' then
    raise exception 'FAIL: refusal does not name the budget: %', v_message;
  end if;

  -- Nothing was created, so nothing can be claimed later.
  if exists (select 1 from public.generated_assets where kind = 'video') then
    raise exception 'FAIL: a refused request still created a row';
  end if;

  -- Another kind is unaffected: one spent budget is not an outage.
  if (public.request_generated_asset(
        'image', 'other_slot', 'a companion pointing', 'v1'
      )->>'reused')::boolean then
    raise exception 'FAIL: unrelated kind was refused or reused';
  end if;
end $$;
select 'spent_budget_refuses_before_provider' as check, true as ok;
rollback;

-- ---------------------------------------------------------------------------
-- A feature budget stops that feature only
-- ---------------------------------------------------------------------------
begin;
update public.generation_quotas
set max_requests_per_day = 0
where scope = 'feature' and scope_key = 'companion';

set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $$
begin
  begin
    perform public.request_generated_asset(
      'image', 'guide_point_staticArt', 'a companion pointing', 'v1',
      'en', '1:1', null, 'companion'
    );
    raise exception 'FAIL: blocked feature generated anyway';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
    if sqlstate <> 'NM006' then
      raise exception 'FAIL: unexpected feature refusal %', sqlstate;
    end if;
  end;

  -- A feature with no budget row of its own falls back to the platform budget.
  if (public.request_generated_asset(
        'image', 'onboarding_hero', 'a welcome illustration', 'v1',
        'en', '16:9', null, 'onboarding'
      )->>'reused')::boolean then
    raise exception 'FAIL: unbudgeted feature was refused';
  end if;
end $$;
select 'feature_budget_is_scoped' as check, true as ok;
rollback;

-- ---------------------------------------------------------------------------
-- Cost is charged when it is known, and only once
-- ---------------------------------------------------------------------------
begin;
set local role service_role;
set local request.jwt.claims = '{"role":"service_role"}';

do $$
declare
  v_id uuid;
  v_cost bigint;
begin
  insert into public.generated_assets
    (kind, slot, locale, aspect_ratio, prompt, prompt_version, prompt_hash,
     provider_id, feature)
  values
    ('image', 'cost_slot', 'en', '1:1', 'a companion', 'v1',
     nano_internal.generated_asset_hash(
       'image', 'cost_slot', 'en', '1:1', 'a companion', 'v1'
     ),
     'pollinations_image', 'companion')
  returning id into v_id;

  perform public.claim_generated_asset(v_id);
  perform public.record_generated_asset_result(
    v_id, 'generated-assets', 'image/cost_slot.png', 'image/png',
    2048, 'sha256:abc', null, 2500, 120
  );

  select cost_micros into v_cost
  from public.generation_usage
  where scope = 'platform' and scope_key = '' and kind = 'image'
    and usage_date = (timezone('utc', now()))::date;
  if coalesce(v_cost, 0) <> 2500 then
    raise exception 'FAIL: real cost not charged (%)', v_cost;
  end if;

  -- A duplicated provider callback is refused, so it cannot charge twice.
  begin
    perform public.record_generated_asset_result(
      v_id, 'generated-assets', 'image/cost_slot.png', 'image/png',
      2048, 'sha256:abc', null, 2500, 120
    );
    raise exception 'FAIL: result recorded twice';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
    if sqlstate <> 'NM004' then
      raise exception 'FAIL: unexpected second-result error %', sqlstate;
    end if;
  end;

  select cost_micros into v_cost
  from public.generation_usage
  where scope = 'platform' and scope_key = '' and kind = 'image'
    and usage_date = (timezone('utc', now()))::date;
  if v_cost <> 2500 then
    raise exception 'FAIL: duplicated callback charged again (%)', v_cost;
  end if;
end $$;
select 'cost_charged_once_when_known' as check, true as ok;
rollback;

-- ---------------------------------------------------------------------------
-- Cached delivery: an approved file is readable, an unapproved one is not
-- ---------------------------------------------------------------------------
begin;
set local role service_role;
set local request.jwt.claims = '{"role":"service_role"}';

insert into public.generated_assets
  (kind, slot, locale, aspect_ratio, prompt, prompt_version, prompt_hash,
   provider_id, status, moderation, storage_bucket, storage_path, content_type,
   byte_size, checksum, completed_at)
values
  ('image', 'published_slot', 'en', '1:1', 'a companion', 'v1',
   nano_internal.generated_asset_hash(
     'image', 'published_slot', 'en', '1:1', 'a companion', 'v1'
   ),
   'pollinations_image', 'ready', 'approved', 'generated-assets',
   'image/published_slot/en/hash.png', 'image/png', 2048, 'sha256:ok',
   timezone('utc', now())),
  ('image', 'draft_slot', 'en', '1:1', 'a companion drafting', 'v1',
   nano_internal.generated_asset_hash(
     'image', 'draft_slot', 'en', '1:1', 'a companion drafting', 'v1'
   ),
   'pollinations_image', 'ready', 'unreviewed', 'generated-assets',
   'image/draft_slot/en/hash.png', 'image/png', 2048, 'sha256:draft',
   timezone('utc', now()));

set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

select 'published_file_is_readable' as check,
  nano_internal.asset_object_is_published('image/published_slot/en/hash.png')
    as ok;
select 'unapproved_file_is_not_readable' as check,
  not nano_internal.asset_object_is_published('image/draft_slot/en/hash.png')
    as ok;
select 'unknown_file_is_not_readable' as check,
  not nano_internal.asset_object_is_published('image/nothing.png') as ok;

-- The catalog and the bucket agree: one approved row, one readable file.
select 'learner_reads_only_approved_via_function' as check,
  (select count(*) from public.list_generated_assets()) = 1 as ok;
rollback;

-- ---------------------------------------------------------------------------
-- Budget visibility is admin-only, and quiet for everyone else
-- ---------------------------------------------------------------------------
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';
select 'learner_sees_no_budgets' as check,
  (select count(*) from public.generation_budget_status()) = 0
  and (select count(*) from public.generation_quotas) = 0
  and (select count(*) from public.generation_usage) = 0 as ok;

-- Nobody signed in may edit a budget, superadmin included: today that is a
-- migration or the service role, and MED-05 owns the eventual curator screen.
select 'nobody_signed_in_can_edit_budgets' as check,
  not has_table_privilege('authenticated', 'public.generation_quotas', 'update')
  and not has_table_privilege('authenticated', 'public.generation_usage', 'insert')
    as ok;
rollback;

begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';
select 'admin_sees_budgets' as check,
  (select count(*) from public.generation_budget_status()) >= 4 as ok;
rollback;

-- ---------------------------------------------------------------------------
-- Nothing above left anything behind
-- ---------------------------------------------------------------------------
select 'no_test_rows_remain' as check,
  (select count(*) from public.generated_assets) = 0
  and (select count(*) from public.generation_usage) = 0
  and (select count(*) from public.generation_quotas) = 4 as ok;
