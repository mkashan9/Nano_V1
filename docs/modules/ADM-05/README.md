# ADM-05 — Gamification Administration

## Purpose

Platform staff can edit XP policy, reshape the level curve, activate achievement
and mission catalog rows, and apply manual XP adjustments with a reason.

## Delivered

**RPCs** — `list_gamification_admin`, `set_xp_daily_cap`, `set_xp_award_amount`,
`set_level_step`, `set_achievement_active`, `set_mission_active`,
`set_mission_rewards`, `admin_adjust_xp`.

**Gamification hub** — `/gamification` with Policy, Levels, Catalog, Adjust tabs.

## Deferred

Streak repair, league/game administration, bulk import, rich definition editors.
