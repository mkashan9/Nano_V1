# SEC-01 Test Report

| Test | Result | Notes |
|------|--------|-------|
| MCP apply_migration sec01_baseline | RUN | success on nano_v1 |
| MCP apply_migration search_path fix | RUN | advisor WARN cleared |
| MCP list_tables app_health RLS | RUN | rls_enabled=true, rows=1 |
| MCP execute_sql schema_version | RUN | SEC-01 |
| scripts/check_migration_layout.ps1 | RUN | filename convention |
| nano_data app_health_snapshot_test | RUN | unit |
| flutter analyze health page | RUN | no issues |
| CI workflow | NOT RUN | PAT missing `workflow` scope |
| Live Flutter health (needs anon key) | OWNER | optional manual |
