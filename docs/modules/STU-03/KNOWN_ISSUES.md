# STU-03 — Known issues

- Home data is fixture-backed. `FakeStudentHomeRepository` supplies the resumable lesson, missions, streak, XP, and notification count until the LRN and XP modules land.
- Tapping a subject or the continue card does not navigate yet; lesson routes arrive with the learning modules.
- The notification badge count is not wired to a notification feed (NOTI module).
- The maintenance and access-warning notices are driven by the repository field, not yet by a server flag.
- Run the app from `apps/student_app` (`cd apps/student_app; flutter run -d chrome`). Running from the repo root omits the Material icon font and icons render as boxes.
