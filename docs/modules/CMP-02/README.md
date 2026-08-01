# CMP-02 — Nori Modes and Reaction Rules

## Purpose

Turn the one companion into controlled variants without letting it become five
characters, and put a rule book around when it may speak at all. A mode changes
the accent, the emblem, and (rarely) the framing; the face, the voice, the
caption design, and the wording stay shared.

## Deliverables

| Area | What shipped |
|------|--------------|
| Domain | `CompanionSurface`, `CompanionMode` (guide, explorer, quiz coach, builder, celebration), `CompanionPresentation` |
| Domain | `CompanionRules`: session budget, story-card selection, collision priorities |
| Domain | `CompanionRuntime` gains `surface`, `shownThisSession`, `notifyFirstOf`, `newSession`, `withSurface`, and `skipReason` |
| Copy | `companionModeLabel` / `companionModeBadge` / `companionDismissLabel` in English and Urdu |
| Design system | `CompanionModeTheme` (accent + emblem per mode) and a story-card presentation inside `CompanionStage` |
| Student app | Quiz results run as Quiz Coach Nori; the onboarding welcome is a framed story card; the gallery shows every mode |
| Tests | Domain mode/rule tests, design-system frame tests, student-app wiring tests |

## Rules

- **Mode comes from the surface, mood from the event.** Quiz Coach Nori can
  celebrate a pass without becoming Celebration Nori. A level-up or achievement
  is Celebration Nori on any surface; a new world is an Explorer reveal.
- **One identity.** All modes share the script book, so the wording cannot drift
  between variants, and each reaction names itself ("Nori · Quiz coach") so the
  mode is never carried by colour alone.
- **Story cards are rare.** Only the onboarding welcome, a new world, and a level
  milestone get the framed treatment; everything else is inline.
- **Collisions resolve by priority.** Essential outcome (100) beats a story card
  (80), which beats ordinary guidance (50), which beats idle (10). Ties keep the
  caller's order, so the same pair always resolves the same way.
- **A session has a budget.** Junior allows 6 ordinary appearances, Senior 3.
  Essential moments are exempt and do not spend the budget; `newSession()` starts
  the budget and the cooldowns over.
- **Classroom Mode means essential only.** Ordinary guidance is held back
  entirely (and does not spend budget); an outcome still arrives, silent and
  static.
- `skipReason` names which rule fired, so suppression is testable and
  debuggable rather than an invisible no-op.

## Out of scope

- Real per-mode art and animation, and the Aoede voice (MED-01/MED-03)
- Generated story-card clips, provenance, and budget (MED-02)
- A companion holder that persists cooldowns and budget across routes and
  restarts
- Seasonal or story-arc modes beyond the four the handbook names
