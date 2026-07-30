# AUD-01 Known Issues

1. **Docker / local Supabase (superseded)** — `supabase start` unavailable until Docker Desktop runs with accessible engine pipe.
2. **GitHub CLI login** — PAT lacks `read:org`; use GCM for git; use session `GH_TOKEN` for `gh` when needed; owner may widen scopes.
3. **avatar_trials analyzer** — `test/widget_test.dart` references `MyApp` which does not exist; product apps not started yet.
4. **Product Flutter apps missing** — Expected; FND-01 will scaffold.
5. **Branch protection** — Owner must enable settings in `docs/setup/GITHUB_REPOSITORY_SETTINGS.md`.
6. **Key rotation** — Video/voice keys lived briefly in root `api_s.txt`; rotation recommended if the file was shared.

7. **CI workflow not on default path yet** � Push blocked without PAT workflow scope; workflow saved as `docs/setup/ci.yml.pending` until owner widens token scopes.

8. **avatar_trials removed** — Owner directed complete deletion; provenance updated to DISCARD.
9. **No Docker** — Remote-first Supabase per ADR-0002; do not require Docker Desktop.

