# CMP-02 test report

## Automated

| Suite | Result |
|-------|--------|
| `packages/nano_domain/test/companion_modes_test.dart` | 23 passed |
| `packages/nano_design_system/test/companion_mode_frame_test.dart` | 7 passed |
| `apps/student_app/test/companion_modes_wiring_test.dart` | 4 passed |
| `packages/nano_domain` suite | 191 passed |
| `packages/nano_data` suite | 72 passed |
| `packages/nano_design_system` suite | 28 passed |
| `apps/student_app` suite | 108 passed |

## What the tests pin

| Behaviour | Check |
|-----------|-------|
| Mode from surface | learning → explorer, quiz → quiz coach, game → builder, else guide |
| Mode ≠ mood | a quiz pass is `celebration` mood in `quizCoach` mode |
| Milestone override | level-up is Celebration Nori on every surface |
| New world | Explorer reveal with a pointing mood, not a celebration |
| One identity | the same event produces the same caption on every surface |
| Asset key | mode is part of the key, so two modes cannot share art by accident |
| Story-card rarity | onboarding welcome, new world, and level-up only; app open elsewhere is inline |
| Collision order | outcome > story card > guidance > idle, ties keep caller order |
| Session budget | junior 6 / senior 3 ordinary appearances, then `sessionBudget` skips |
| Budget exemption | an essential outcome passes a spent budget and does not spend it |
| New session | budget and cooldowns reset, reaction cleared |
| Classroom Mode | ordinary guidance held back, outcome still delivered silent and static, nothing spent |
| Skip reasons | quiet-for-experience, cooldown, classroom mode, session budget each reported |
| Shared frame | modes differ in accent and emblem only; slot size and caption style match |
| Localisation | mode labels render in Urdu |
| Wiring | quiz results are Quiz Coach inline; onboarding welcome is a story card; a renamed companion is named in its badge |

## Server checks

None. CMP-02 adds no tables, policies, or functions; modes and rules are resolved
on device.

## Security notes

No secrets, no network calls, no provider keys. The runtime still performs no
arithmetic and writes nothing, so adding modes and rules cannot affect scores,
XP, or eligibility. Mode labels are the only new user-visible strings and they are
localized copy, not data.
