# QZ-05 — Trusted Scoring, Attempts, Retakes, and Resume

## Purpose

Persist quiz attempts on the server, score submit idempotently, and resume
in-progress answers. The client never invents the final score.

## Deliverables

| Area | What shipped |
|------|--------------|
| Database | `quiz_attempts`, `attempt_answers`, `attempt_events`, `score_results`, `suspicious_attempt_flags` |
| RPCs | `start_or_resume_quiz_attempt`, `save_attempt_answer`, `submit_quiz_attempt` |
| Domain | `QuizAttemptSession`, `ScoreResult`, flow resume helpers |
| Data | `QuizAttemptRepository` (fake + Supabase) |
| Student app | Junior/Senior finish submit and show server score |
| Tests | Domain, data, widget, adversarial SQL |

## Rules

- Learners own their attempt rows; score_results are RPC-only writes.
- Duplicate submit returns the same score.
- Retakes respect `quiz_policies.max_retakes`.
- Resume restores saved option ids without correctness flags.

## Out of scope

- Full results/explanations UI (QZ-06)
- XP ledger updates (XP-01)
