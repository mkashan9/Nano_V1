import 'package:flutter/animation.dart';

abstract final class NanoMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Curve standard = Curves.easeInOut;
  static const Duration companionCooldown = Duration(seconds: 8);
}
