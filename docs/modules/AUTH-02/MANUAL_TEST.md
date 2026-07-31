# AUTH-02 Manual Test Guide

## Fixture

| Field | Value |
|-------|-------|
| Email | `teacher@alpha.nano.dev` |
| Password | `NanoTeacherDev1!` |
| Profile UUID | `cccccccc-cccc-cccc-cccc-cccccccccccc` |
| School | ALPHA01 |

Development fixture only.

## Run

```powershell
cd D:\nano\apps\teacher_app
flutter run -d chrome `
  --dart-define=NANO_ENV=development `
  --dart-define=SUPABASE_URL=https://jjsnvmxasbtimesjsyoy.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

## Checklist

- [ ] App opens on **Teacher sign-in**
- [ ] Sign in with Ms Khan fixture → Teacher shell (Dashboard)
- [ ] **Sign out** returns to sign-in
- [ ] Optional: student Ali credentials rejected on teacher app
- [ ] Optional: `dart test` / `flutter test` for nano_auth + teacher_sign_in_page_test

## Approve

`NEXT`

## Reject

`FIX: <problem>`
