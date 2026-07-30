import 'package:flutter/material.dart';
import '../tokens/nano_colors.dart';
import '../tokens/nano_radii.dart';
import '../tokens/nano_spacing.dart';
import '../tokens/nano_typography.dart';
import 'nano_theme_extension.dart';
import 'school_branding.dart';

abstract final class NanoTheme {
  static ThemeData junior({SchoolBranding branding = const SchoolBranding()}) {
    return _build(
      experience: NanoExperience.junior,
      dense: false,
      cardRadius: NanoRadii.junior,
      pageGutter: NanoSpacing.pageGutterJunior,
      cardPadding: NanoSpacing.cardPaddingJunior,
      minTapTarget: 56,
      branding: branding,
    );
  }

  static ThemeData senior({SchoolBranding branding = const SchoolBranding()}) {
    return _build(
      experience: NanoExperience.senior,
      dense: true,
      cardRadius: NanoRadii.senior,
      pageGutter: NanoSpacing.pageGutterSenior,
      cardPadding: NanoSpacing.cardPaddingSenior,
      minTapTarget: 48,
      branding: branding,
    );
  }

  static ThemeData teacher({SchoolBranding branding = const SchoolBranding()}) {
    return _build(
      experience: NanoExperience.teacher,
      dense: true,
      cardRadius: NanoRadii.admin,
      pageGutter: NanoSpacing.pageGutterAdmin,
      cardPadding: NanoSpacing.md,
      minTapTarget: 48,
      branding: branding,
      accent: NanoColors.teacherAccent,
      canvas: NanoColors.adminCanvas,
      surface: NanoColors.adminSurface,
    );
  }

  static ThemeData schoolAdmin({SchoolBranding branding = const SchoolBranding()}) {
    return _build(
      experience: NanoExperience.schoolAdmin,
      dense: true,
      cardRadius: NanoRadii.admin,
      pageGutter: NanoSpacing.pageGutterAdmin,
      cardPadding: NanoSpacing.md,
      minTapTarget: 44,
      branding: branding,
      accent: branding.safePrimary,
      canvas: NanoColors.adminCanvas,
      surface: NanoColors.adminSurface,
    );
  }

  static ThemeData superadmin({SchoolBranding branding = const SchoolBranding()}) {
    return _build(
      experience: NanoExperience.superadmin,
      dense: true,
      cardRadius: NanoRadii.admin,
      pageGutter: NanoSpacing.pageGutterAdmin,
      cardPadding: NanoSpacing.md,
      minTapTarget: 44,
      branding: branding,
      accent: NanoColors.superadminAccent,
      canvas: NanoColors.adminCanvas,
      surface: NanoColors.adminSurface,
    );
  }

  /// Back-compat for FND-01 callers.
  static ThemeData light() => junior();

  static ThemeData _build({
    required NanoExperience experience,
    required bool dense,
    required double cardRadius,
    required double pageGutter,
    required double cardPadding,
    required double minTapTarget,
    required SchoolBranding branding,
    Color? accent,
    Color canvas = NanoColors.canvas,
    Color surface = NanoColors.surfaceCard,
  }) {
    final primary = accent ?? branding.safePrimary;
    final scheme = ColorScheme.dark(
      primary: primary,
      secondary: branding.safeSecondary,
      surface: surface,
      error: NanoColors.error,
      onPrimary: NanoColors.textOnAccent,
      onSecondary: NanoColors.textOnAccent,
      onSurface: NanoColors.textPrimary,
      onError: NanoColors.textOnAccent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      textTheme: NanoTypography.textTheme(dense: dense),
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: NanoColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: NanoTypography.textTheme(dense: dense).titleLarge,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(minTapTarget * 2, minTapTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NanoRadii.pill),
          ),
        ),
      ),
      extensions: [
        NanoThemeExtension(
          experience: experience,
          cardRadius: cardRadius,
          pageGutter: pageGutter,
          cardPadding: cardPadding,
          minTapTarget: minTapTarget,
          branding: branding,
        ),
      ],
    );
  }
}
