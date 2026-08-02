# ATT-01 — In-App Attendance Grid

Teacher **Attendance** destination: pick active assignment + date, mark roster,
submit with idempotency. Excel import is ATT-02; corrections are ATT-03.

## Owns

- `attendance_sessions`, `attendance_entries`
- `teacher_attendance_load` / `teacher_attendance_submit`
- `TeacherAttendancePage`

## Does not own

- Excel template/upload → ATT-02
- Correction history → ATT-03
- Student Flex attendance views → FLX-02
