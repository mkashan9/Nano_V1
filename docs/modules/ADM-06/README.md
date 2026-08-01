# ADM-06 — Game Administration

## Purpose

Platform staff can manage the game catalog: draft new games, publish a version,
and disable (kill-switch seed) with an audited reason.

## Delivered

**Tables** — `games`, `game_versions` (draft / published / archived + enabled).

**RPCs** — `list_games_admin`, `create_game_draft`, `publish_game_version`,
`disable_game_version`.

**Games hub** — `/game-admin` with list + detail (publish / disable).

## Deferred

Student play host, sessions, score verify, asset packaging (GME-01..), and full
product kill-switch UX (GME-07 builds on `enabled=false` here).
