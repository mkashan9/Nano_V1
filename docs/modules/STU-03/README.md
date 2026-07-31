# STU-03 — Junior Home

## Purpose

Give junior learners a home screen that answers three questions with almost no reading: what is waiting for me, what should I do next, and how am I doing. The composition is a few large actions instead of dense lists.

## Deliverables

- `StudentHomeSummary`, `ContinueLearningItem`, `HomeNoticeKind` domain models with junior mission capping and freshness labels
- `StudentHomeRepository` with `FakeStudentHomeRepository` (UI-first; live data arrives with the LRN/XP modules)
- `JuniorHomePage` mapping repository results to `NanoViewState`: loading, error with retry, empty, offline-with-timestamp, maintenance
- Greeting with companion slot, streak, XP chip, notification badge, continue-learning card, today's mission, subject grid
- Bilingual copy for the new home strings
- `StudentLearningTab` wires the page for junior roles and keeps `JuniorHomeFoundation` as the no-repository preview

## Owner test focus

Sign in as a junior learner, confirm the home shows a resumable lesson and three missions, tap through the large cards, then use the debug role switch to confirm senior still shows the senior foundation.
