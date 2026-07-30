# FND-01 Known Issues

1. CI workflow still parked at `docs/setup/ci.yml.pending` until GitHub PAT has `workflow` scope.
2. Staging/production Supabase projects not created yet — development uses `nano_v1`.
3. Design tokens are placeholders until FND-02.
4. Leftover local `avatar_trials/` folder may still exist on disk if locked by another process; it is gitignored and not in the repo.
5. Melos global vs project version may differ (7.x workspace vs 8.x global) — use `dart run melos` from repo root if needed.
