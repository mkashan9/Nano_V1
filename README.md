# Nano

Education platform monorepo.

## Apps

- `apps/student_app` — students (Junior / Senior)
- `apps/teacher_app` — teachers
- `apps/admin_web` — school management + superadmin (role shells later)

## Packages

- `nano_design_system`, `nano_domain`, `nano_data`, `nano_auth`, `nano_media`, `nano_games`, `nano_testing`

## Setup

1. Install Flutter stable (3.44+).
2. From the repo root:

```powershell
dart pub get
dart run melos bootstrap
```

Or: `.\scripts\bootstrap.ps1`

3. Copy `.env.example` values into your shell / `--dart-define` (never commit secrets).
4. Supabase is **remote-first** — no Docker. See `docs/setup/ENVIRONMENTS.md`.

> Prefer `dart run melos …` over a global `melos` command so you do not need Pub Cache on PATH.

## Verify

```powershell
dart run melos run verify
```

Or `.\scripts\verify.ps1` on Windows.
