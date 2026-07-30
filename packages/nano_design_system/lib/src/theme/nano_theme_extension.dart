import 'package:flutter/material.dart';
import 'school_branding.dart';

enum NanoExperience {
  junior,
  senior,
  teacher,
  schoolAdmin,
  superadmin,
}

@immutable
class NanoThemeExtension extends ThemeExtension<NanoThemeExtension> {
  const NanoThemeExtension({
    required this.experience,
    required this.cardRadius,
    required this.pageGutter,
    required this.cardPadding,
    required this.minTapTarget,
    required this.branding,
  });

  final NanoExperience experience;
  final double cardRadius;
  final double pageGutter;
  final double cardPadding;
  final double minTapTarget;
  final SchoolBranding branding;

  bool get isJunior => experience == NanoExperience.junior;
  bool get isSenior => experience == NanoExperience.senior;

  @override
  NanoThemeExtension copyWith({
    NanoExperience? experience,
    double? cardRadius,
    double? pageGutter,
    double? cardPadding,
    double? minTapTarget,
    SchoolBranding? branding,
  }) {
    return NanoThemeExtension(
      experience: experience ?? this.experience,
      cardRadius: cardRadius ?? this.cardRadius,
      pageGutter: pageGutter ?? this.pageGutter,
      cardPadding: cardPadding ?? this.cardPadding,
      minTapTarget: minTapTarget ?? this.minTapTarget,
      branding: branding ?? this.branding,
    );
  }

  @override
  NanoThemeExtension lerp(ThemeExtension<NanoThemeExtension>? other, double t) {
    if (other is! NanoThemeExtension) return this;
    return t < 0.5 ? this : other;
  }
}

extension NanoThemeX on ThemeData {
  NanoThemeExtension get nano => extension<NanoThemeExtension>()!;
}
