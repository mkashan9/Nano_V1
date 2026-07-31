# AUTH-02 Test Report

| Test | Result | Notes |
|------|--------|-------|
| MCP apply_migration auth02_teacher_auth_user | RUN | version 20260731055319 |
| packages/nano_auth fake_auth_repository_test | RUN | includes teacher fixture |
| apps/teacher_app teacher_sign_in_page_test | RUN | FakeAuthRepository.teacher |
| Live Ms Khan sign-in against nano_v1 | OWNER | MANUAL_TEST |
| CI workflow | NOT RUN | PAT missing workflow scope |
