import 'package:flutter/material.dart';

/// Placeholder tokens — FND-02 owns the full design system.
class NanoColors {
  static const Color brandPrimary = Color(0xFF0B6E4F);
  static const Color brandSecondary = Color(0xFF08A045);
  static const Color surface = Color(0xFFF7FBF8);
}

class NanoTheme {
  static ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: NanoColors.brandPrimary,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }
}
