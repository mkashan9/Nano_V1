# SEC-03 Decisions

- Table name `audit_events` (handbook data dictionary) rather than `audit_logs`.
- Audit/login writes are service-role / future AUTH only; authenticated clients have select policies only (append-only for ordinary users).
- School suspension blocks member school visibility; platform superadmin retains access via `is_platform_admin`.
- Client `AccessGuard` mirrors server rules for UI; RLS remains authoritative.
