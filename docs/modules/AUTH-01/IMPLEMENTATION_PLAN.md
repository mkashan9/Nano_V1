# AUTH-01 Implementation Plan

1. Create Ali auth.users + identity with fixed profile UUID.
2. Implement auth repositories and student bootstrap from profiles/memberships.
3. Gate student router behind sign-in when Supabase keys are present.
4. Document fixture credentials; unit/widget tests with FakeAuthRepository.
