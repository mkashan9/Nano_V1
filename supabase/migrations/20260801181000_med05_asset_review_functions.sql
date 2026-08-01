-- MED-05: the publication decision itself.

-- ---------------------------------------------------------------------------
-- Applying one decision
-- ---------------------------------------------------------------------------
-- Returns true when something actually changed, so the caller can tell a real
-- decision apart from re-confirming one.
create or replace function nano_internal.apply_asset_review(
  p_asset_id uuid,
  p_decision public.generated_asset_moderation,
  p_note text
)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_asset public.generated_assets;
  v_note text := btrim(coalesce(p_note, ''));
  v_actor uuid := auth.uid();
begin
  select * into v_asset
  from public.generated_assets
  where id = p_asset_id
  for update;

  if v_asset.id is null then
    raise exception using
      errcode = 'NM010',
      message = 'That asset does not exist.';
  end if;

  -- Deciding the same thing twice is not an error, it just is not a decision.
  if v_asset.moderation = p_decision then
    return false;
  end if;

  -- Approving a filename is not review. A row is only publishable once the
  -- worker has actually stored bytes for it.
  if p_decision = 'approved' and v_asset.status <> 'ready' then
    raise exception using
      errcode = 'NM010',
      message = 'Only a ready asset can be approved.';
  end if;

  if p_decision = 'rejected' and v_note = '' then
    raise exception using
      errcode = 'NM010',
      message = 'A rejection needs a reason so the next attempt can be better.';
  end if;

  if length(v_note) > 2000 then
    raise exception using
      errcode = 'NM010',
      message = 'A review note is limited to 2000 characters.';
  end if;

  insert into public.asset_review_events
    (asset_id, reviewer_id, previous_moderation, decision, note)
  values
    (v_asset.id, v_actor, v_asset.moderation, p_decision, v_note);

  begin
    update public.generated_assets
    set moderation = p_decision,
        reviewed_by = v_actor,
        reviewed_at = timezone('utc', now()),
        review_note = nullif(v_note, '')
    where id = v_asset.id;
  exception when unique_violation then
    -- Un-rejecting collides with the replacement that the rejection allowed to
    -- be generated. Two live rows cannot share one ask, and the reviewer is
    -- better told which way out they have than shown a constraint name.
    raise exception using
      errcode = 'NM010',
      message = 'A newer asset already fills this slot. Reject that one first.';
  end;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id,
     previous_value, new_value, reason)
  values
    (
      v_actor,
      'superadmin',
      'update',
      'generated_asset',
      v_asset.id::text,
      jsonb_build_object('moderation', v_asset.moderation),
      jsonb_build_object(
        'moderation', p_decision,
        'kind', v_asset.kind,
        'slot', v_asset.slot,
        'locale', v_asset.locale
      ),
      nullif(v_note, '')
    );

  return true;
end;
$$;

revoke all on function nano_internal.apply_asset_review(
  uuid, public.generated_asset_moderation, text
) from public, anon;

-- ---------------------------------------------------------------------------
-- Deciding, in one round trip
-- ---------------------------------------------------------------------------
-- A review session is a queue, not a single asset, so the batch is the real
-- entry point and the singular form below just wraps it. All-or-nothing: a
-- batch that trips over one bad id leaves nothing half-published.
create or replace function public.review_generated_assets(
  p_asset_ids uuid[],
  p_decision text,
  p_note text default ''
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_decision public.generated_asset_moderation;
  v_ids uuid[];
  v_id uuid;
  v_changed integer := 0;
  v_unchanged integer := 0;
  v_assets jsonb := '[]'::jsonb;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NM010',
      message = 'Only platform admins can review generated assets.';
  end if;

  begin
    v_decision := lower(btrim(coalesce(p_decision, '')))::public.generated_asset_moderation;
  exception when invalid_text_representation then
    raise exception using
      errcode = 'NM010',
      message = 'A decision is approved, rejected, or unreviewed.';
  end;

  select array_agg(distinct id) into v_ids
  from unnest(coalesce(p_asset_ids, array[]::uuid[])) as id
  where id is not null;

  if v_ids is null or cardinality(v_ids) = 0 then
    raise exception using
      errcode = 'NM010',
      message = 'Name at least one asset to review.';
  end if;

  if cardinality(v_ids) > 200 then
    raise exception using
      errcode = 'NM010',
      message = 'Review at most 200 assets at a time.';
  end if;

  foreach v_id in array v_ids loop
    if nano_internal.apply_asset_review(v_id, v_decision, p_note) then
      v_changed := v_changed + 1;
    else
      v_unchanged := v_unchanged + 1;
    end if;
    v_assets := v_assets || jsonb_build_array(
      nano_internal.generated_asset_json(v_id)
    );
  end loop;

  return jsonb_build_object(
    'decision', v_decision,
    'reviewed', v_changed,
    'unchanged', v_unchanged,
    'assets', v_assets
  );
end;
$$;

comment on function public.review_generated_assets(uuid[], text, text) is
  'MED-05 the publication decision. Superadmin only, all-or-nothing, and the '
  'only way an asset becomes visible to a learner.';

revoke all on function public.review_generated_assets(uuid[], text, text)
  from public, anon;
grant execute on function public.review_generated_assets(uuid[], text, text)
  to authenticated, service_role;

create or replace function public.review_generated_asset(
  p_asset_id uuid,
  p_decision text,
  p_note text default ''
)
returns jsonb
language sql
set search_path = pg_catalog, public, nano_internal
as $$
  select public.review_generated_assets(array[p_asset_id], p_decision, p_note);
$$;

comment on function public.review_generated_asset(uuid, text, text) is
  'MED-05 convenience wrapper over review_generated_assets for a single asset.';

revoke all on function public.review_generated_asset(uuid, text, text)
  from public, anon;
grant execute on function public.review_generated_asset(uuid, text, text)
  to authenticated, service_role;
