# FBK-01 — Teacher-Guardian Structured Feedback

Teachers write structured feedback notes (effort / behavior / progress)
for roster students on an active assignment. Draft and publish in this
slice; guardian read is deferred.

## Owns

- `feedback_notes` table + enums
- `teacher_feedback_list` / `create` / `update` RPCs
- `TeacherFeedbackRepository` + Feedback nav destination

## Does not own

- Guardian inbox / replies → PAR-*
- Notifications → NOT-01
- Student Flex feedback surface
- Escalate / archive workflows
