# MRK-05 decisions

- Compute-on-read summary (no materialized table).
- Only `published` / `corrected` assessments.
- Percent and pass/fail use scored entries only; absent/exempt/not_submitted excluded from averages.
- Grades and passing threshold come from `school_marks_policies`.
