# LRN-04 plan

1. Add `chapters` and `seek_policy` to `topic_versions`.
2. Create `refresh_checkpoints` and `checkpoint_events` with learner-read,
   backend-write policies.
3. Add the placement trigger so curator edits obey the same rules as generation.
4. Implement `plan_refresh_checkpoints` and `checkpoint_is_protected`.
5. Add `rebuild_refresh_checkpoints` for curators, preserving hand-placed rows.
6. Add `checkpoint_credit_gate` and `acknowledge_checkpoint`.
7. Extend `record_playback_heartbeat` with the gate and the seeking clamp.
8. Rebuild `learning_catalog` with chapters and the seeking policy.
9. Seed the forty-minute Ecosystems fixture with a protected assessment chapter,
   generated prompts, and one hand-placed required prompt.
10. Add the domain models and `CheckpointPolicy`.
11. Add `CheckpointRepository` (fake and Supabase) and thread it to the player.
12. Show prompts, chapter names, the paused-credit notice, and the seek ceiling
    in `TopicPlayerPage`.
13. Cover the rules with domain, repository, widget, and adversarial SQL tests.
14. Update status files and open the pull request.
