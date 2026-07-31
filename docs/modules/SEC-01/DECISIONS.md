# SEC-01 Decisions

- Automation SEC-01 is **baseline + workflow**; handbook “SEC-01 Tenancy/RLS” maps primarily to SEC-02/SEC-03.
- Applied baseline to classified development project `nano_v1` only.
- `app_health` is intentionally readable by anon for connectivity smoke tests; it holds no PII.
- Tenancy tables (`schools`, `memberships`, …) wait for SEC-02.
