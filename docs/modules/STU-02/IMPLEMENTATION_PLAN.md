# STU-02 Implementation Plan

1. Add `student_preferences` with owner-only RLS and students-only writes.
2. Extend the onboarding step contract with `preferences`.
3. Model companion-name rules and preference row mapping in `nano_domain`.
4. Add fake and Supabase preference repositories in `nano_data`.
5. Insert the setup step into the onboarding flow and apply locale/a11y live.
6. Persist preference changes made outside onboarding from the app shell.
