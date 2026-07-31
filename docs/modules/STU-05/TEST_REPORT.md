# STU-05 — Test report

| Test | Result |
|------|--------|
| `supabase/tests/stu05_profile_privacy_sessions.sql` (via MCP `execute_sql`) | PASS — cross-user/teacher denied, platform admin privacy count 0, revoke audits, active sessions 0 after revoke |
| `packages/nano_domain/test/student_profile_view_test.dart` | PASS (5 tests) |
| `packages/nano_data/test/student_profile_repository_test.dart` | PASS (5 tests) |
| `apps/student_app/test/student_profile_page_test.dart` | PASS (5 tests) |
| `apps/student_app` full suite | PASS (50 tests) |
| `packages/nano_domain` full suite | PASS (56 tests) |
| `packages/nano_data` full suite | PASS (22 tests) |

## Coverage notes

- Public projection never contains any of `PublicProfileProjection.forbiddenFields`.
- Hiding achievements empties them from the projection and discoverable=false propagates.
- Device session: current device not revocable; other active device is; last-seen label formats.
- Repository: privacy upsert recorded; revoke refuses the current device and marks others; sync clear empties cache and queue.
- Page: privacy toggle writes, device revoke updates the list, sign-out clears caches, load failure shows the error state.

## Advisors

- WARN `authenticated_security_definer_function_executable` on `public.revoke_device_session` — intentional, documented in DECISIONS.
- WARN `auth_leaked_password_protection` — pre-existing Auth setting, out of module scope.
