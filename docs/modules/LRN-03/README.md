# LRN-03 — Video Player, Resume, Captions, and Completion

## Purpose

Turn a topic into a watchable session whose progress the server can trust:
resume where the learner stopped, show captions when the version has them, and
grant completion only after the server has credited enough watch time.

## Deliverables

- `topic_versions` playback metadata: `duration_seconds`,
  `completion_threshold`, `video_provider`, `video_ref`, `captions`.
- `learning_progress` watch accounting: `watched_seconds`,
  `last_heartbeat_at`.
- `public.record_playback_heartbeat(topic_version_id, position_seconds)` —
  the client reports the player head; the server decides the credit.
- `public.complete_topic(topic_version_id)` — threshold-checked, idempotent,
  audited, and recorded in `public.topic_completions`.
- `nano_internal.playback_credit()` — the credit rule in one place.
- `learning_catalog` carries playback metadata and credited seconds.
- Domain: `CaptionCue`, `CaptionTrack`, `PlaybackPolicy`, and playback fields
  on `CatalogTopic`.
- Data: `LearningProgressRepository.heartbeat/complete` with a fake that
  mirrors the server rules.
- UI: `TopicPlayerPage` with resume, position, captions toggle, credited-time
  readout, gated **Mark complete**, and a companion slot.

## Owner test focus

Watching earns progress. Dragging the scrubber does not. Completion appears
only after the threshold, and reopening the topic resumes at the saved second.

## Not in this module

- Real provider playback (MED-01) — the video surface is a placeholder.
- Long-video refresh checkpoints (LRN-04).
- XP for completion (XP-01) reads `topic_completions` later.
