# AUTH-04 Manual Test

## Setup

Run from the app directory. Running from the repo root builds the
`nano_workspace` package, which bundles no Material Icons font, so every icon
renders as an empty box.

```powershell
cd D:\nano\apps\student_app
flutter run -d chrome `
  --dart-define=NANO_ENV=development `
  --dart-define=SUPABASE_URL=https://jjsnvmxasbtimesjsyoy.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

## Steps

1. On the sign-in screen, tap **Create an independent account**.
2. Enter a name, a fresh email, and a password shorter than 8 characters. Expect an inline error and no account.
3. Correct the password to something like `NanoLearn1` and submit.
4. Expect the independent student shell: Home, Play, Me — and **no Flex tab**.
5. Sign out, then tap **Forgot password?** and submit the same email.
6. Expect the neutral confirmation message and a reset email in the inbox.
7. Repeat step 5 with an email that has no account. Expect the identical message (no account disclosure).
8. Sign in as `indie@nano.dev` / `NanoIndieDev1!`. Expect the independent shell.

## Server checks

Run `supabase/tests/auth04_independent_signup.sql` against the development project. It must complete with `AUTH-04 trigger OK`.
