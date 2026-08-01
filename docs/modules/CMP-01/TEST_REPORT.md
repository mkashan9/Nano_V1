# CMP-01 test report

## Automated

| Suite | Result |
|-------|--------|
| `packages/nano_domain/test/companion_runtime_test.dart` | 18 passed |
| `packages/nano_design_system/test/companion_stage_test.dart` | 7 passed |
| `apps/student_app/test/companion_reaction_test.dart` | 5 passed |
| `packages/nano_domain` suite | 168 passed |
| `packages/nano_design_system` suite | 21 passed |
| `apps/student_app` suite | 104 passed |

## What the tests pin

| Behaviour | Check |
|-----------|-------|
| Deterministic selection | same event + seed gives the same script and asset key |
| Every moment is covered | all `CompanionEvent` values resolve to a mood with a caption |
| Server authority | `forOutcome(passed:)` maps to celebration / gentle retry; no score math exists |
| Cooldowns | an ordinary moment is suppressed until the window passes; essential outcomes never are |
| Dismissal | clears the reaction, keeps the cooldown |
| Senior density | home, learning entry, per-question, and idle produce nothing; results are small |
| Muted sound | voice off, caption kept |
| Classroom Mode | voice off and static art even with sound enabled |
| Captions off | art still shown, no caption |
| Offline availability | a clip-tier mood falls back to a local tier; an empty manifest still resolves to static art |

## Server checks

None. CMP-01 adds no tables, policies, or functions — the module runs entirely on
device, which is the acceptance gate the handbook sets for the companion.

## Security notes

No secrets, no network calls, no provider keys. The runtime reads only
`AccessibilityPreferences` and the event a surface reports, and it cannot
influence scores, XP, or eligibility because it performs no arithmetic and writes
nothing.
