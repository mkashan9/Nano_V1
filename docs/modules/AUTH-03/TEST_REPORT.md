# AUTH-03 Test Report

| Test | Result | Notes |
|------|--------|-------|
| MCP apply_migration auth03_admin_auth_users | RUN | version 20260731060846 |
| packages/nano_auth fake_auth_repository_test | RUN | school admin + platform |
| apps/admin_web admin_sign_in_page_test | RUN | FakeAuthRepository.schoolAdmin |
| Live admin sign-in against nano_v1 | OWNER | MANUAL_TEST |
| CI workflow | NOT RUN | PAT missing workflow scope |
