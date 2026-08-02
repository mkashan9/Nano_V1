# SAFE-03 — Rate Limits, Restricted Content, and Link Rules

Server-side flood limits and text/link policy for social actions. Seeds are
migration-managed; admin CRUD is deferred.

## Owns

- `safety_rate_limits` / `safety_rate_usage`
- `restricted_terms` / `link_allowlist_hosts`
- Helpers gating friend requests, reports, and future community messages
- `check_safety_text` / `my_safety_rate_status` preview RPCs

## Does not own

- Report submit UI → SAFE-01
- Moderation queue → SAFE-02
- Community messaging → COM-04
- Platform policy editor UI → later ADM / SAFE-04
