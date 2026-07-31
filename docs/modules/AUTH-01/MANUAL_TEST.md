# AUTH-01 Manual Test Guide

## Fixture

| Field | Value |
|-------|-------|
| Email | `ali@alpha.nano.dev` |
| Password | `NanoAliDev1!` |
| Profile UUID | `aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa` |
| School | ALPHA01 |

Development fixture only — rotate before any shared/staging use.

## Run

```powershell
cd D:\nano\apps\student_app
flutter run -d chrome `
  --dart-define=NANO_ENV=development `
  --dart-define=SUPABASE_URL=https://jjsnvmxasbtimesjsyoy.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

## Checklist

- [ ] App opens on **Student sign-in** (not home)
- [ ] Sign in with Ali fixture → Junior shell / Home
- [ ] Profile shows Signed in + Ali UUID
- [ ] **Sign out** returns to sign-in; home not reachable without session
- [ ] Wrong password shows error
- [ ] Optional: `dart test` in `packages/nano_auth` and `apps/student_app/test/sign_in_page_test.dart`

## Approve

`NEXT`

## Reject

`FIX: <problem>`
