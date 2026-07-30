# FND-01 Implementation Plan

## Scope

Monorepo workspace, environment loader, app shells foundations, remote-first Supabase developer workflow.

## Files

- `apps/**`, `packages/**`, `melos.yaml`, `pubspec.yaml`
- `docs/setup/ENVIRONMENTS.md`, `SUPABASE_REMOTE_WORKFLOW.md`
- `scripts/verify.ps1`, `scripts/verify.sh`
- Module docs under `docs/modules/FND-01/`

## Out of scope

- Full design system (FND-02)
- Auth (AUTH-*)
- Schema/RLS (SEC-*)
- Docker / `supabase start` (forbidden by ADR-0002)

## Tests

- Domain unit tests
- App widget tests
- `flutter analyze` across workspace
- `flutter build web` for student_app
