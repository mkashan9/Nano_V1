# TCH-02 — My Classes and Assigned Scope

Teacher-app **Classes**: active assignment list and server-guarded class roster.

## Owns

- `public.teacher_my_classes()`
- `public.teacher_class_roster(uuid)`
- `TeacherClassesPage` list + roster detail (`/classes?assignment=`)

## Does not own

- Attendance / marks / classroom workflows → ATT / MRK / CLS
- Assignment matrix editing → SCH-05
- Learner email / guardian contact on roster
