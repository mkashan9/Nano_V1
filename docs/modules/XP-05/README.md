# XP-05 — Streaks and Gentle Motivation

## Purpose

Home and Me still showed a fixture seven-day streak. This module owns
consecutive learning days from trusted events, keeps the count server-side, and
uses gentle welcome-back copy when a streak pauses — never shame.

## Delivered

**`streaks`** — per-learner `current_count`, `longest_count`, `last_active_on`
(UTC date), and a one-shot `pending_notice`.

**`touch_streak`** — called from topic complete and quiz pass. Same UTC day
does not double-count; yesterday extends; a gap restarts at 1 with
`welcome_back`.

**`my_streak`** — soft-pauses a stale streak on read, returns status and gentle
bilingual copy, then clears the notice so it fires once.

**Home / Me** — prefer the live count when wired. Home can show
`HomeNoticeKind.streakGentle` with CMP-02-aligned calm wording.

## Deferred

Streak freezes / repair. Streak achievements. Companion auto-fire on notice
(Home banner is enough for this module).
