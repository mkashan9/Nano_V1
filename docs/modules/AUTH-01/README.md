# AUTH-01 — Student Authentication

## Purpose

Student email/password sign-in against remote Supabase, session restore, route guards, and logout — bound to SEC-02 Ali profile UUID.

## Deliverables

- Ali `auth.users` fixture (`ali@alpha.nano.dev`)
- `nano_auth`: `AuthRepository`, `FakeAuthRepository`, `SupabaseAuthRepository`
- Student sign-in page, `/sign-in` + `/blocked` routes, Sign out
- SessionPrincipal `userId` / `schoolId` / `isAuthenticated`

## Owner test focus

Sign in as Ali with Supabase dart-defines; land in Junior shell; Sign out returns to sign-in.
