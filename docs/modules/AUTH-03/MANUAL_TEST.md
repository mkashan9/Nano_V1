# AUTH-03 Manual Test Guide

## Fixtures

| Role | Email | Password | UUID |
|------|-------|----------|------|
| School admin | `admin@alpha.nano.dev` | `NanoSchoolAdminDev1!` | `ffffffff-ffff-ffff-ffff-ffffffffffff` |
| Platform | `platform@nano.dev` | `NanoPlatformDev1!` | `dddddddd-dddd-dddd-dddd-dddddddddddd` |

Development fixtures only.

## Run

```powershell
cd D:\nano\apps\admin_web
flutter run -d chrome `
  --dart-define=NANO_ENV=development `
  --dart-define=SUPABASE_URL=https://jjsnvmxasbtimesjsyoy.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

## Checklist

- [ ] App opens on **Admin sign-in**
- [ ] School admin → School shell (Overview)
- [ ] Sign out → sign-in; then platform → Superadmin shell
- [ ] Student/teacher credentials rejected
- [ ] Optional: nano_auth + admin_sign_in_page_test

## Approve

`NEXT`

## Reject

`FIX: <problem>`
