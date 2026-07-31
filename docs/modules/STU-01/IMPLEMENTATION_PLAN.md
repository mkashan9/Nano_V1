# STU-01 Implementation Plan

1. Add `student_onboarding` with owner-only RLS and a `nano_internal.is_student()` write guard.
2. Model steps, experience derivation, and progress in `nano_domain`.
3. Add `OnboardingRepository` (fake first, then Supabase) in `nano_data`.
4. Build the student flow page and gate it in the router after auth.
5. Load progress on session restore; upgrade the principal's track on completion.
6. Cover step order, resume, independent framing, and RLS isolation with tests.
