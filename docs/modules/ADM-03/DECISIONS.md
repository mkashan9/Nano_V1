# ADM-03 decisions

## Search minimizes PII

Results expose id, display name, account kind, status, session count, and
school code/role summaries. Email, guardian, attendance, and marks are rejected
client-side if they appear.

## Status is active or suspended only

`set_profile_status` never writes `left`. Acting platform staff cannot change
their own profile status through this RPC.

## Replace admin demotes then assigns

Prior active `school_admin` memberships become `left`. The new admin must be an
active staff/teacher/platform profile. Both sides are audited.

## Session revoke is platform-only

`admin_revoke_user_sessions` is distinct from learner self-revoke (STU-05).
Reason is required; optional single session id is supported.
