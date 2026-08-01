# XP-02 decisions

## Thresholds are a table, not a constant

A single `xp_per_level` column would have been enough for the flat seed, but
the handbook names `level_rules` and ADM-05 will reshape the curve. Cumulative
`min_xp` per level lets a later non-linear schedule land without changing the
RPC contract Home already reads.

## Projection, not recomputation on every paint

`xp_progress` is refreshed inside `award_xp` so the expensive join of "sum the
ledger, find the band" runs when XP changes, not when Home opens. `my_xp_balance`
still re-derives when the cache is missing or drifts, so a backfill gap cannot
silently show the wrong level.

## Client derivation stays as fallback only

Fixtures and offline demos still call `LevelProgress.fromXp`. Live Home and Me
prefer the server fields. That keeps STU-04's UI untouched while closing the
"client invents the curve" hole XP-01 left open.
