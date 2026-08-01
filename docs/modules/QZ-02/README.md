# QZ-02 — Video-Specific Ordered Quiz Authoring

## Purpose

Attach an ordered, versioned quiz to a topic (video) version so learners later
attempt one published quiz per video. Questions come from the QZ-01 bank.

## Deliverables

| Area | What shipped |
|------|--------------|
| Database | `quiz_versions`, `quiz_policies`, `quiz_items`, `quiz_authoring`, `learner_quiz` |
| RPCs | `create_quiz_draft`, `replace_quiz_items`, `publish_quiz_version`, `retire_quiz_version` |
| Domain | `TopicQuiz`, `QuizItem`, `QuizPolicy` |
| Data | `TopicQuizRepository` (fake + Supabase) |
| Admin web | Content hub → Topic quizzes with Junior/Senior preview |
| Seeds | Counting, addition, living-things quizzes |
| Tests | Domain, data, widget, adversarial SQL |

## Rules

- Only platform admins can author quizzes.
- Learners read `learner_quiz` without `is_correct`.
- Drafts are mutable; published and retired quizzes (and their items/policies) are immutable.
- Only published question versions can be attached.
- At most one published quiz per topic version.
- Junior and Senior previews share the same `quiz_version_id`.

## Out of scope (later modules)

- Student Junior/Senior attempt UX (QZ-03 / QZ-04)
- Trusted scoring (QZ-05)
