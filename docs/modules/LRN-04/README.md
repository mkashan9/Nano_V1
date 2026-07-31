# LRN-04 — Long-Video Checkpoints and Refresh Interactions

## Purpose

A forty-minute video cannot be a single unbroken sitting for a child, and it
also cannot be chopped every ten minutes regardless of what is happening on
screen. LRN-04 implements the handbook's long-video rule: refresh moments near
ten-minute intervals, snapped to safe chapter boundaries, never inside an
assessment segment, silenceable when they are optional, and enforced on the
server when they are not.

## Deliverables

### Server

- `public.topic_versions.chapters` — ordered boundaries with a `protected` flag
  for segments that must not be interrupted.
- `public.topic_versions.seek_policy` — `free` or `no_skip_ahead`, per content.
- `public.refresh_checkpoints` — curator-owned prompts. Learners read; only the
  trusted backend writes.
- `public.checkpoint_events` — one row per learner per checkpoint, written only
  through `public.acknowledge_checkpoint`.
- `nano_internal.plan_refresh_checkpoints` — the handbook rule as code: nothing
  under thirty minutes, ten-minute targets, snap within two minutes to a
  non-protected boundary, five-minute minimum spacing.
- `nano_internal.assert_checkpoint_placement` — the same guardrails applied to
  curator edits, so moving a checkpoint cannot land it mid-assessment.
- `nano_internal.checkpoint_credit_gate` — where watch credit stops for this
  learner.
- `public.rebuild_refresh_checkpoints` — regenerates generated rows and
  preserves hand-placed ones. Trusted backend only.
- `public.acknowledge_checkpoint` — records the answer; the only way to release
  a credit gate.
- `public.record_playback_heartbeat` — now clamps the reported position under
  `no_skip_ahead` and caps credit at the gate.

### Client

- `RefreshCheckpoint`, `CheckpointKind`, `CheckpointResponse`, `VideoChapter`,
  `SeekPolicy`, and `CheckpointPolicy` in `nano_domain`.
- `CheckpointRepository` with fake and Supabase implementations.
- `TopicPlayerPage` pauses at a due checkpoint, shows a companion-led prompt
  with **Keep watching** and **Take a break**, names the current chapter, says
  when credit is paused, and stops the scrubber at the watched ceiling on
  no-skip-ahead content.

## What the owner should look at

Whether the interruption feels considerate rather than nagging: it arrives at a
chapter change, it never appears twice, Classroom Mode removes the optional one,
and the required one explains why it is there.
