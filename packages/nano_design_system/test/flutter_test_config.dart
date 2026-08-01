import 'dart:async';

import 'package:nano_design_system/nano_design_system.dart';

/// Ambient companion motion is off by default in tests (MED-10).
///
/// Nori breathes continuously, and a tree with a perpetual animation never
/// reaches a settled frame, so `pumpAndSettle` would hang in every test that
/// happens to have a companion on screen. Turning it off here keeps those tests
/// describing what they are actually about.
///
/// The tests that *are* about motion re-enable it for their own duration:
/// see `companion_local_animation_test.dart` and
/// `companion_reduced_motion_test.dart`.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  NoriLivingArt.debugAmbientMotionEnabled = false;
  await testMain();
}
