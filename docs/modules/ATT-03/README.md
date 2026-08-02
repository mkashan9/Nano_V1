# ATT-03 — Attendance Correction and History

Teachers correct **submitted** attendance with a required reason. Prior values
are never erased — each change appends to `attendance_corrections`.

## Owns

- `attendance_corrections`
- `teacher_attendance_correct`, `teacher_attendance_history`
- Correction + history UI on Attendance (after submit)

## Does not own

- Initial grid submit → ATT-01
- CSV/Excel import → ATT-02
- Marks corrections → MRK-04
