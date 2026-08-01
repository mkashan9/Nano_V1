# CMP-03 — Junior and Senior Companion Placement

## Purpose

Put Nori on the learner's real screens at the density each experience deserves,
and give the session one owner so the rules from CMP-01 and CMP-02 actually hold
while a learner moves around the app. Before this module the runtime existed but
every screen decided for itself where a companion sat and how big it was, and a
cooldown reset the moment a route changed.

## Deliverables

| Area | What shipped |
|------|--------------|
| Domain | `CompanionPlacement` (hero, inline, aside, hidden) and `CompanionPlacementPolicy`: one table for surface × experience |
| Design system | `CompanionController` — the session-scoped owner of the runtime, and the only place that reads a clock |
| Design system | `NanoCompanionScope` so every surface shares that one controller |
| Design system | `CompanionSurfaceStage`: a screen states its surface and arrival moment; placement, mode, sizing, and suppression are decided for it |
| Design system | `CompanionStage` sizes art from placement (`artSizeFor`) instead of each page passing a number |
| Student app | Session controller in `main.dart`, kept in step with preferences and experience, and a resume hook for coming back |
| Student app | Junior/Senior home, the topic player, and the progress empty state placed through the shared controller |
| Tests | Placement table tests, controller/session tests, and student-app placement wiring tests |

## Rules

- **Placement is decided once, per surface and experience.** Junior leads with a
  hero companion on home, learning, and onboarding; Senior keeps it aside; a quiz
  keeps it inline for both. Social and settings carry none, in either experience.
  Junior is never quieter than Senior on the same surface — there is a test for
  that, so the table cannot drift.
- **One controller per session.** Cooldowns and the appearance budget survive
  navigation, because the runtime outlives the route. Signing out or switching
  experience starts a fresh session.
- **One companion at a time.** A stage renders only while its surface is the one
  in front, so a screen left behind a pushed route goes quiet instead of showing
  a stale line.
- **Screens report moments, they do not decide.** A page calls `report(...)` and
  the controller applies the quiet lists, cooldowns, budget, and Classroom Mode.
  A suppressed moment notifies nobody, so nothing rebuilds and nothing shifts.
- **The layout does not move when there is nothing to say.** The gap belongs to
  the companion, not the page, so a held-back reaction costs zero height.
- **The clock stays injectable.** The controller is the only companion code that
  reads time, and tests pass their own clock, so behaviour over an hour is a
  unit test rather than a wait.
- **Coming back is a moment; switching apps is not.** A resume after 30 minutes
  or more is greeted, anything shorter is ignored.
- **Senior home has no daily greeting.** Ordinary navigation stays quiet for
  Senior (CMP-01), so the Senior home placement exists for the moments that do
  earn a word — returning after a long absence, a milestone.

## Out of scope

- Real per-mode art, animation, and the Aoede voice (MED-01/MED-03)
- Persisting cooldowns and the session budget across app restarts
- Game and social surfaces, which have no screens yet
- Quiz results, which stay derived from the server's outcome rather than pushed
  through the session controller (see DECISIONS)
