# XP-04 decisions

## Bonus XP goes through the ledger

Missions do not invent a second XP path. Completing a period calls
`award_xp(..., 'mission_complete', mission_id:period_key, amount)` so the daily
cap, audit trail, and level refresh all still apply.

## Period keys, not rolling windows

Daily uses `YYYY-MM-DD` UTC. Weekly uses ISO `IYYY-WIW`. Progress counts events
whose timestamps fall on or after the period start, so a late-night completion
lands in the day the server saw, not the learner's local calendar.
