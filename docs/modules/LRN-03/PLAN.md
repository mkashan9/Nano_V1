# LRN-03 plan

1. Add playback metadata to `topic_versions` and watch accounting to
   `learning_progress`.
2. Create `topic_completions` with a unique completion key and read-only RLS.
3. Add `nano_internal.playback_credit`, replace `save_topic_progress` with
   `record_playback_heartbeat`, and add `complete_topic`.
4. Extend `learning_catalog` with playback metadata and credited seconds.
5. Model captions and the playback rules in `nano_domain`.
6. Extend `LearningProgressRepository` with heartbeat and complete, and teach
   the fake the same rules.
7. Build `TopicPlayerPage` and open it from topic detail.
8. Test: domain policy, fake repository, player widget, adversarial SQL.
9. Update status docs and hand over for the owner test.
