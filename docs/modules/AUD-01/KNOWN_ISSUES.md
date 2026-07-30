# AUD-01 Known Issues

1. **Docker / local Supabase** — `supabase start` unavailable until Docker Desktop runs with accessible engine pipe.
2. **GitHub CLI login** — PAT lacks `read:org`; use GCM for git; use session `GH_TOKEN` for `gh` when needed; owner may widen scopes.
3. **avatar_trials analyzer** — `test/widget_test.dart` references `MyApp` which does not exist; product apps not started yet.
4. **Product Flutter apps missing** — Expected; FND-01 will scaffold.
5. **Branch protection** — Owner must enable settings in `docs/setup/GITHUB_REPOSITORY_SETTINGS.md`.
6. **Key rotation** — Video/voice keys lived briefly in root `api_s.txt`; rotation recommended if the file was shared.
