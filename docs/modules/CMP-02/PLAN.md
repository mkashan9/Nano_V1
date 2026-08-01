# CMP-02 plan

1. Domain: `CompanionSurface`, `CompanionMode` with surface-based resolution,
   `CompanionPresentation`, and `CompanionRules` (budget, priorities, story-card
   selection).
2. Domain: extend the runtime with surface, session budget, Classroom Mode quiet,
   `notifyFirstOf` for collisions, `newSession`, and `skipReason`.
3. Copy: localized mode labels and the dismiss label, so the design system holds
   no strings.
4. Design system: `CompanionModeTheme` for accent and emblem; a story-card
   presentation and a mode badge inside the shared `CompanionStage` frame.
5. Student app: quiz results as Quiz Coach, onboarding welcome as a story card,
   gallery showing every mode and both presentations.
6. Tests: mode/mood independence, story-card rarity, priority order, budget
   exhaustion and exemption, Classroom Mode, frame sharing, wiring.
7. Docs and status; branch, PR, owner manual test.

No database or Edge Function work.
