import 'package:flutter/material.dart';
import 'package:nano_domain/nano_domain.dart';

import '../tokens/nano_colors.dart';

/// The visual half of a controlled variant (CMP-02).
///
/// A mode changes the accent and the emblem only. The frame, caption design,
/// entrance treatment, and the face itself are shared, which is what keeps five
/// modes reading as one companion.
class CompanionModeTheme {
  const CompanionModeTheme({
    required this.accent,
    required this.emblem,
  });

  final Color accent;
  final IconData emblem;

  static const _themes = <CompanionMode, CompanionModeTheme>{
    CompanionMode.guide: CompanionModeTheme(
      accent: NanoColors.brandPrimary,
      emblem: Icons.auto_awesome_rounded,
    ),
    CompanionMode.explorer: CompanionModeTheme(
      accent: NanoColors.worldScience,
      emblem: Icons.map_rounded,
    ),
    CompanionMode.quizCoach: CompanionModeTheme(
      accent: NanoColors.brandSecondary,
      emblem: Icons.school_rounded,
    ),
    CompanionMode.builder: CompanionModeTheme(
      accent: NanoColors.worldEnglish,
      emblem: Icons.construction_rounded,
    ),
    CompanionMode.celebration: CompanionModeTheme(
      accent: NanoColors.worldStories,
      emblem: Icons.emoji_events_rounded,
    ),
  };

  static CompanionModeTheme of(CompanionMode mode) =>
      _themes[mode] ?? _themes[CompanionMode.guide]!;
}
