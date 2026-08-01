# ADM-03 — Global User and Account Control

## Purpose

Platform staff can search users safely, suspend or restore profiles with a
reason, replace a school admin, and revoke another user's device sessions.

## Delivered

**RPCs** — `search_platform_users`, `set_profile_status`,
`replace_school_admin`, `admin_revoke_user_sessions` (platform admin only).

**Users page** — `/users` destination with search, suspend/restore, replace
admin, and session revoke. Every privileged action requires a reason.

## Deferred

Admin-triggered password-reset email. Stronger step-up beyond reason text.
