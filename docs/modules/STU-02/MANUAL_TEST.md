# STU-02 Manual Test

## Setup

Run from the app directory, not the repo root.

```powershell
cd D:\nano\apps\student_app
flutter run -d chrome `
  --dart-define=NANO_ENV=development `
  --dart-define=SUPABASE_URL=https://jjsnvmxasbtimesjsyoy.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

Use a learner who has not finished onboarding, or delete their `student_onboarding` and `student_preferences` rows first.

## Steps

1. Sign in and advance past welcome and grade selection.
2. On **Name your learning guide**, clear the name and tap Continue. Expect an inline error and no advance.
3. Enter `Tara`, switch language to **Urdu**, and toggle reduced motion on. Expect the layout to flip RTL and the Continue label to become اردو copy.
4. Finish the remaining steps. On the ready screen, expect a greeting that names Tara.
5. Reload the browser. Expect the shell in Urdu with no onboarding gate.
6. Open accessibility settings, change text size, reload again. Expect the saved scale to stick.
7. Confirm a platform-admin session cannot see preference rows (`supabase/tests/stu02_preferences_isolation.sql`).

## Server checks

Run `supabase/tests/stu02_preferences_isolation.sql`. Expect `platform_admin_visible_rows = 0` and no `FAIL:` exception.
