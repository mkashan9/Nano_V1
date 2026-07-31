# SYNC-01 Decisions

- In-memory store for R0 foundation; interface-shaped for later durable local DB.
- Idempotent enqueue by `operation_id` — duplicates return the existing item.
- Cache `put` rejects older revisions (never silent overwrite).
- User copy: “Pending changes”, “Keep saved version” — never “sync queue”.
