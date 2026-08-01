# QZ-06 known issues

- No dedicated attempt-history screen yet. `QuizAttemptRepository.history` and
  `public.learner_quiz_history` exist and are tested, but nothing in the student
  app renders them.
- A passed quiz does not yet award XP or advance a streak (XP-01).
- The seeded quizzes have a single question, so the multi-question review is
  covered by fake-backed tests rather than by the remote fixtures.
- `learning_progress_summary` still counts topics only; per-subject quiz pass
  counts are not exposed.
