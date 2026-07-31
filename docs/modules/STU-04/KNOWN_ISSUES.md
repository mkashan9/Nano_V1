# STU-04 — Known issues

- Home content is still fixture-backed. `FakeStudentHomeRepository` supplies XP, streak, the update, the plan, and the Flex counts until the LRN, XP, and FLX modules land.
- The Flex card counts are placeholders; FLX-01 owns the real Flex read model.
- The latest update is a single item with no feed behind it; NOT-01 owns notifications and updates.
- Tapping the continue card, a plan item, or a subject does not navigate yet. Only the Flex card deep-links, because `/flex` is the one destination that already exists.
- Level thresholds are a flat 250 XP per level. XP-01 should replace this with the real curve.
- Independent learners see the senior composition minus Flex. IND-01 will fill that space with independent-appropriate content.
- Run the app from `apps/student_app` (`cd apps/student_app; flutter run -d chrome`). Running from the repo root omits the Material icon font and icons render as boxes.
