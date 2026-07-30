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
2. `dart pub global activate melos`
3. `melos bootstrap`
4. Copy `.env.example` values into your shell / `--dart-define` (never commit secrets).
5. Supabase is **remote-first** — no Docker. See `docs/setup/ENVIRONMENTS.md`.

## Verify

```bash
melos run verify
```

Or `scripts/verify.ps1` on Windows.
