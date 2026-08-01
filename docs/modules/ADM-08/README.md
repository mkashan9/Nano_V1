# ADM-08 — Platform Analytics

## Purpose

Platform staff can open **Analytics** and see privacy-safe platform aggregates:
health, catalog readiness, and last-7-day learning/audit activity.

## Delivered

**RPC** — `platform_analytics` (platform admin only).

**Analytics hub** — `/analytics` replaces the shell stub with metric cards and a
7-day audit action breakdown (no actor identities).

## Deferred

Event taxonomy / `analytics_events` (ANA-01), school health scores, school-scoped
report packs (SCH-07).
