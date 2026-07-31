# SEC-01 Manual Test Guide

## Prerequisites

- No Docker
- Optional: Flutter with dart-defines for live health check

## Checklist

- [ ] Confirm `supabase/migrations/20260731045507_sec01_baseline.sql` exists
- [ ] Run `powershell -File scripts\check_migration_layout.ps1` → OK
- [ ] (Owner/dev) In Supabase dashboard or MCP: `app_health` exists, RLS on, one row `schema_version=SEC-01`
- [ ] Optional live check:

```powershell
cd D:\nano\apps\student_app
flutter run -d chrome `
  --dart-define=NANO_ENV=development `
  --dart-define=SUPABASE_URL=https://jjsnvmxasbtimesjsyoy.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

Open **DB health** → Check app_health → Status OK / Schema SEC-01

- [ ] Confirm no service-role key in the repo

## Approve

`NEXT`

## Reject

`FIX: <problem>`
