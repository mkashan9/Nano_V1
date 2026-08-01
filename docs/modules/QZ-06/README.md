# QZ-06 — Quiz Results, Explanations, and Progress Update

## Purpose

Turn a submitted attempt into a result the learner can learn from: the server
score, a per-question review with the correct answer and an explanation, the
retake budget the server will actually honour, and a progress signal that keeps
an unpassed quiz in the recommendations.

## Deliverables

| Area | What shipped |
|------|--------------|
| Database | `topic_quiz_progress` (server-written outcome per learner + quiz) |
| RPCs | `get_attempt_result`; `submit_quiz_attempt` now records the outcome and returns the retake budget |
| Read models | `learner_quiz_history`; `learning_next_up` gains the `review_quiz` reason |
| Domain | `AttemptResult`, `AttemptReviewItem`, `QuizAttemptHistoryEntry`, `NextUpReason.reviewQuiz` |
| Data | `QuizAttemptRepository.result` / `.history`, retake-aware fake |
| Student app | `QuizResultView` shared by Junior and Senior, retake action |
| Tests | Domain, data, widget, adversarial SQL |

## Rules

- Explanations and correct answers are released only after submit.
  `get_attempt_result` raises `NQ030` while the attempt is open, and
  `learner_quiz` still carries neither.
- Pass/fail and the percent stay server-authored; the client never recomputes
  either from the review.
- The retake button reflects `quiz_policies.max_retakes`; the same budget is
  enforced by `start_or_resume_quiz_attempt`.
- `topic_quiz_progress` has no learner write path; only submit writes it.
- Junior and Senior show the same verdict and the same explanations, differing
  only in density and warmth.

## Out of scope

- XP and streak updates for a passed quiz (XP-01)
- A standalone attempt-history screen; history is exposed on the repository
  but not yet given its own surface
- Curator-facing analytics on missed questions (ANA-01)
