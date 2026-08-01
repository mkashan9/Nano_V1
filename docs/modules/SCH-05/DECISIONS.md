# SCH-05 decisions

- Extend SEC-02 `teacher_assignments` with real academic FKs; keep
  `class_label` / `subject_code` as denormalized display.
- Co-assign allowed; matrix surfaces conflicts (shared scopes) and uncovered
  `class_subjects`.
- End sets `status=left` with audited reason; replace ends then creates so
  historical authorship stays intact.
- Assign requires an active class-subject map from SCH-02.
