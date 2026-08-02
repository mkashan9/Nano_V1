# GME-05 — Trusted Game Result Verification

Server verifies client game completions (token, bounds, nonce, version)
before writing `game_results` and awarding `game_result` XP once.

## Owns

- `game_score_submissions`, `game_results`, `rejected_scores`
- Verifying `report_game_client_completed`
- Host banner for verified / rejected / XP awarded

## Does not own

- Leagues / leaderboards → LGE-*
- Kill switch UX → GME-07
- CDN packs → GME-04 follow-up
