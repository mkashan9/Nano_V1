# QZ-05 test report

## Automated

| Suite | Result |
|-------|--------|
| `quiz_attempt_test.dart` | 3 passed |
| `quiz_attempt_repository_test.dart` | 2 passed |
| `quiz_attempt_submit_test.dart` + junior/senior pages | passed |
| `learner_quiz_repository_test.dart` (catalog topic ids) | 4 passed |
| `apps/student_app` full suite | 94 passed |

## Server checks (rolled-back)

| Check | Result |
|-------|--------|
| Learner submit counting quiz | score 100 |
| Idempotent resubmit | ok |

## Security notes

No insert policies on `score_results` for learners; scoring is security definer.
