# AUTH-04 Test Report

| Test | Result | Notes |
|------|--------|-------|
| MCP apply_migration auth04_independent_signup | RUN | version 20260731065548 |
| MCP apply_migration auth04_profiles_auth_fk | RUN | version 20260731070026 |
| MCP apply_migration auth04_signup_trigger_cleanup | RUN | version 20260731070117 |
| supabase/tests/auth04_independent_signup.sql | RUN | trigger, escalation guard, cascade all pass |
| packages/nano_auth independent_signup_test | RUN | 14 tests pass |
| apps/student_app sign_up_page_test | RUN | signup, weak password, recovery |
| apps/student_app full suite | RUN | 15 tests pass |
| Supabase security advisors | RUN | only pre-existing leaked-password warning |
| Live signup against nano_v1 | OWNER | MANUAL_TEST |
| CI workflow | NOT RUN | PAT missing workflow scope |
