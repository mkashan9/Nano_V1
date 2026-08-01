# ADM-01 — Superadmin Dashboard

## Purpose

Platform staff land on a real Platform home instead of a stub: safe aggregate
metrics, school directory search, recent audit preview, and shortcuts to
Content / Moderation / Schools / Audit. Create/codes and privileged user
actions stay with ADM-02 / ADM-03.

## Delivered

**`platform_dashboard`** — superadmin-only RPC returning counts, filtered
school summaries (code, name, status, learner/staff counts), and minimized
audit lines (action, target type, school code, timestamp).

**Platform home** — `AdminMetricCard` overview, search, shortcuts. Content and
Moderation destinations are unchanged.

## Deferred

School create/status writes (ADM-02). Suspend, replace admin, session revoke
with reason (ADM-03). Full Audit destination workflows.
