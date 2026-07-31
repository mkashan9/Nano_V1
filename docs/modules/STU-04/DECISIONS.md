# STU-04 — Decisions

1. **One summary, two compositions.** Junior and senior share `StudentHomeSummary`; junior reads `juniorMissions` (capped at three), senior reads `plan` (everything). The junior rule stays in the domain so neither screen can drift from it.
2. **Level is display-only.** `LevelProgress.fromXp` derives level and progress from server-owned XP at 250 XP per level. The client never writes XP or level. If the server later returns an authoritative level, it replaces the derivation without touching the UI.
3. **Flex eligibility comes from the server.** `loadHome` takes `flexEligible` and the repository decides whether to return a `FlexSummary`; the page additionally guards on the nav catalog. Two gates, and neither is the UI inventing entitlement. Independent learners have no path to a Flex card.
4. **Partial data over an error screen.** The handbook's acceptance gate is that home renders when one source fails. Failed sections are tracked in `failedSections` and each renders an inline notice with retry; only a total load failure shows the full error state.
5. **Retry reloads the whole summary.** Home is one aggregated read, so a section-level retry re-runs that read rather than introducing per-section fetches. Simpler, and the read is cheap.
6. **Deep links resolve in the router.** Cards call back to the router, which uses `DeepLinkResolver`, so an ineligible learner lands on Home with an explanation instead of a dead route. The page itself stays navigation-agnostic and testable.
7. **Independent learners use the senior composition.** `usesJuniorPresentation` is true only for juniors. Filling the school-only space with useful independent content is IND-01's job; this module simply omits Flex.
