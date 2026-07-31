# SEC-03 Manual Test Guide

## Checklist

- [ ] Migration present: `sec03_audit_sessions_guards`
- [ ] Run `powershell -File scripts\check_migration_layout.ps1`
- [ ] Tables exist with RLS: `audit_events`, `device_sessions`, `login_events`, `security_incidents`
- [ ] `app_health.schema_version` = `SEC-03`
- [ ] Suspend Alpha → Ali JWT sees no schools → restore Alpha to active
- [ ] Ali cannot insert into `audit_events` (RLS deny)
- [ ] Security advisors clean

## Approve

`NEXT`

## Reject

`FIX: <problem>`
