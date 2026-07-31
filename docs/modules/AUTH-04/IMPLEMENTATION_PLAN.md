# AUTH-04 Implementation Plan

1. Add an `auth.users` insert trigger that provisions independent profiles server-side.
2. Bind `profiles.id` to `auth.users` (cascade) and seed the missing Bina fixture identity.
3. Extend `AuthRepository` with independent signup, recovery, and shared validation.
4. Add student `/sign-up` and `/recover` routes plus sign-in entry points.
5. Cover validation, duplicates, pending confirmation, and recovery in tests; document owner steps.
