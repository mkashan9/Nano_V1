# STU-01 Decisions

- Progress lives server-side in `student_onboarding`, one row per learner, so onboarding resumes across devices rather than only in local storage.
- Writes are restricted to active students by `nano_internal.is_student()`; a teacher or admin account cannot create onboarding rows even for itself.
- Grade level collected here is explicitly a learner self-report. The column is named `self_reported_grade_level` and the table comment says it is never authoritative; SCH-04 will supply verified grades and may override the track.
- `ExperiencePolicy` resolves in priority order: authorized override, verified grade, self-report, then senior as the safe default. Junior is grade 5 and below.
- Independent learners keep `AppRole.independentStudent` regardless of track, so the flow never mentions Flex, attendance, or marks.
- Every step transition is saved, not just completion, which is what makes resume-after-interruption work.
- Companion naming, language, sound, and accessibility setup stay in STU-02; this module only introduces the companion slot.
