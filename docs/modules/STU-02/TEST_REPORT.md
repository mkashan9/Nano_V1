# STU-02 Test Report

| Test | Result | Notes |
|------|--------|-------|
| MCP apply_migration stu02_student_preferences | RUN | version 20260731100730 |
| supabase/tests/stu02_preferences_isolation.sql | RUN | cross-user blocked, platform admin sees 0, blank rejected |
| packages/nano_domain student_preferences_test + onboarding | RUN | 39 tests pass in package |
| packages/nano_data student_preferences_repository_test | RUN | 11 tests pass in package |
| apps/student_app onboarding_flow_test | RUN | 6 tests pass including blank name and live locale |
| flutter analyze | RUN | no new issues |
| Supabase security advisors | RUN | only pre-existing leaked-password warning |
| Live preferences walkthrough | OWNER | MANUAL_TEST |
| CI workflow | NOT RUN | PAT missing workflow scope |
