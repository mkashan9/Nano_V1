# AUTH-02 Implementation Plan

1. Create Ms Khan auth.users + identity with fixed teacher profile UUID.
2. Extend SupabaseAuthRepository with allowedAccountKinds for teacher app.
3. Gate teacher_app router behind sign-in when Supabase keys are present.
4. Document fixture; unit/widget tests with FakeAuthRepository.teacher().
