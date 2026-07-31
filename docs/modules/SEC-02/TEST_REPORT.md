# SEC-02 Test Report

| Test | Result | Notes |
|------|--------|-------|
| MCP apply sec02_tenancy_rls | RUN | success |
| MCP apply sec02_internalize_rls_helpers | RUN | success |
| MCP list_tables RLS | RUN | 5 tenancy tables, rls=true |
| Adversarial Ali schools | RUN | only ALPHA01 |
| get_advisors security | RUN | clean |
| nano_domain tenancy_models_test | RUN | fixtures |
| CI workflow | NOT RUN | PAT missing workflow scope |
