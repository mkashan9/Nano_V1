# STU-01 Manual Test

## Setup

Run from the app directory, not the repo root.

```powershell
cd D:\nano\apps\student_app
flutter run -d chrome `
  --dart-define=NANO_ENV=development `
  --dart-define=SUPABASE_URL=https://jjsnvmxasbtimesjsyoy.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

## Steps

1. Sign in as `indie@nano.dev` / `NanoIndieDev1!`. Expect the onboarding welcome screen, not the shell.
2. Tap **Continue**, pick grade 3, and confirm the screen shows **Junior**.
3. Tap **Continue**. Expect the independent introduction with no mention of Flex, attendance, or marks.
4. Reload the browser tab before finishing. Expect **We saved your place** and the same step you left, not the welcome screen.
5. Finish the flow with **Start learning**. Expect the student shell.
6. Reload again. Expect the shell directly, with no onboarding.
7. Sign in as `ali@alpha.nano.dev` / `NanoAliDev1!`, pick grade 9, and confirm **Senior** plus a school-context screen naming the school.
8. Switch the app language to Urdu and re-check the onboarding copy renders right-to-left.

## Server checks

Run `supabase/tests/stu01_onboarding_isolation.sql` against the development project. The teacher row count must be `0` and no `FAIL:` exception may be raised.
