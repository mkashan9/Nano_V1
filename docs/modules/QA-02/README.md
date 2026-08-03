# QA-02 — Performance and Small-Device Testing

## Purpose

Encode pilot smoke budgets for small phones (360px), junior/senior column
density, text-scale 1.3, and dense-list / first-frame targets — as an
executable checklist learners can open from Me.

## Deliverables

- Domain: `PerformanceAuditPolicy`, `PerformanceViewports`, layout budgets
- Fake `PerformanceAuditRepository`
- Me → **Performance & small device** smoke page
- Widget smoke at 360×640 with textScale 1.3

## Does not own

- Real device profiling / CI benchmark farms
- Offline/poor-network matrices (QA-03)
- Full accessibility audit (QA-04)

## Owner test focus

Me → Performance & small device → All performance checks passed on a narrow
phone-width preview.
