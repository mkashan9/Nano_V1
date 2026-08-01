# XP-01 — Trusted XP Ledger

## Purpose

Video completion and quiz scoring were trusted events with no credit attached.
Home and Me showed a fixture 560 XP. This module is the append-only ledger and
the only path that can award XP.

## Delivered

**`public.xp_ledger`** — append-only, unique `(user_id, source_kind, source_id)`,
learners read their own rows, nobody inserts except `nano_internal.award_xp`.

**Amounts in `xp_award_rules`** — video completion 10, first quiz pass 30,
failed quiz 0. Daily cap 200. Numbers change without a client release.

**Hooks** — `complete_topic` and `submit_quiz_attempt` award inside the same
transaction as the source event. Replay is free: the unique key returns the
existing row.

**Reads** — `my_xp_balance` / `my_xp_ledger`. Home and Me take the ledger total
when a live `XpLedgerRepository` is wired (development with Supabase).

**Manual adjust** — `adjust_xp` for platform admins only, requires a reason,
audited.

## Deferred

Levels (XP-02), achievements (XP-03), missions (XP-04), streaks (XP-05),
game XP (GME-05). Level display stays `LevelProgress.fromXp` at 250/level.
