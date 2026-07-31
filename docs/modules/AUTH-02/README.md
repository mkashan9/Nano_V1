# AUTH-02 — Teacher Authentication

## Purpose

Teacher email/password sign-in against remote Supabase, session restore, route guards, and logout — bound to SEC-02 Ms Khan profile UUID.

## Deliverables

- Ms Khan `auth.users` fixture (`teacher@alpha.nano.dev`)
- `SupabaseAuthRepository` app-scoped account kinds (`teacher`)
- Teacher sign-in page, `/sign-in` + `/blocked`, Sign out
- FakeAuthRepository.teacher() for tests

## Owner test focus

Sign in as Ms Khan with Supabase dart-defines; land in Teacher shell; Sign out returns to sign-in.
