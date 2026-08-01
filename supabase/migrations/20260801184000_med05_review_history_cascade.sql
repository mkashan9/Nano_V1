-- MED-05 follow-up: the append-only guard was also blocking the cascade.
--
-- `asset_review_events.asset_id` is declared `on delete cascade`, but the
-- BEFORE DELETE guard fired for the cascade too, so the first decision made
-- about an asset permanently pinned that asset in the table. Nothing in Nano
-- deletes generated assets today, but "this row can never be removed, and the
-- error says the history is append-only" is not a rule anybody chose.
--
-- The rule that matters is that a decision cannot be revised or erased while
-- the asset it describes still exists, and that the durable record survives
-- regardless -- which it does, in audit_events, where the review path writes an
-- entry this trigger cannot reach. Removing the asset takes its per-asset
-- detail with it, exactly as the foreign key already says.

create or replace function nano_internal.asset_review_events_are_final()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
begin
  -- A cascade reaches this table from the referential-integrity trigger on
  -- generated_assets, so it always runs nested. A reviewer trying to rewrite
  -- history issues a statement directly, at depth one, and is refused.
  if tg_op = 'DELETE' and pg_trigger_depth() > 1 then
    return old;
  end if;

  raise exception using
    errcode = 'NM010',
    message = 'Review history is append-only.';
end;
$$;
