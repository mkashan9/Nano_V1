# AUTH-04 Decisions

- Profile creation happens in a SECURITY DEFINER trigger, not from the client; `profiles` still has no client insert policy.
- Only `account_kind=independent_student` is auto-provisioned. Forged metadata claiming `teacher`, `school_staff`, or `platform` is ignored, and no profile is created.
- Independent accounts get no `school_memberships` row; school linking is IND-04.
- Recovery uses Supabase `resetPasswordForEmail` and always reports the same message, so the UI never discloses whether an address is registered.
- Signup writes no `login_events` row; a signup is not a sign-in.
- `login_events` and `device_sessions` cascade from `profiles`; `audit_events` deliberately does not, so account deletion with audit history stays an explicit ops decision.
- Password rule for R1: 8+ characters with letters and digits, enforced client-side and by Supabase Auth.
