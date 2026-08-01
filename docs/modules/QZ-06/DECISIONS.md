# QZ-06 decisions

- **Results come from an RPC, not a view.** A view would have to be readable
  while an attempt is open, and the only thing keeping explanations back would
  be a client-side filter. `get_attempt_result` refuses an unscored attempt
  outright (`NQ030`).

- **One summary shape for submit and result.** `nano_internal.quiz_result_summary`
  builds the score and retake budget for both, so the retakes offered after
  finishing cannot disagree with what `start_or_resume_quiz_attempt` allows.

- **Outcome stored separately from `learning_progress`.** Topic completion stays
  LRN-03's watch-threshold rule. QZ-06 records the quiz outcome in
  `topic_quiz_progress` instead of overloading topic completion, so passing a
  quiz cannot silently substitute for watching the lesson.

- **An unpassed quiz keeps the topic recommended.** `learning_next_up` now
  returns `review_quiz` and no longer drops a completed topic whose quiz was
  failed, which is the "progress update" this module owes the learner.

- **Junior keeps its celebration.** Junior leads with "You finished the quiz!"
  and a companion, Senior leads with "Your results"; both then show the same
  score, review, and explanations from the same payload.

- **Explanations live with the answer key in the fake.** The fake learner quiz
  stays free of explanations so it keeps mirroring `learner_quiz`; the fake
  attempt repository supplies them, as the server does after submit.
