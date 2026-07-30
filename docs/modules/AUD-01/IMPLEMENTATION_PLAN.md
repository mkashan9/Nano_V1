# AUD-01 Implementation Plan

## Scope

Complete first-execution Phases 0–7 and package results as AUD-01 for owner review.

## Files changed (intended)

- `.gitignore`, `.cursorignore`
- `AGENTS.md`, `TASKS.md`, `MODULE_STATUS.md`, `PROJECT_STATUS.md`, `CHANGELOG.md`
- `automation/**`
- `docs/**`
- `UI_reference/manifest.yaml`
- `supabase/` (init + env example)
- `.github/workflows/ci.yml`
- `.cursor/rules/**`

## Out of scope

- Creating product Flutter apps (FND-01)
- Remote Supabase schema changes
- Fixing `avatar_trials` analyzer debt (documented only)

## Tests

- Documentation completeness review
- `git check-ignore` on secret paths
- `flutter doctor` (PASS)
- `avatar_trials` analyze (FAIL — known; see KNOWN_ISSUES)
- Secret filename CI job

## Security

- No secrets in commits
- Provider keys only in ignored `.env.local`
