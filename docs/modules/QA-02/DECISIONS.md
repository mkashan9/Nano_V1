# QA-02 — Decisions

1. **Executable smoke, not a profiler.** Budgets are documented pilot gates;
   measured first-frame is optional.
2. **360px floor.** `PerformanceViewports.smallPhoneWidth` matches
   `NanoBreakpoints.smallPhone`.
3. **Density rules shared.** Layout policy mirrors `NanoResponsive` junior /
   senior phone columns; a test asserts they stay aligned.
4. **Text scale 1.3 smoke.** Me page defaults to the handbook small-device /
   text-scaling smoke target.
5. **Warn vs fail.** Dense lists warn above 40 and fail above 80.
