# STU-04 — Senior Home

## Purpose

The senior counterpart to STU-03. Same aggregated summary, denser composition: where the junior home gives one obvious next action, the senior home shows standing (level, XP progress, streak), the latest relevant update, what to continue, the full day's plan, and a Flex snapshot for school-eligible learners.

## Deliverables

- Domain additions on `StudentHomeSummary`: `LevelProgress` derived from XP, `FlexSummary`, `HomeUpdate`, and `HomeSection` failure tracking
- `StudentHomeRepository.loadHome` takes `flexEligible`, so Flex data is a server entitlement rather than a UI decision
- `FakeStudentHomeRepository` can fail individual sections while the rest of the home loads
- `SeniorHomePage`: level bar with XP-to-next, streak, notifications, latest update, continue card, Flex summary, Today's Plan, subject grid
- Per-section inline notices with retry, so one broken source never blanks the screen
- Flex card deep-links through `DeepLinkResolver`, falling back to Home with a message when the learner is not eligible
- Bilingual copy for level, plan, Flex, and section-failure strings

## Owner test focus

Sign in as a senior school learner: confirm the level line and XP bar, the Flex card, and the full plan. Then switch to the Independent persona and confirm there is no Flex card anywhere on Home.
