# LRN-04 test report

## Domain — `packages/nano_domain/test/refresh_checkpoint_test.dart`

21 tests pass. Covers which prompt is due (nothing before the first, the one
just crossed, never a prompt already answered, optional prompts dropped after
the grace window, required prompts still due after a scrub past them, the later
of two crossed prompts winning), the credit gate (stops at the first unanswered
required prompt, opens after it is answered, optional prompts never gate), the
seeking ceiling, chapter ordering and protection, Urdu chapter and prompt text,
and row mapping.

## Data — `packages/nano_data/test/checkpoint_repository_test.dart`

6 tests pass. Checkpoints come back in order with the required one identified, a
short topic has none, acknowledgement is idempotent and records each response,
answers do not leak across topics, watch credit stops at the gate and resumes
once cleared, and completion still needs the threshold on a long video.

## Widget — `apps/student_app/test/topic_player_checkpoint_test.dart`

7 tests pass. A refresh moment pauses playback and offers **Keep watching**, an
answered moment does not return, **Take a break** leaves the video paused,
Classroom Mode silences the optional prompt but not the required one, the
required prompt states that credit is paused, the current chapter is named, and
no-skip-ahead content stops the scrubber at the watched ceiling and reports the
clamped position.

Full suites also pass: student_app 76 tests, nano_domain 104, nano_data 44.

## Adversarial SQL — `supabase/tests/lrn04_checkpoints.sql`

Run against the development project.

| Check | Result |
| --- | --- |
| `plan_refresh_checkpoints` on a 120s video | 0 rows |
| `plan_refresh_checkpoints` on the 2400s fixture | `660:stretch, 1320:recall, 1800:stretch` |
| 600s candidate snapped to the 660s chapter boundary | pass |
| Nothing generated inside the protected 1140–1320 segment | pass |
| Insert at 60s | refused, `NL007` |
| Insert at 1200s (inside the assessment) | refused, `NL008` |
| Insert at 1900s (within five minutes of 1800) | refused, `NL009` |
| Rebuild preserves the hand-placed required prompt at 1320 | pass |
| Learner inserts a checkpoint | refused, `insufficient_privilege` |
| Learner calls `rebuild_refresh_checkpoints` | refused, `insufficient_privilege` |
| Learner inserts into `checkpoint_events` to clear a gate | refused, `insufficient_privilege` |
| Learner reads the three checkpoints for a visible topic | 3 rows |
| Heartbeat past an unanswered required checkpoint | credit stops at 1320 |
| Unknown acknowledgement response | refused, `NL011` |
| Acknowledging twice | one row, same id |
| Heartbeat after acknowledgement | credit resumes to 1400 |
| Heartbeat at 145s on no-skip-ahead content from 0 watched | position clamped to 30 |

## Static analysis

`dart analyze` on the three packages reports only pre-existing warnings (two
unused imports and one dangling library doc comment), none in LRN-04 files.

## Security advisors

`public.acknowledge_checkpoint` joins the existing intentional
`authenticated_security_definer_function_executable` warnings alongside
`start_topic`, `record_playback_heartbeat`, `complete_topic`, and
`revoke_device_session`; the reasoning is in DECISIONS.md. No new
`function_search_path_mutable` or RLS findings. The pre-existing
`auth_leaked_password_protection` advisory is unchanged and owner-configurable.
