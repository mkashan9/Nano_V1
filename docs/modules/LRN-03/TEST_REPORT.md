# LRN-03 test report

| Suite | Result |
|-------|--------|
| `packages/nano_domain/test/topic_playback_test.dart` | PASS (credit caps, thresholds, resume, captions) |
| `packages/nano_domain/test/topic_action_test.dart` | PASS |
| `packages/nano_data/test/learning_progress_repository_test.dart` | PASS (heartbeat credit, refused completion, one-time completion) |
| `apps/student_app/test/topic_player_page_test.dart` | PASS (resume, watch credit, seek earns nothing, captions, refusal) |
| `apps/student_app` full suite | PASS (69 tests) |
| `supabase/tests/lrn03_playback_verification.sql` | PASS |
| `supabase/tests/lrn02_topic_gates.sql` (re-run on the new write path) | PASS |
| `dart analyze` | No new issues (two pre-existing unused-import warnings remain) |

## Adversarial SQL detail

| Check | Result |
|-------|--------|
| Jump to the end of the video, then claim completion | Refused with `NL005`, zero seconds credited |
| Heartbeat after a 60 second gap claiming 120 seconds of video | Credited 75 seconds (elapsed plus jitter) |
| Complete twice | One `topic_completions` row, unchanged `completed_at` |
| Insert into `topic_completions` as the learner | `insufficient_privilege` |
| Heartbeat on a locked topic | Refused with `NL001` |
| Completion audit | Exactly one `audit_events` row, invisible to the learner |
| Catalog after completion | Prerequisite topic unlocks through the shared helper |

## Security advisors

`record_playback_heartbeat` and `complete_topic` are reported as
`authenticated`-executable SECURITY DEFINER functions, which is intentional and
documented in DECISIONS.md — direct table writes are revoked, so these RPCs are
the only write path. `nano_internal.playback_credit` had a mutable
`search_path` on first apply and was pinned in a follow-up migration. The
pre-existing leaked-password-protection warning is unrelated to this module.
