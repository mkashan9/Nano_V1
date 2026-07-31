# AUTH-01 Decisions

- Email/password for R1 lean student auth; school-code+login-ID provisioning is ADM later.
- Fixture email `ali@alpha.nano.dev` maps to profile UUID `aaaaaaaa-…` (RLS-compatible).
- Live auth only when `SUPABASE_URL` + `SUPABASE_ANON_KEY` dart-defines are set; otherwise preview persona mode for existing widget tests.
- Teacher/admin/indie signup deferred to AUTH-02/03/04.
- No FK `profiles`→`auth.users` yet (other fixtures lack auth users).
