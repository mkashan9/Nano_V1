# ADR-0007: Offline mutation limits

## Status

Accepted (SYNC-01)

## Context

Handbook §12 and FND-05 require offline drafts for selected flows while keeping scores, XP, publish, and membership server-authoritative.

## Decision

- Client may draft: attendance, marks (short-lived), quiz answers, game play, read caches.
- Client must not queue as final: score publish, XP award, membership changes.
- Every queued mutation uses a globally unique `operation_id` (idempotency key).
- Never silently overwrite a newer cache/server revision; surface retry / discard / keep-saved-version.
- User-facing copy must not say “sync queue”.

## Consequences

Feature modules (ATT, MRK, QZ, GME) plug into `NanoSyncController` / `SyncQueueStore`. Durable on-device storage can replace the in-memory store without changing domain types.
