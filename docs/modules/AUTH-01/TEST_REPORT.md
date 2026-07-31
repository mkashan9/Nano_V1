# AUTH-01 Test Report

| Test | Result | Notes |
|------|--------|-------|
| MCP apply_migration auth01_student_ali_auth_user | RUN | version 20260731053518 |
| packages/nano_auth fake_auth_repository_test | RUN | |
| apps/student_app sign_in_page_test | RUN | FakeAuthRepository |
| Live Ali sign-in against nano_v1 | OWNER | MANUAL_TEST |
| CI workflow | NOT RUN | PAT missing workflow scope |
