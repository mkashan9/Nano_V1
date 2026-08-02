# GME-01 decisions

- Reuse ADM-06 `games` / `game_versions`; do not duplicate catalog tables.
- Learner access is RPC-only (`list_games_for_learner`); no learner table grants beyond existing select policies.
- Eligibility: published + enabled + grade band + `independent_allowed`.
- Catalog is browse-only; Start/Play stays for later modules.
- Fake repository mirrors server filters for UI-first tests.
