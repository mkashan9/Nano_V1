# XP-03 — Achievements and Stickers

## Purpose

XP-01 and XP-02 made XP and levels trusted. Me still showed fixture badges.
This module awards named achievements and stickers from trusted events, keeps
the grant path server-only, and wires Me to the live list.

## Delivered

**`achievement_definitions`** — catalog with kind `achievement` or `sticker`,
bilingual titles, and a rule (`topic_completions_at_least`,
`quiz_passes_at_least`, `level_at_least`).

**Seeded grants** — First Steps (sticker, first video), Quiz Rookie (first
quiz pass), Rising Star (level ≥ 2), Level Climber (level ≥ 3).

**`achievement_awards`** — unique `(user_id, achievement_id)`. Replay cannot
grant twice.

**`evaluate_achievements`** — runs after level refresh, topic completion, and
quiz submit so a capped XP day can still unlock First Steps from the
completion itself.

**`my_achievements`** — learner read model; Me prefers it when Supabase is
wired. Stickers use a distinct icon on the profile list.

## Deferred

Featured pinning / share cards (XP-06). Admin catalog editing (ADM-05).
Streak badges (XP-05). Companion celebration moment for a new award (CMP hook).
