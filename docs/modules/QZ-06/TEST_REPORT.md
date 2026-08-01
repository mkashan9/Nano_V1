# QZ-06 test report

## Automated

| Suite | Result |
|-------|--------|
| `packages/nano_domain/test/attempt_result_test.dart` | 10 passed |
| `packages/nano_data/test/quiz_attempt_result_test.dart` | 6 passed |
| `apps/student_app/test/quiz_result_test.dart` | 5 passed |
| `packages/nano_domain` + `packages/nano_data` suites | 222 passed |
| `apps/student_app` suite | 99 passed |

## Server checks (rolled-back)

Run against the development project; every check wrapped in a transaction that
was rolled back.

| Check | Result |
|-------|--------|
| `get_attempt_result` before submit | refused with `NQ030` |
| Review after submit | wrong answer flagged, correct option and explanation returned |
| `topic_quiz_progress` after submit | one row, last score 0, passed false |
| `learner_quiz_history` as owner | 1 row |
| `learner_quiz_history` as another learner | 0 rows |
| `topic_quiz_progress` as another learner | 0 rows |
| Direct insert into `topic_quiz_progress` | refused |
| `learning_next_up` after a failed quiz | topic returned with reason `review_quiz` |

## Security notes

Explanations and correct answers exist in exactly two server paths: the
platform-admin authoring view and `get_attempt_result` for a scored attempt.
`learner_quiz` still exposes neither, so the pre-submit path cannot leak them
even to a modified client. `topic_quiz_progress` has no learner insert, update,
or delete policy; submit is security definer.
