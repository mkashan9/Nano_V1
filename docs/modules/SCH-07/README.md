# SCH-07 — School Reports

School-admin **Reports** hub: privacy-safe operational summaries for headcount,
assignment coverage, enrollment, result periods, and teacher workload counts.

## Owns

- `school_reports_summary` (SECURITY DEFINER, caller school only)

## Does not own

- Marks entry / PDF report cards → MRK / later
- Attendance grids → ATT
- Platform-wide analytics → ADM-08 / ANA-01
