# FND-01 — Workspace, Configuration, and Environments

## Purpose

Create the Nano monorepo foundation: Melos/Dart workspace, apps, shared packages, environment contracts, and remote-first Supabase setup (no Docker).

## Deliverables

- `apps/student_app`, `apps/teacher_app`, `apps/admin_web`
- Packages: `nano_design_system`, `nano_domain`, `nano_data`, `nano_auth`, `nano_media`, `nano_games`, `nano_testing`
- `EnvironmentConfig`, `FeatureFlag`, `BuildInfo`, `ServiceEndpoint`
- Debug diagnostics page + environment badge (non-production)
- `.env.example`, `docs/setup/ENVIRONMENTS.md`, remote Supabase workflow docs
- `melos run` / `scripts/verify.ps1` verification entry points

## Owner test focus

Bootstrap Melos, run student app in Chrome with DEV badge, open diagnostics, confirm no Docker requirement.
