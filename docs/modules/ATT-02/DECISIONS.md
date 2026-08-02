# ATT-02 decisions

- Template is CSV (Excel-compatible) with `student_user_id,display_name,status`.
- Commit reuses `teacher_attendance_submit` so bulk and in-app share canonical records.
- Import rejects non-roster student IDs; names are display-only.
- Binary `.xlsx` parsing deferred; paste/copy CSV is the mobile-first path.
