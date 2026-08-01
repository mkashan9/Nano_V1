# SCH-02 — Classes, Grades, Sections, and Subjects

School-admin **Classes** hub for academic structure: grade levels, classes,
sections, school subjects, and class↔subject maps.

## Owns

- `grade_levels`, `classes`, `sections`, `school_subjects`, `class_subjects`
- RPCs: `list_academic_structure`, create_*, `assign_class_subject`,
  `archive_academic_structure`
- Overview `class_count` now reads active classes

## Does not own

- Attendance / grading / report-card policies → SCH-06
- Teacher assignment FKs → SCH-05
- Student enrollment → SCH-03/04
- Platform Learning Stack subjects → LRN/ADM-04
