# LRN-03 known issues

- The video surface is a placeholder driven by a one-second clock. Approved
  provider playback arrives with MED-01; the accounting around it is final.
- Fixture durations are short (120–180s) so the owner test finishes quickly.
  Production versions set their own `duration_seconds`.
- Long-video refresh checkpoints are LRN-04, so nothing interrupts playback yet.
- Completion grants no XP yet. XP-01 will read `public.topic_completions`.
- `record_playback_heartbeat` and `complete_topic` are SECURITY DEFINER by
  design; see DECISIONS.md.
- Offline heartbeat queuing is not wired to SYNC-01 yet. A missed beat is
  simply lost, which only costs the learner credit, never the reverse.
