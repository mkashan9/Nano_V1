# QZ-05 known issues

- Explanations and rich results UI are deferred to QZ-06.
- Suspicious-flag writers are reserved; only an admin-readable table exists.
- Fixture-only: the fake learner quizzes are keyed to the fake catalog's
  `tv-*` topic ids, with the server fixture UUIDs kept as aliases. Live runs
  read real ids from `learner_quiz`, so no alias is involved there.
