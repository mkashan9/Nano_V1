# LRN-01 — Learning Subject Catalog

## Purpose

Deliver the platform-curated Learning Stack: published subjects and topics with eligibility, prerequisite locks, estimated time, objectives, and resume state. Junior worlds and Senior searchable lists render the same underlying version IDs.

## Deliverables

- Schema: `learning_subjects`, `subject_versions`, `topics`, `topic_versions`, `topic_prerequisites`, `eligibility_rules`, `learning_progress`
- Read model: `public.learning_catalog` (`security_invoker`) with server-computed lock state
- Helpers: `nano_internal.subject_is_eligible` / `subject_is_visible` (drafts stay invisible; eligibility is not a client filter)
- Domain: `LearningCatalog`, `CatalogSubject`, `CatalogTopic`
- Data: `LearningCatalogRepository` (fake + Supabase)
- UI: `LearningCatalogPage` (Junior worlds / Senior search) and `SubjectTopicsPage` (ordered topics, locks, objectives)
- Home subject taps open the topic list against catalog IDs

## Owner test focus

As Junior, open Math and confirm Adding is locked behind Counting. Switch to Senior, confirm Science appears and Math still uses the same topic version IDs. Search "living" and confirm only Science remains.
