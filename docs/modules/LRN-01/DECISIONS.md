# LRN-01 Decisions

## Publication model

Draft `subject_versions` / `topic_versions` have no learner read path. Platform admins see drafts for preview against the same version IDs learners will eventually get.

## Eligibility is a server decision

`nano_internal.subject_is_eligible` reads onboarding track/grade and the eligibility rule row. The client never filters drafts or senior-only subjects — RLS does.

## Prerequisite locks arrive as titles

The catalog view returns `blocking_titles` / `is_locked`. The UI displays them; it does not recompute the graph.

## One catalog, two compositions

`LearningCatalog.topicVersionIds` is the equality proof that Junior and Senior shells show the same published content. Search is Senior-only chrome over the same rows.

## School subjects stay out

Learning Stack subjects are platform-curated only. School-created subjects are not seeded here (handbook rule).

## Progress is owner-only

`learning_progress` is private academic data. No social projection reads it (PRF-01). Video completion writes arrive with LRN-03.
