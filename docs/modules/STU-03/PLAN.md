# STU-03 — Plan

1. Domain: aggregate the home into one read (`StudentHomeSummary`) with junior rules (three missions, XP total, freshness label, content check).
2. Data: `StudentHomeRepository` interface plus a deterministic fake with switchable failure, cache, and notice behaviour.
3. Presentation: `JuniorHomePage` loads once, maps results to `NanoViewState`, and renders the junior composition (large cards, minimal text).
4. Wiring: thread the repository and the STU-02 companion name through the router into `StudentLearningTab`.
5. Copy: add English and Urdu strings for streak, notifications, keep going, percent done, and the access notice.
6. Tests: domain rules, fake repository behaviour, and widget coverage for every state plus the shell integration.
7. Docs and status: module docs, `MODULE_STATUS.md`, `PROJECT_STATUS.md`, `TASKS.md`, `CHANGELOG.md`, handbook traceability.

## Reuse

- `NanoViewStateHost`, `NanoOfflineBanner`, `JuniorActionCard`, `XpChip`, `CompanionSlot`, `NanoResponsive` (FND-02/FND-05)
- `StudentHomeFixtures`, `LearningSubject`, `HomePlanItem` (FND-03)
- `StudentPreferences.companionName` (STU-02)
