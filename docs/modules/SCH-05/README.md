# SCH-05 — Teacher Assignment Matrix

School-admin **Assignments** hub: assign teachers to class/section/subject,
end or replace, and review coverage gaps plus workload.

## Owns

- `teacher_assignments` academic FKs (`class_id`, `section_id`,
  `school_subject_id`, `starts_on`, `ends_on`)
- `list_teacher_assignment_matrix`, `assign_teacher`,
  `end_teacher_assignment`, `replace_teacher_assignment`

## Does not own

- Teacher create/import → SCH-03
- Class/subject maps → SCH-02
- Timetable / marks policies → later modules
