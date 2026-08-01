# SCH-06 — Marks and Result Policies

School-admin **Settings → Policies**: attendance mode, passing percent,
report-card format, grade bands, and result periods (open/close).

## Owns

- `school_marks_policies`, `result_periods`
- `get_school_marks_policy`, `upsert_school_marks_policy`,
  `create_result_period`, `close_result_period`

## Does not own

- Marks entry / publish → MRK-*
- Attendance grids → ATT-*
- School reports export → SCH-07
- Branding → SCH-01 (Settings → Branding tab)
