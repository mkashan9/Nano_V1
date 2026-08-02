# ATT-02 — Attendance Excel Download and Upload

Teacher attendance **CSV/Excel-compatible** template download, preview, and
commit into the same `attendance_sessions` / `attendance_entries` as ATT-01.

## Owns

- `attendance_import_jobs`, `attendance_import_rows`
- `teacher_attendance_template`, `preview_attendance_import`, `commit_attendance_import`
- CSV paste/import UI on Attendance

## Does not own

- In-app grid entry → ATT-01
- Corrections/history → ATT-03
- Binary `.xlsx` parser (CSV opened/saved by Excel is the supported path)
