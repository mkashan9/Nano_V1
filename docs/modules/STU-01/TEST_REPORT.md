# STU-01 Test Report

| Test | Result | Notes |
|------|--------|-------|
| MCP apply_migration stu01_student_onboarding | RUN | version 20260731100000 |
| supabase/tests/stu01_onboarding_isolation.sql | RUN | cross-user write blocked, teacher sees 0 rows |
| packages/nano_domain onboarding_models_test | RUN | 33 tests pass in package |
| packages/nano_data onboarding_repository_test | RUN | 8 tests pass in package |
| apps/student_app onboarding_flow_test | RUN | 19 tests pass in app, 4 new |
| flutter analyze | RUN | no new issues |
| Supabase security advisors | RUN | only pre-existing leaked-password warning |
| Live onboarding walkthrough | OWNER | MANUAL_TEST |
| CI workflow | NOT RUN | PAT missing workflow scope |
