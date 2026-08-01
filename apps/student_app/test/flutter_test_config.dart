import 'dart:async';

import 'package:nano_design_system/nano_design_system.dart';

/// Ambient companion motion is off by default in tests (MED-10).
///
/// Nori breathes continuously, and a tree with a perpetual animation never
/// reaches a settled frame, so `pumpAndSettle` would hang in every test that
/// happens to have a companion on screen. The motion itself is covered by the
/// design system's own tests, which turn it back on deliberately.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  NoriLivingArt.debugAmbientMotionEnabled = false;
  await testMain();
}
