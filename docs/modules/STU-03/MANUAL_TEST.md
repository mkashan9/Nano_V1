# STU-03 Manual Test

## Setup

Run from the app directory, not the repo root (the root package does not bundle the Material icon font).

```powershell
cd D:\nano\apps\student_app
flutter run -d chrome `
  --dart-define=NANO_ENV=development `
  --dart-define=SUPABASE_URL=https://jjsnvmxasbtimesjsyoy.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

Use a junior learner who has already finished onboarding (for example the school junior fixture).

## Steps

1. Sign in and land on Home. Expect a greeting with your companion slot, a day streak line, an XP chip, and a notification bell with a badge.
2. Expect one large **Animals Adventure** card showing "Keep going · 42% done".
3. Expect **Today's Mission** with exactly three items and an XP-to-earn chip that sums them.
4. Scroll down. Expect the subject grid with large tappable cards (Math, English, Science, Stories).
5. Switch language to **Urdu** from the debug bar. Expect the greeting, mission heading, and streak label in Urdu and an RTL layout.
6. Use the debug role switch to pick **Senior**. Expect the senior home foundation instead of the junior composition.
7. Resize the browser narrow and wide. Expect the subject grid to change column count without clipping.

## State checks

These are covered by `apps/student_app/test/junior_home_page_test.dart` and can be re-created in the app by adjusting the fake repository flags in `main.dart`:

- `failOnce: true` → error state with **Try again** that recovers content.
- `servesCache: true` → content plus a "Last updated 3 h ago" banner.
- `notice: HomeNoticeKind.maintenance` → maintenance screen with no home content.
- `notice: HomeNoticeKind.accessWarning` → banner above content, learning still reachable.

## Server checks

None. This module adds no tables, policies, or functions; home content is still fixture-backed.
