# STU-02 Decisions

- Preferences are personal. Unlike onboarding progress, platform admins have no select policy on `student_preferences`. A school should never see a learner's companion name or accessibility choices.
- Companion name validation is structural only (length, letters, no blank). Word-level safety belongs to moderation modules; the name is private and never shown to other users.
- Default companion name is `Nori`, matching the handbook. An empty stored value falls back to Nori on read.
- The preferences step sits between experience and context so Junior/Senior tone is known before the learner names their guide, and the school/independent framing still comes after personal setup.
- Locale and accessibility apply immediately when toggled, not only on Continue, so Urdu RTL and reduced motion are visible before the learner commits.
- Shell language and accessibility changes after onboarding still write to the same preference row, so settings stay one place.
- Classroom Mode remains available from the existing accessibility settings page; the first-run step keeps the quietest three toggles to avoid overwhelming juniors.
