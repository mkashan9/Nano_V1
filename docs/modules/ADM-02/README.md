# ADM-02 — School Creation, Codes, Status, and Administrator Control

## Purpose

Platform staff can create schools with immutable codes, change status with an
audited reason, and assign the first school administrator. Replace-admin and
user-level suspend stay with ADM-03.

## Delivered

**RPCs** — `create_school`, `set_school_status`, `assign_first_school_admin`,
`list_managed_schools` (platform admin only).

**Schools page** — list/search, create dialog, status dialog with reason,
first-admin assignment when missing.

## Deferred

Replace school admin, session revoke, stronger step-up auth (ADM-03). School
branding and setup progress (SCH-01).
