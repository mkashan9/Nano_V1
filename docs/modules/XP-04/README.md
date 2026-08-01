# XP-04 — Daily and Weekly Missions

## Purpose

Home still showed fixture missions with invented XP rewards. This module owns
server-defined daily and weekly missions, tracks progress per period, awards
bonus XP once through the ledger, and wires the Home plan to that list.

## Delivered

**`missions`** — catalog with cadence `daily` / `weekly`, bilingual titles,
rule (`topic_completions_in_period` / `quiz_passes_in_period`), target, and
`xp_bonus`.

**Seeded set** — daily lesson (+15), daily quiz (+20), weekly 3 lessons (+50),
weekly 2 quizzes (+40).

**`mission_progress`** — unique `(user_id, mission_id, period_key)`. UTC day
and ISO week keys.

**`evaluate_missions`** — runs after topic complete and quiz submit; completing
a period awards `mission_complete` XP once.

**`my_missions`** — Home prefers this when Supabase is wired. Completed items
show **Done** on Junior Home.

## Deferred

Admin editing (ADM-05). Streak missions (XP-05). Game missions (GME). Companion
celebration on mission complete.
