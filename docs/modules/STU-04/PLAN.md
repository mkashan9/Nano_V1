# STU-04 — Plan

1. Domain: extend the STU-03 summary rather than forking it — `LevelProgress.fromXp`, `FlexSummary`, `HomeUpdate`, `HomeSection`, `failedSections`, and a `plan` getter that returns the full mission list.
2. Data: add `flexEligible` to `loadHome` and per-section failure switches to the fake, so partial-data behaviour is testable without a server.
3. Presentation: `SeniorHomePage` with the denser composition and inline `_SectionNotice` replacements for failed sections.
4. Deep links: home cards call back into the router, which resolves through `DeepLinkResolver` and falls back to Home with a message.
5. Wiring: `StudentLearningTab` routes seniors and independents to the new page, keeping `SeniorHomeFoundation` as the no-repository preview.
6. Copy: English and Urdu for level, XP-to-next, plan, Flex, and the section-failure notice.
7. Tests: domain level and partial rules, repository eligibility and section failures, widget coverage for every state plus eligibility and deep-link callbacks.
8. Docs and status.

## Reuse

- `StudentHomeSummary` and `StudentHomeRepository` (STU-03)
- `SeniorProgressCard`, `TeacherTaskCard`, `XpChip`, `CompanionSlot`, `NanoViewStateHost`, `NanoResponsive` (FND-02/FND-03/FND-05)
- `DeepLinkResolver` and `NavCatalog` (FND-04)
