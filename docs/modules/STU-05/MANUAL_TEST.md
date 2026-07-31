# STU-05 Manual Test

## Setup

```powershell
cd D:\nano\apps\student_app
flutter run -d chrome `
  --dart-define=NANO_ENV=development `
  --dart-define=SUPABASE_URL=https://jjsnvmxasbtimesjsyoy.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

Sign in as a school junior (for example Ali) who has finished onboarding.

## Steps

1. Open the **Me** tab. Expect your name, initials avatar, level line, school/class line, companion name and language tag, and an XP chip.
2. Expect Progress with a streak, topics completed, a "Next up" item, and any featured achievements.
3. Under Privacy, turn **Let others find me** off. Leave the tab and return (or reload). Expect the toggle still off.
4. Under Settings, switch language to **Urdu**. Expect the profile headings to flip RTL. Switch back to English.
5. Tap **Accessibility**. Expect the existing accessibility page; change text size and return. Expect the scale to stick.
6. Under Devices, expect the current device labelled **This device** with no revoke button, one other active device with **Sign out device**, and any already-revoked device labelled **Signed out**.
7. Tap **Sign out device** on the other active device. Expect it to move to **Signed out**.
8. Tap **Sign out**. Expect to land on the sign-in screen. Sign in again (or use a preview persona) and confirm language is back to English defaults and no leftover offline drafts appear in the Offline debug preview.

## Server checks

Run `supabase/tests/stu05_profile_privacy_sessions.sql` (or the equivalent MCP blocks). Expect:

- No `FAIL:` exceptions
- `ali_active_sessions_after_revoke = 0` and `ali_revoke_audit_rows = 1` inside a rolled-back revoke block
- `platform_admin_visible_privacy_rows = 0`
- Cross-user and teacher revoke attempts denied
