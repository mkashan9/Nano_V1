# SYNC-01 Implementation Plan

1. Model sync envelope, queue statuses, cache revision rules, offline policy.
2. Implement in-memory cache + idempotent queue in `nano_data`.
3. Add conflict banner and student Offline preview (debug tools only).
4. Unit/widget tests; document ADR-0007; stop at USER_TEST.
