# LRN-04 known issues

- Recall prompts collect nothing yet. The learner is asked to think, and the
  answer is not captured; QUIZ-01 owns real questions.
- The refresh-prompt switch lives only in the player's constructor and Classroom
  Mode. A dedicated preference row in `student_preferences` arrives with the
  settings pass.
- Generated prompt text is generic. Per-topic wording is a curator task once the
  content tools exist.
- The video surface is still the LRN-03 placeholder, so "pause" stops a
  simulated clock rather than a real player.
- `rebuild_refresh_checkpoints` has no admin UI; it runs from the trusted
  backend.
