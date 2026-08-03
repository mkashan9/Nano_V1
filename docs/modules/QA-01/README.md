# QA-01 — Security Hardening

## Purpose

Encode pilot security gates as an executable checklist: Flutter anon-only
config, AccessGuard denials for suspended/revoked actors, no secret material
in principals, and reminders that RLS remains authoritative.

## Deliverables

- Domain: `SecurityHardeningPolicy`, `SecretPatternPolicy`, client config gates
- `EnvironmentConfig` rejects `service_role` in the anon key slot
- Fake `SecurityHardeningRepository`
- Superadmin **Security** (`/audit`) checklist page

## Does not own

- Live pen-tests / bug bounty
- Changing SEC-02/SEC-03 RLS (already authoritative)
- Provider API key storage (must stay in Edge Functions)

## Owner test focus

Superadmin → Security → confirm all checks passed. Confirm service_role anon
keys are rejected by config/tests.
