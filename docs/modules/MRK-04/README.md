# MRK-04 — Marks Publication and Correction

Teachers publish draft assessments and correct published marks with
immutable history (ATT-03 pattern).

## Owns

- `assessments.revision`, `published_at`, `published_by`
- `marks_corrections` (immutable)
- `teacher_marks_publish`, `teacher_marks_correct`, `teacher_marks_history`
- Publish + correction UI on Marks

## Does not own

- Student results views → FLX-03
- Class performance summary → MRK-05
- Closed-period privileged override (deferred)
- Notification delivery on publish (audit-only stub)
