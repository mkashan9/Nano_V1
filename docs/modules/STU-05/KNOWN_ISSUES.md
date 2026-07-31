# STU-05 — Known issues

- Progress, achievements, and the "next up" recommendation are fixture-backed until LRN/XP land.
- `SupabaseStudentProfileRepository.loadProfile` reads `profiles` + `student_preferences` only; school name, class, email, guardian, attendance, and marks are not yet joined (no safe academic projection exists).
- The current-device marker depends on an optional `currentSessionId` passed into the Supabase repository; the app does not yet register a live device session on sign-in (SEC-03 seed fixtures cover the fake).
- Privacy toggles affect the public projection immediately in domain terms, but no social discovery surface exists yet to observe the change end-to-end (COM/SAFE).
- Junior guardian gate for sensitive settings is deferred (see DECISIONS).
- The Supabase advisor warns that `authenticated` can execute `public.revoke_device_session`; that is intentional for the self-service path and constrained to the caller's own sessions.
- Run the app from `apps/student_app` (`cd apps/student_app; flutter run -d chrome`). Running from the repo root omits the Material icon font.
