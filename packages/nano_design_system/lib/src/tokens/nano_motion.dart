import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';
import 'package:nano_domain/nano_domain.dart';
import '../accessibility/nano_accessibility_scope.dart';

abstract final class NanoMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Curve standard = Curves.easeInOut;
  static const Duration companionCooldown = Duration(seconds: 8);

  /// Returns [Duration.zero] when reduced motion / classroom mode is active.
  static Duration resolve(
    BuildContext context,
    Duration preferred, {
    bool essential = false,
  }) {
    if (essential) return preferred;
    final prefs = NanoAccessibilityScope.maybeOf(context)?.preferences;
    final mediaReduced = MediaQuery.disableAnimationsOf(context);
    final prefsReduced = prefs?.effectiveReducedMotion ?? false;
    if (mediaReduced || prefsReduced) return Duration.zero;
    return preferred;
  }
}
