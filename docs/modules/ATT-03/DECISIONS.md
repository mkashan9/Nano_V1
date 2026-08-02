# ATT-03 decisions

- Corrections only apply to **submitted** sessions.
- Reason is required (non-empty after trim).
- Each correction appends an immutable row with `previous_status` + `new_status`.
- Current `attendance_entries.status` updates; history rows are never updated/deleted (trigger).
- Session `revision` bumps on each correction.
- Bulk UI may apply multiple student changes sequentially with one shared reason.
