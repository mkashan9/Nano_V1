# STU-03 — Decisions

1. **No database work in this module.** Home content depends on lessons, missions, and XP, which are owned by later modules. Per AGENTS.md (UI-first), the screen is built against `StudentHomeRepository` and served by a fake, so the live implementation is a drop-in later.
2. **One aggregated read.** The home takes a single `StudentHomeSummary` rather than several independent loads, which keeps the junior screen from showing a patchwork of spinners.
3. **Cache is a notice, not a block.** Cached data renders content with a "last updated" banner (`NanoViewOffline`); only maintenance blocks the screen. Access warnings are banners so a learner is never locked out mid-session.
4. **Mission cap lives in the domain.** `juniorMissions` truncates to three in the model, so any presentation reusing the summary inherits the junior rule.
5. **Progress and XP stay read-only on the client.** The home never writes scores; server authority is unchanged.
6. **Foundation kept as fallback.** `StudentLearningTab` still renders `JuniorHomeFoundation` when no repository is supplied, so gallery and preview paths keep working.
