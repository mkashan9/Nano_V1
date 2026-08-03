# PAR-02 — Superadmin Weekly PDF and Activity Upload

## Purpose

Let superadmins create weekly parent guidance packages, attach a PDF
filename, add home activity tips, and publish. Learner-facing card remains
PAR-01; this module owns the admin upload/publish surface (fake-first).

## Deliverables

- Domain: `WeeklyGuidancePackage`, `WeeklyGuidancePublishPolicy`
- Fake `WeeklyGuidanceAdminRepository` (PDF = filename ending in `.pdf`)
- Superadmin nav **Parent guidance** + `ParentGuidanceAdminPage`
- Publish requires title, body, week key, and PDF name

## Does not own

- Live storage / binary PDF upload
- Syncing published packages into student PAR-01 repository
- Guardian linking UI (PAR-03)

## Owner test focus

Superadmin → Parent guidance → New draft → attach `*.pdf` name → save tips →
Publish. Confirm publish without PDF is rejected.
