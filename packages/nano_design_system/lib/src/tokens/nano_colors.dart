import 'package:flutter/material.dart';

/// Palette derived from UI_reference Junior/Senior mockups (dark navy worlds).
/// Safety colors are fixed and cannot be overridden by school branding.
abstract final class NanoColors {
  // Canvas
  static const Color canvas = Color(0xFF0A0C1B);
  static const Color canvasElevated = Color(0xFF14162A);
  static const Color surfaceCard = Color(0xFF1A1D33);

  // Brand / accents from references
  static const Color brandPrimary = Color(0xFF7B5CFF);
  static const Color brandPrimarySoft = Color(0xFF9B7BFF);
  static const Color brandSecondary = Color(0xFF3D8BFF);

  // Subject worlds (Junior tiles)
  static const Color worldMath = Color(0xFF2F7BFF);
  static const Color worldEnglish = Color(0xFF2FBF71);
  static const Color worldScience = Color(0xFFFF8A3D);
  static const Color worldStories = Color(0xFFFF4F9A);
  static const Color worldHistory = Color(0xFFFF8A3D);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB7B9C9);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // Safety — not overridable
  static const Color success = Color(0xFF2FBF71);
  static const Color warning = Color(0xFFFFC53D);
  static const Color error = Color(0xFFFF4D6D);
  static const Color offline = Color(0xFFFF8A3D);
  static const Color suspended = Color(0xFFFF4D6D);

  // Admin / teacher denser surfaces (still dark-aligned for consistency)
  static const Color adminCanvas = Color(0xFF0E1117);
  static const Color adminSurface = Color(0xFF161B22);
  static const Color teacherAccent = Color(0xFF3D8BFF);
  static const Color superadminAccent = Color(0xFF7B5CFF);
}
