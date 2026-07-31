# SYNC-01 — Local Cache, Drafts, Queue, and Conflict States

## Purpose

Provide the client substrate for offline-friendly reads, short-lived drafts, idempotent mutation queues, and conflict resolution UI — without treating offline as trusted.

## Deliverables

- Domain: `SyncEnvelope`, `SyncQueueItem`, `CacheEntry`, `SyncConflict`, `OfflineMutationPolicy`
- Data: `LocalCacheStore`, `SyncQueueStore`, `NanoSyncController`
- UI: `NanoConflictBanner` + student debug **Offline** preview
- ADR-0007 offline mutation limits

## Owner test focus

Open student app debug **Offline** page; confirm cache timestamp, pending draft, and conflict actions.
