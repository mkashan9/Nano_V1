# QA-06 — Pilot Release Preparation

## Purpose

Aggregate QA-01..QA-05 and handbook ops gates (feature flags, kill switch,
cross-tenant RLS, backup/restore, manual pilot scripts, environment
classification) into an executable superadmin readiness checklist.

## Deliverables

- Domain: `PilotReleasePolicy`, `PilotReleaseGates`
- Fake `PilotReleaseRepository`
- Superadmin **Pilot** (`/pilot`) checklist page + Platform shortcut
- Docs and owner manual steps

## Does not own

- Production cutover / remote Supabase deploy without owner approval
- Running live backup restore on production
- Replacing per-module smoke pages (QA-01..QA-05 remain the deep checks)

## Owner test focus

Superadmin → Pilot → All pilot gates passed. Confirm Platform → Pilot shortcut
opens the same checklist.
