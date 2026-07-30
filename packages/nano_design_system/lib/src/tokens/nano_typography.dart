import 'package:flutter/material.dart';
import 'nano_colors.dart';

/// English-first typography with Urdu-ready font family slots.
abstract final class NanoTypography {
  static const String englishFamily = 'Nunito';
  static const String urduFamily = 'Noto Nastaliq Urdu';
  static const List<String> englishFallback = ['Segoe UI', 'Roboto', 'Arial'];
  static const List<String> urduFallback = ['Noto Nastaliq Urdu', 'Arial'];

  static TextTheme textTheme({required bool dense, String? localeTag}) {
    final isUrdu = (localeTag ?? '').toLowerCase().startsWith('ur');
    final family = isUrdu ? urduFamily : englishFamily;
    final fallback = isUrdu ? urduFallback : englishFallback;
    final scale = dense ? 0.92 : 1.0;

    TextStyle base(double size, FontWeight weight, {double height = 1.25}) {
      return TextStyle(
        fontFamily: isUrdu ? family : null,
        fontFamilyFallback: fallback,
        fontSize: size * scale,
        fontWeight: weight,
        height: height,
        color: NanoColors.textPrimary,
      );
    }

    return TextTheme(
      displayLarge: base(dense ? 32 : 36, FontWeight.w800),
      headlineMedium: base(dense ? 22 : 26, FontWeight.w700),
      titleLarge: base(dense ? 18 : 20, FontWeight.w700),
      titleMedium: base(dense ? 16 : 18, FontWeight.w600),
      bodyLarge: base(dense ? 15 : 16, FontWeight.w500, height: 1.4),
      bodyMedium: base(dense ? 13 : 14, FontWeight.w500, height: 1.4),
      labelLarge: base(dense ? 13 : 14, FontWeight.w700),
      labelSmall: base(12, FontWeight.w600, height: 1.2),
    );
  }
}
