# ADM-05 decisions

## Reuse XP catalogs

No second award engine. Writes go through SECURITY DEFINER RPCs over existing
XP-01..XP-04 tables.

## Flat level curve

`set_level_step` regenerates levels 1–40 and refreshes `xp_progress` for users
with ledger rows.

## Manual adjust requires reason

`admin_adjust_xp` wraps XP-01 `adjust_xp` and rejects empty reasons.
