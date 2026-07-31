# STU-04 Manual Test

## Setup

Run from the app directory, not the repo root (the root package does not bundle the Material icon font).

```powershell
cd D:\nano\apps\student_app
flutter run -d chrome `
  --dart-define=NANO_ENV=development `
  --dart-define=SUPABASE_URL=https://jjsnvmxasbtimesjsyoy.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

Use a senior school learner who has finished onboarding.

## Steps

1. Land on Home. Expect the greeting, a `Level 3 · 7 day streak` line, an XP chip, and a progress bar reading `190 XP to next level`.
2. Expect the latest update card ("Ms Khan reviewed your quiz") above the continue card.
3. Expect **Animals Adventure** as a senior progress card showing `42% done`.
4. Expect a **Flex** card showing `3 tasks open · Due Friday`. Tap it and expect to land on the Flex tab.
5. Scroll to **Today's Plan**. Expect all three plan items with their XP, not a capped list.
6. Scroll further. Expect the subject cards with progress and estimated minutes.
7. Switch the debug role to **Independent**. Expect the same senior composition with no Flex card and no Flex tab.
8. Switch to **Junior**. Expect the STU-03 junior composition instead.
9. Switch language to **Urdu**. Expect `آج کا پلان`, an Urdu level line, and RTL layout.
10. Resize narrow and wide. Expect subjects to move between a single column and a grid without clipping.

## Partial-data check

Handbook acceptance: home renders with partial data when one source fails. To see it in the app, set `failSections` on the fake repository in `apps/student_app/lib/main.dart`, for example:

```dart
FakeStudentHomeRepository(
  subjects: StudentHomeFixtures.subjects,
  missions: StudentHomeFixtures.missions,
  failSections: const {HomeSection.subjects},
)
```

Expect the Subjects heading followed by "Subjects — This part didn't load." with a **Try again** button, while the level line, update, continue card, and plan all still render. Tapping **Try again** reloads the home.

## Server checks

None. This module adds no tables, policies, or functions, and performs no XP or level writes.
