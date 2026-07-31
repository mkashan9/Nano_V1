# AUTH-03 Implementation Plan

1. Seed school admin profile/membership + auth users for platform and school admin.
2. Extend SupabaseAuthRepository bootstrap for school_staff and platform.
3. Gate admin_web behind sign-in when Supabase keys are present.
4. Document fixtures; FakeAuthRepository + widget tests.
