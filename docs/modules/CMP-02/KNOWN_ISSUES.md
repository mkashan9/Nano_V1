# CMP-02 known issues

- Mode art is still the shared placeholder circle with a per-mode accent and
  emblem. Distinct per-mode master art and animation arrive with MED-01;
  `assetKey` already carries the mode so the swap is local to one widget.
- The session budget and cooldowns live in whichever runtime a surface holds, so
  they reset on a route change or restart. Until a shared holder exists, the
  budget is closer to a per-screen guard than a true per-session one.
- Only two learner surfaces are wired: quiz results (Quiz Coach) and the
  onboarding welcome (story card). Learning, games, progress, and social screens
  still show the plain `CompanionSlot`, so Explorer and Builder are visible only
  in the component gallery.
- In Classroom Mode the onboarding welcome companion is held back. The step still
  explains itself in text, but a first-run learner in Classroom Mode meets Nori
  by name only, without the introduction art.
- Story cards have no entrance animation yet beyond the shared switcher fade; the
  handbook's "entrance/exit treatment" is a single fade for every mode.
- `newSession()` exists but nothing calls it, because no component owns the
  session lifecycle yet.
