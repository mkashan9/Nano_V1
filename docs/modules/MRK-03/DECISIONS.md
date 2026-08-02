# MRK-03 decisions

- CSV/Excel-compatible template with stable `student_user_id`.
- Columns: student_user_id, display_name, status, obtained_marks, remarks.
- Empty roster rows default to `not_submitted` so template preview can commit.
- Preview/commit produce the same `marks_entries` as in-app save.
- Only draft assessments accept import.
- Binary xlsx parser deferred.
