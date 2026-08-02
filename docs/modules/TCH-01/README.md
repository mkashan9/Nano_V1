# TCH-01 — Teacher Dashboard

Teacher-app **Dashboard**: caller-scoped active assignments and pending
workflow stubs (attendance / marks / classroom remain zero until those modules).

## Owns

- `nano_internal.require_teacher_school_id()`
- `public.teacher_dashboard()` (SECURITY DEFINER, caller teacher only)
- `TeacherDashboard` / repositories / `TeacherDashboardPage`

## Does not own

- Class roster and deep class navigation → TCH-02
- Attendance / marks / classroom workflows → ATT / MRK / CLS
