# LRN-02 — Topic List, Ordering, and Prerequisites

## Purpose

LRN-01 made prerequisite locks visible. LRN-02 makes them binding: the server refuses to start or record progress on a topic the learner has not unlocked, ordering is enforced by constraints rather than by curator discipline, and the learner gets a topic detail surface that explains what to do and why something is closed.

## Deliverables

- Ordering integrity: unique topic order per subject; prerequisites confined to one subject and checked for cycles
- `nano_internal.topic_lock_titles` — one helper behind both the catalog read model and the write guards, so displayed locks and enforced locks cannot drift
- `public.start_topic` / `public.save_topic_progress` — the only write path to `learning_progress`; direct client writes are revoked
- Completion is not client-settable; `start`/`save` never write `completed` (LRN-03 and QZ-05 own that)
- Domain: `TopicAction`, shared action labels, `TopicProgress`, `TopicGateException`
- Data: `LearningProgressRepository` (fake + Supabase, with server refusals mapped to reasons)
- UI: `TopicDetailPage` with objectives, resources, estimated time, progress, unlock reason, and a state-matched action button

## Owner test focus

As Junior, start Counting to 20 and confirm the button becomes Resume. Open Adding small numbers and confirm it stays locked and names Counting to 20. As Senior, confirm Plants and animals is locked behind Living things.
