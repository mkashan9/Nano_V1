# XP-02 — Levels and Thresholds

## Purpose

XP-01 made the ledger the only place XP can come from, but Home and Me still
turned that total into a level with a hard-coded 250 XP step on the client.
This module moves the curve to the server so a threshold change does not need
an app release, and so "ledger totals reconcile to profile level" is a real
check rather than a hope.

## Delivered

**`public.level_rules`** — cumulative `min_xp` per level. Seeded flat at 250
XP through level 40; the table shape already allows a non-linear curve.

**`public.xp_progress`** — per-learner projection of total XP and derived
level. Refreshed inside `nano_internal.award_xp` after every new ledger row.

**`my_xp_balance`** — now returns `level`, `xp_into_level`, `xp_to_next`,
`xp_per_level`, and a `reconciled` flag that compares the cache to a fresh
derivation from the ledger sum.

**Client** — `XpBalance` carries the server level; Home and Me prefer
`levelProgress` from the balance when a ledger is wired. `LevelProgress.fromXp`
stays as the fixture/offline fallback and still matches the seeded curve.

## Deferred

Editing thresholds in admin (ADM-05). Achievements and stickers (XP-03).
Level-up companion celebration triggers beyond the existing CMP-02 mode.
Missions and streaks (XP-04 / XP-05).
