# SEC-03 — Audit Logs, Sessions, Suspension, and Permission Guards

## Purpose

Add append-only audit and session tables, enforce school/profile suspension in RLS helpers, and ship client-side access guard models aligned with server checks.

## Deliverables

- Tables: `audit_events`, `device_sessions`, `login_events`, `security_incidents` (RLS on)
- Helpers: `nano_internal.can_access_school`, `profile_is_active`, `school_is_active`, `session_is_active`
- Domain: `AccessGuard`, `DeviceSession`, `AuditEvent`, `SecurityFixtures`
- Adversarial: suspended school hides data; students cannot insert audit rows

## Owner test focus

Confirm tables/RLS, suspension isolation, and advisors remain clean on `nano_v1`.
