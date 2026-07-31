# LRN-05 — Learning Progress and Recommendations

## Purpose

Tell a learner where they stand and what to open next, and make the answer come
from the server rather than from whatever the app happens to have cached.

Two read models do the work:

- `public.learning_progress_summary` — one row per subject the learner can see,
  counting topics finished, topics in flight, topics still locked, and credited
  watch time.
- `public.learning_next_up` — the same learner's unfinished, unlocked topics,
  ranked, each carrying the reason it was chosen.

## Deliverables

| Area | What shipped |
|------|--------------|
| Database | `learning_progress_summary`, `learning_next_up`, `last_activity_at` added to `learning_catalog` |
| Domain | `SubjectProgress`, `NextUpSuggestion`, `NextUpReason`, `LearningInsights` |
| Data | `LearningInsightsRepository` with fake and Supabase implementations |
| Student app | `LearningProgressPage`, a profile entry point, Continue Learning on Home |
| Tests | 14 domain, 6 data, 11 widget, 6 adversarial SQL groups |

## Ranking

The server orders candidates as:

1. `resume` — already in progress, most recently touched first.
2. `next_in_subject` — untouched topic in a subject the learner has worked in.
3. `new_subject` — untouched topic in a subject they have not opened.

Ties fall back to subject order, then topic order, so the ranking is stable
between reads. `rank = 1` is the recommendation; the rest are alternatives.

## Why this is safe

Both views are `security_invoker` and both read `public.learning_catalog`, which
already applies eligibility, publication state, and prerequisite locks as the
calling learner. A suggestion therefore cannot name a topic the learner could not
already open, and a summary cannot count another learner's progress. There is no
client-side filter standing in for that enforcement.

## Strengths and focus areas

`LearningInsights.strongest` and `needsAttention` are derived from completion
ratios over subjects the learner has actually started. That is progress, not
mastery — real strengths need quiz scoring, which arrives with QZ-05. The UI says
"Going well" and "Worth some time" rather than claiming skill.

## Surfaces

- Profile → **Your progress** opens the screen.
- Home → **Continue Learning** follows the server's rank-1 suggestion straight
  into the topic, and falls back to the progress screen if that topic cannot be
  resolved from the catalog.
- The learning catalog page shows a **Your progress** action when an insights
  repository is supplied.

## Handbook alignment

- LRN-01 Learning Stack Catalog: "progress, and next recommendations".
- PRF-01 Profiles: "learning progress, completed topics … recommended next
  activity".
- STU-01 Student Home: "Continue Learning".
