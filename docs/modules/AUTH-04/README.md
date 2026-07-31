# AUTH-04 — Independent Student Signup and Recovery

## Purpose

Self-service account creation and password recovery for learners without a school code, provisioned by the server so a client can never grant itself a privileged account kind.

## Deliverables

- `nano_internal.handle_new_auth_user()` trigger on `auth.users` that creates an `independent_student` profile from signup metadata
- `profiles.id` foreign key to `auth.users` with cascade, so profiles cannot outlive an identity
- `signUpIndependent` and `requestPasswordRecovery` on `AuthRepository` (fake + Supabase)
- Student app `/sign-up` and `/recover` routes, linked from sign-in
- `indie@nano.dev` fixture for the existing independent profile

## Owner test focus

Create a new independent account from the student app, confirm it lands in the independent shell with no Flex, then request a recovery email.
