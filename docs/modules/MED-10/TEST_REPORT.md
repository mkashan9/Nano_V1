# MED-10 test report

## Automated

| Suite | Result |
|-------|--------|
| `packages/nano_design_system` | 88 passed |
| `packages/nano_domain` | 235 passed |
| `apps/student_app` | 130 passed |
| `apps/admin_web` | 22 passed |
| `flutter analyze` (workspace) | 16 issues, all pre-existing, none in changed files |

## New tests

`packages/nano_design_system/test/companion_local_animation_test.dart`

- Every mood has a signature and none of them is still.
- No channel exceeds its ceiling — 4% breath, 4% bob, 2% sway. This is the test
  that stops a future "make it livelier" tweak turning the companion into a
  distraction, because the ceiling is asserted rather than remembered.
- The six signatures are all distinct from one another, so no two moods
  accidentally collapse into the same movement.
- Gentle retry is slower and smaller than celebration on every channel, and its
  sway is exactly zero.
- The transform actually changes over successive frames. Without this the whole
  file could pass against a widget that applies a constant transform and never
  animates.
- The composed scale never drops below 1.0 for any mood at any point in a
  three-second sample, so motion can never pull an empty crescent into the
  circular mask.
- A clip that is playing gets no transform: it has its own motion.
- The `CompanionSlot` rect is byte-identical before and after 700ms of motion,
  which is the tap-target guarantee.
- Under `TickerMode(enabled: false)` the transform does not change across two
  seconds — the off-screen and backgrounded case.

`packages/nano_design_system/test/companion_reduced_motion_test.dart`

The file that matters most. It opens with a control case asserting the default
*does* move, because every assertion after it is a negative and negatives pass
for free against a widget that never animated.

- Reduced motion stops it completely, and is still stopped a second later.
- Classroom Mode stops it without `reducedMotion` being set.
- `MediaQuery.disableAnimations` stops it even when the app's own preference is
  default, for a learner who set it at the OS level and never opened our
  settings screen.
- Every mood is silenced, not just the loud one.
- The drawing is still on screen. Stopping motion must not cost the companion.

## Harness change

`test/flutter_test_config.dart` added to `nano_design_system` and `student_app`.

Wiring in a perpetual animation broke 25 existing tests at once — none of them
because anything was wrong. `pumpAndSettle` waits for a settled frame and a
breathing companion never produces one. The config file turns ambient motion
off once per package; the two files above turn it back on for themselves.

Side effect worth noting: the design system suite got faster, from about 50
seconds to 19, because tests that were previously waiting out companion
entrance animations no longer do.

## Not covered by automation

- Whether the motion is pleasant. A test can assert that celebration is
  springier than gentle retry; it cannot assert that either one looks right.
- Whether Nori becomes annoying after a minute of being ignored. This is the
  main thing the manual test is for.
- Resume-after-background smoothness on a real device. The `TickerMode` test
  covers the mechanism, not the feel.
