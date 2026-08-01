# QZ-02 decisions

- Quiz versions bind to `topic_version_id` (one video revision → one quiz lineage).
- `learner_quiz` uses `security_invoker = false` and strips `is_correct` so
  learners never read authoring correctness flags.
- Content hub tabs keep QZ-01 and QZ-02 on the same Superadmin Content destination.
