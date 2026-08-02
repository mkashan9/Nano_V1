# GME-01 — Game Catalog and Eligibility

Learners see published, enabled games that pass grade and school/independent
eligibility. Play host is deferred to GME-02.

## Owns

- `game_versions.independent_allowed`
- `list_games_for_learner` + `nano_internal.game_version_is_eligible`
- `GameCatalog` / `GameCatalogRepository`
- Student Games tab catalog list

## Does not own

- Web/Flutter game host → GME-02 / GME-03
- Score verify / XP → GME-05
- Kill-switch UX → GME-07
- Admin draft/publish → ADM-06
