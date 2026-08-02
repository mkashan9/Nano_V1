# MRK-03 — Marks Excel Download and Upload

Teacher marks **CSV/Excel-compatible** template download, preview, and commit
into the same `marks_entries` as MRK-02.

## Owns

- `marks_import_jobs`, `marks_import_rows`
- `teacher_marks_template`, `preview_marks_import`, `commit_marks_import`
- CSV paste/import UI on Marks grid

## Does not own

- In-app grid entry → MRK-02
- Publish / correction → MRK-04
- Binary `.xlsx` parser (CSV opened/saved by Excel is the supported path)
