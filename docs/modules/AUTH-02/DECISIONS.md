# AUTH-02 Decisions

- Mirror AUTH-01 email/password lean path; school-code login deferred.
- Fixture `teacher@alpha.nano.dev` maps to profile UUID `cccccccc-…`.
- Shared `SupabaseAuthRepository` with `allowedAccountKinds` so student app rejects teachers and teacher app rejects students.
- Admin/indie auth deferred to AUTH-03/04.
