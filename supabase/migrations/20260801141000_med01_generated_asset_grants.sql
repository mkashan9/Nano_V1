-- MED-01 follow-up: close the two doors the linter found.
--
-- 1. Supabase default privileges grant EXECUTE on new public functions to
--    `authenticated`, so revoking from `public` and `anon` was not enough: the
--    worker-only RPCs were reachable (though refused) by any signed-in caller.
--    They are now unreachable as well as refused.
-- 2. The learner projection ran with the view owner's rights, which the database
--    linter flags as a security-definer view. The view now inherits the caller's
--    RLS, and clients read published assets through one security-definer function
--    instead — so the base table stays admin-only and a prompt still cannot leak.

revoke all on function public.claim_generated_asset(uuid)
  from anon, authenticated;

revoke all on function public.record_generated_asset_result(
  uuid, text, text, text, bigint, text, text, integer, integer, text, jsonb
) from anon, authenticated;

revoke all on function public.record_generated_asset_failure(
  uuid, text, text, integer
) from anon, authenticated;

-- The projection now enforces the caller's RLS, so it shows an admin their rows
-- and a learner nothing at all.
create or replace view public.generated_asset_catalog
with (security_invoker = true)
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
  'MED-01 published generated assets: file identity only, no prompt, provider, or '
  'cost. Caller RLS applies, so clients read it through list_generated_assets.';

-- One read path for clients: published assets only, projected columns only.
create or replace function public.list_generated_assets(
  p_kind public.generated_asset_kind default null,
  p_locale text default null,
  p_slot text default null
)
returns setof public.generated_asset_catalog
language sql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
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
    and ga.moderation = 'approved'
    and (p_kind is null or ga.kind = p_kind)
    and (p_locale is null or ga.locale = p_locale)
    and (p_slot is null or ga.slot = p_slot)
  order by ga.slot, ga.locale;
$$;

comment on function public.list_generated_assets(
  public.generated_asset_kind, text, text
) is
  'MED-01 client read side: ready and approved assets, file identity only. The '
  'underlying table stays admin-only, so provenance and cost cannot leak here.';

revoke all on function public.list_generated_assets(
  public.generated_asset_kind, text, text
) from public, anon;
grant execute on function public.list_generated_assets(
  public.generated_asset_kind, text, text
) to authenticated, service_role;
