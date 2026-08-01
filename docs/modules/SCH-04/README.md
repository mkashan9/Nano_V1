# SCH-04 — Student Management and Excel Import

School-admin **Students** hub: list, create, suspend/restore, class enrollment,
and CSV import.

## Owns

- `student_enrollments`
- `list_school_students`, `create_school_student`, `set_school_student_status`,
  `enroll_school_student`, `preview_student_import`, `commit_student_import`

## Does not own

- Teachers → SCH-03
- Assignment matrix → SCH-05
- Guardians / promotion bulk workflows (later)
