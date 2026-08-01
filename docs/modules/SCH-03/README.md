# SCH-03 — Teacher Management and Excel Import

School-admin **Teachers** hub: list, create, suspend/restore, and CSV import.

## Owns

- `list_school_teachers`, `create_school_teacher`, `set_school_teacher_status`
- `preview_teacher_import`, `commit_teacher_import` (CSV columns `display_name,email`)

## Does not own

- Students / enrollments → SCH-04
- Assignment matrix → SCH-05
- True `.xlsx` binary parsing (CSV is the first slice)
