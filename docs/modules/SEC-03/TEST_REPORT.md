# SEC-03 Test Report

| Test | Result | Notes |
|------|--------|-------|
| MCP apply_migration sec03_audit_sessions_guards | RUN | version 20260731051524 |
| Security advisors | RUN | clean (no lints) |
| School suspension hides Alpha from Ali | RUN | codes=[] while suspended; restored |
| Ali insert audit_events | RUN | RLS 42501 denied |
| packages/nano_domain access_guard_test | RUN | see CI/local dart test |
| CI workflow | NOT RUN | PAT missing workflow scope |
