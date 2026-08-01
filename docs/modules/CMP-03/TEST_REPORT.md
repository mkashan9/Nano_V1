# CMP-03 test report

Date: 2026-08-01

## Automated

| Suite | Command | Result |
|-------|---------|--------|
| Domain | `dart test packages/nano_domain` | 198 passed (7 new placement tests) |
| Design system | `flutter test packages/nano_design_system` | 41 passed (13 new controller/scope tests) |
| Student app | `flutter test apps/student_app` | 113 passed (5 new placement wiring tests) |
| Static analysis | `dart analyze` | No new findings; 16 pre-existing issues unchanged |

### New coverage

`packages/nano_domain/test/companion_placement_test.dart`

- Junior leads on home, learning, and onboarding; Senior stays aside
- A quiz keeps the companion inline in both experiences
- Social and settings carry no companion in either experience
- Every surface resolves in both experiences (no missing cases)
- Junior is never quieter than Senior on the same surface
- `hidden` is the only placement that renders nothing

`packages/nano_design_system/test/companion_controller_test.dart`

- A cooldown survives moving between surfaces, and expires on time
- The appearance budget is shared across surfaces and reset by `endSession`
- Only the surface in front is current; re-entering the same one keeps the line
- A long gap on resume is greeted; a short gap is not
- Preference changes reach the live controller (a muted reaction stops speaking)
- A suppressed moment notifies nobody, so nothing rebuilds
- The scope shares one controller; dismissal clears the stage
- A hidden surface neither renders nor spends budget
- Senior home entry stays quiet while Junior home greets
- Placement decides art size, and Senior's is smaller than Junior's

`apps/student_app/test/companion_placement_wiring_test.dart`

- Junior home leads with a hero-sized Guide companion
- Senior home is not greeted on an ordinary visit
- A resume after hours is greeted on Senior home, at aside size
- The progress empty state carries a companion instead of a blank panel
- Classroom Mode leaves the home layout intact and quiet

## Not run

- Real-device lifecycle test for the 30-minute return (covered by the injected
  clock in `companion_controller_test.dart`)
- Golden images: art is still the FND-03 placeholder, so goldens wait for MED-01

## Security

- No secrets touched; no network calls added. The companion reads no learner data
  beyond the display name and preferences already in the session.
