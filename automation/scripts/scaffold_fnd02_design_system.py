"""Generate nano_design_system FND-02 tokens, themes, components, gallery, tests."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(r"d:\nano")
PKG = ROOT / "packages" / "nano_design_system"


def w(rel: str, content: str) -> None:
    path = PKG / rel if not rel.startswith("apps/") else ROOT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content.strip() + "\n", encoding="utf-8")


def main() -> None:
    # ---- barrel ----
    w(
        "lib/nano_design_system.dart",
        """
export 'src/tokens/nano_breakpoints.dart';
export 'src/tokens/nano_colors.dart';
export 'src/tokens/nano_elevation.dart';
export 'src/tokens/nano_motion.dart';
export 'src/tokens/nano_radii.dart';
export 'src/tokens/nano_spacing.dart';
export 'src/tokens/nano_typography.dart';
export 'src/theme/nano_theme.dart';
export 'src/theme/nano_theme_extension.dart';
export 'src/theme/school_branding.dart';
export 'src/components/nano_scaffold.dart';
export 'src/components/cards/junior_action_card.dart';
export 'src/components/cards/senior_progress_card.dart';
export 'src/components/cards/admin_metric_card.dart';
export 'src/components/cards/teacher_task_card.dart';
export 'src/components/states/nano_loading_state.dart';
export 'src/components/states/nano_empty_state.dart';
export 'src/components/states/nano_error_state.dart';
export 'src/components/states/nano_offline_banner.dart';
export 'src/components/states/nano_suspended_state.dart';
export 'src/components/companion_slot.dart';
export 'src/components/xp_chip.dart';
export 'src/components/environment_badge.dart';
export 'src/responsive/nano_page_padding.dart';
""",
    )

    w(
        "lib/src/tokens/nano_spacing.dart",
        """
/// 4-point spacing scale.
abstract final class NanoSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
  static const double pageGutterJunior = 20;
  static const double pageGutterSenior = 16;
  static const double pageGutterAdmin = 24;
  static const double cardPaddingJunior = 20;
  static const double cardPaddingSenior = 16;
  static const double listGapJunior = 16;
  static const double listGapSenior = 12;
}
""",
    )

    w(
        "lib/src/tokens/nano_radii.dart",
        """
import 'package:flutter/material.dart';

abstract final class NanoRadii {
  static const double junior = 28;
  static const double senior = 20;
  static const double admin = 12;
  static const double pill = 999;
  static const double avatar = 999;
  static const double sheet = 24;

  static BorderRadius juniorCard = BorderRadius.circular(junior);
  static BorderRadius seniorCard = BorderRadius.circular(senior);
  static BorderRadius adminCard = BorderRadius.circular(admin);
}
""",
    )

    w(
        "lib/src/tokens/nano_motion.dart",
        """
abstract final class NanoMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Curve standard = Curves.easeInOut;
  static const Duration companionCooldown = Duration(seconds: 8);
}

// ignore: depend_on_referenced_packages
import 'package:flutter/animation.dart';
""",
    )

    # Fix motion import order - rewrite properly
    w(
        "lib/src/tokens/nano_motion.dart",
        """
import 'package:flutter/animation.dart';

abstract final class NanoMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Curve standard = Curves.easeInOut;
  static const Duration companionCooldown = Duration(seconds: 8);
}
""",
    )

    w(
        "lib/src/tokens/nano_elevation.dart",
        """
abstract final class NanoElevation {
  static const double card = 0;
  static const double dialog = 8;
  static const double sticky = 4;
  static const double sidebar = 2;
}
""",
    )

    w(
        "lib/src/tokens/nano_breakpoints.dart",
        """
abstract final class NanoBreakpoints {
  static const double smallPhone = 360;
  static const double largePhone = 430;
  static const double tablet = 768;
  static const double narrowWeb = 1024;
  static const double desktop = 1280;
  static const double wideDesktop = 1440;

  static bool isPhone(double width) => width < tablet;
  static bool isTablet(double width) => width >= tablet && width < narrowWeb;
  static bool isDesktop(double width) => width >= narrowWeb;
}
""",
    )

    w(
        "lib/src/tokens/nano_colors.dart",
        """
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
""",
    )

    w(
        "lib/src/tokens/nano_typography.dart",
        """
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
        fontFamily: family,
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
""",
    )

    w(
        "lib/src/theme/school_branding.dart",
        """
import 'package:flutter/material.dart';
import '../tokens/nano_colors.dart';

/// Approved brand slots only — cannot override safety or contrast-critical colors.
class SchoolBranding {
  const SchoolBranding({
    this.primary,
    this.secondary,
    this.logoAsset,
    this.displayName,
  });

  final Color? primary;
  final Color? secondary;
  final String? logoAsset;
  final String? displayName;

  Color get safePrimary => primary ?? NanoColors.brandPrimary;
  Color get safeSecondary => secondary ?? NanoColors.brandSecondary;

  /// Safety colors always come from NanoColors.
  Color get success => NanoColors.success;
  Color get warning => NanoColors.warning;
  Color get error => NanoColors.error;
}
""",
    )

    w(
        "lib/src/theme/nano_theme_extension.dart",
        """
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
""",
    )

    w(
        "lib/src/theme/nano_theme.dart",
        """
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
""",
    )

    # Components
    w(
        "lib/src/responsive/nano_page_padding.dart",
        """
import 'package:flutter/material.dart';
import '../theme/nano_theme_extension.dart';
import '../tokens/nano_breakpoints.dart';

class NanoPagePadding extends StatelessWidget {
  const NanoPagePadding({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final nano = Theme.of(context).nano;
    final width = MediaQuery.sizeOf(context).width;
    final extra = NanoBreakpoints.isDesktop(width) ? 24.0 : 0.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: nano.pageGutter + extra),
      child: child,
    );
  }
}
""",
    )

    w(
        "lib/src/components/nano_scaffold.dart",
        """
import 'package:flutter/material.dart';
import '../responsive/nano_page_padding.dart';

class NanoScaffold extends StatelessWidget {
  const NanoScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.padBody = true,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool padBody;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: padBody ? NanoPagePadding(child: body) : body,
    );
  }
}
""",
    )

    w(
        "lib/src/components/environment_badge.dart",
        """
import 'package:flutter/material.dart';

class NanoEnvironmentBadge extends StatelessWidget {
  const NanoEnvironmentBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}
""",
    )

    w(
        "lib/src/components/xp_chip.dart",
        """
import 'package:flutter/material.dart';
import '../tokens/nano_colors.dart';
import '../tokens/nano_radii.dart';
import '../tokens/nano_spacing.dart';

class XpChip extends StatelessWidget {
  const XpChip({super.key, required this.xp, this.label = 'XP'});

  final int xp;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '\$xp \$label',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: NanoSpacing.sm,
          vertical: NanoSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: NanoColors.canvasElevated,
          borderRadius: BorderRadius.circular(NanoRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: NanoColors.warning, size: 18),
            const SizedBox(width: NanoSpacing.xxs),
            Text(
              '\$xp',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}
""",
    )

    w(
        "lib/src/components/companion_slot.dart",
        """
import 'package:flutter/material.dart';
import '../tokens/nano_spacing.dart';

/// Layout-stable companion slot — static, animated, clip, or empty.
class CompanionSlot extends StatelessWidget {
  const CompanionSlot({
    super.key,
    this.child,
    this.size = 96,
    this.semanticLabel = 'Learning guide',
  });

  final Widget? child;
  final double size;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: SizedBox(
        width: size,
        height: size,
        child: child ??
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pets_rounded, size: NanoSpacing.xl),
            ),
      ),
    );
  }
}
""",
    )

    w(
        "lib/src/components/cards/junior_action_card.dart",
        """
import 'package:flutter/material.dart';
import '../../theme/nano_theme_extension.dart';
import '../../tokens/nano_spacing.dart';

class JuniorActionCard extends StatelessWidget {
  const JuniorActionCard({
    super.key,
    required this.title,
    required this.backgroundColor,
    this.subtitle,
    this.onTap,
    this.illustration,
  });

  final String title;
  final String? subtitle;
  final Color backgroundColor;
  final VoidCallback? onTap;
  final Widget? illustration;

  @override
  Widget build(BuildContext context) {
    final nano = Theme.of(context).nano;
    return Semantics(
      button: onTap != null,
      label: title,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(nano.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(nano.cardRadius),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: nano.minTapTarget * 2.2),
            child: Padding(
              padding: EdgeInsets.all(nano.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (illustration != null) ...[
                    illustration!,
                    const SizedBox(height: NanoSpacing.sm),
                  ],
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
""",
    )

    w(
        "lib/src/components/cards/senior_progress_card.dart",
        """
import 'package:flutter/material.dart';
import '../../theme/nano_theme_extension.dart';
import '../../tokens/nano_colors.dart';
import '../../tokens/nano_spacing.dart';

class SeniorProgressCard extends StatelessWidget {
  const SeniorProgressCard({
    super.key,
    required this.title,
    required this.progress,
    this.tag,
    this.meta,
    this.onTap,
  });

  final String title;
  final double progress;
  final String? tag;
  final String? meta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nano = Theme.of(context).nano;
    final clamped = progress.clamp(0.0, 1.0);
    return Semantics(
      button: onTap != null,
      label: '\$title, \${(clamped * 100).round()} percent complete',
      child: Material(
        color: NanoColors.surfaceCard,
        borderRadius: BorderRadius.circular(nano.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(nano.cardRadius),
          child: Padding(
            padding: EdgeInsets.all(nano.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tag != null)
                  Text(
                    tag!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: NanoColors.brandPrimarySoft,
                        ),
                  ),
                const SizedBox(height: NanoSpacing.xxs),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (meta != null) ...[
                  const SizedBox(height: NanoSpacing.xxs),
                  Text(meta!, style: Theme.of(context).textTheme.bodyMedium),
                ],
                const SizedBox(height: NanoSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: clamped,
                    minHeight: 8,
                    backgroundColor: NanoColors.canvasElevated,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
""",
    )

    w(
        "lib/src/components/cards/admin_metric_card.dart",
        """
import 'package:flutter/material.dart';
import '../../theme/nano_theme_extension.dart';
import '../../tokens/nano_colors.dart';
import '../../tokens/nano_spacing.dart';

class AdminMetricCard extends StatelessWidget {
  const AdminMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final nano = Theme.of(context).nano;
    return Semantics(
      label: '\$label \$value',
      child: Container(
        padding: EdgeInsets.all(nano.cardPadding),
        decoration: BoxDecoration(
          color: NanoColors.adminSurface,
          borderRadius: BorderRadius.circular(nano.cardRadius),
          border: Border.all(color: NanoColors.canvasElevated),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: NanoSpacing.xs),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
""",
    )

    w(
        "lib/src/components/cards/teacher_task_card.dart",
        """
import 'package:flutter/material.dart';
import '../../theme/nano_theme_extension.dart';
import '../../tokens/nano_colors.dart';
import '../../tokens/nano_spacing.dart';

class TeacherTaskCard extends StatelessWidget {
  const TeacherTaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nano = Theme.of(context).nano;
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(nano.cardRadius),
      ),
      tileColor: NanoColors.adminSurface,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      contentPadding: EdgeInsets.symmetric(
        horizontal: nano.cardPadding,
        vertical: NanoSpacing.xs,
      ),
    );
  }
}
""",
    )

    for name, title, icon, color in [
        ("nano_loading_state", "Loading", "Icons.hourglass_top_rounded", "null"),
        ("nano_empty_state", "Nothing here yet", "Icons.inbox_outlined", "null"),
        ("nano_error_state", "Something went wrong", "Icons.error_outline", "NanoColors.error"),
        ("nano_suspended_state", "Account paused", "Icons.pause_circle_outline", "NanoColors.suspended"),
    ]:
        pass

    w(
        "lib/src/components/states/nano_loading_state.dart",
        """
import 'package:flutter/material.dart';
import '../../tokens/nano_spacing.dart';

class NanoLoadingState extends StatelessWidget {
  const NanoLoadingState({super.key, this.message = 'Loading'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: NanoSpacing.md),
          Text(message, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
""",
    )

    w(
        "lib/src/components/states/nano_empty_state.dart",
        """
import 'package:flutter/material.dart';
import '../../tokens/nano_spacing.dart';

class NanoEmptyState extends StatelessWidget {
  const NanoEmptyState({
    super.key,
    this.title = 'Nothing here yet',
    this.message = 'Check back soon.',
    this.action,
  });

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NanoSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 48),
            const SizedBox(height: NanoSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: NanoSpacing.xs),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: NanoSpacing.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
""",
    )

    w(
        "lib/src/components/states/nano_error_state.dart",
        """
import 'package:flutter/material.dart';
import '../../tokens/nano_colors.dart';
import '../../tokens/nano_spacing.dart';

class NanoErrorState extends StatelessWidget {
  const NanoErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.message = 'Please try again.',
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NanoSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: NanoColors.error),
            const SizedBox(height: NanoSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: NanoSpacing.xs),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: NanoSpacing.md),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}
""",
    )

    w(
        "lib/src/components/states/nano_offline_banner.dart",
        """
import 'package:flutter/material.dart';
import '../../tokens/nano_colors.dart';
import '../../tokens/nano_spacing.dart';

class NanoOfflineBanner extends StatelessWidget {
  const NanoOfflineBanner({
    super.key,
    this.message = 'You are offline. Changes will sync when you reconnect.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: NanoColors.offline.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: NanoSpacing.md,
          vertical: NanoSpacing.sm,
        ),
        child: Row(
          children: [
            const Icon(Icons.wifi_off, color: NanoColors.offline),
            const SizedBox(width: NanoSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
""",
    )

    w(
        "lib/src/components/states/nano_suspended_state.dart",
        """
import 'package:flutter/material.dart';
import '../../tokens/nano_colors.dart';
import '../../tokens/nano_spacing.dart';

class NanoSuspendedState extends StatelessWidget {
  const NanoSuspendedState({
    super.key,
    this.title = 'Access paused',
    this.message = 'This account or school is temporarily suspended.',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NanoSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.pause_circle_outline,
              size: 48,
              color: NanoColors.suspended,
            ),
            const SizedBox(height: NanoSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: NanoSpacing.xs),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
""",
    )

    # Tests
    w(
        "test/nano_theme_test.dart",
        """
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_design_system/nano_design_system.dart';

void main() {
  test('junior and senior themes expose extensions', () {
    expect(NanoTheme.junior().nano.isJunior, isTrue);
    expect(NanoTheme.senior().nano.isSenior, isTrue);
    expect(NanoTheme.teacher().nano.experience, NanoExperience.teacher);
    expect(NanoTheme.schoolAdmin().nano.experience, NanoExperience.schoolAdmin);
    expect(NanoTheme.superadmin().nano.experience, NanoExperience.superadmin);
  });

  test('school branding cannot override safety colors', () {
    const branding = SchoolBranding(primary: Color(0xFF123456));
    expect(branding.error, NanoColors.error);
    expect(branding.success, NanoColors.success);
    expect(branding.safePrimary, const Color(0xFF123456));
  });

  test('same domain title renders in junior and senior card variants', () {
    expect(JuniorActionCard(title: 'Math', backgroundColor: NanoColors.worldMath), isA<Widget>());
    expect(SeniorProgressCard(title: 'Math', progress: 0.5), isA<Widget>());
  });
}
""",
    )

    w(
        "test/component_golden_test.dart",
        """
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_design_system/nano_design_system.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpCard(WidgetTester tester, ThemeData theme, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(body: Center(child: SizedBox(width: 320, child: child))),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('junior action card golden', (tester) async {
    await pumpCard(
      tester,
      NanoTheme.junior(),
      JuniorActionCard(
        title: 'Math',
        subtitle: 'Play and learn',
        backgroundColor: NanoColors.worldMath,
      ),
    );
    await expectLater(
      find.byType(JuniorActionCard),
      matchesGoldenFile('goldens/junior_action_card.png'),
    );
  });

  testWidgets('senior progress card golden', (tester) async {
    await pumpCard(
      tester,
      NanoTheme.senior(),
      const SeniorProgressCard(
        title: 'Genetics: The Code of Life',
        tag: 'Science',
        progress: 0.65,
        meta: '45 min',
      ),
    );
    await expectLater(
      find.byType(SeniorProgressCard),
      matchesGoldenFile('goldens/senior_progress_card.png'),
    );
  });
}
""",
    )

    # Gallery in student app
    w(
        "apps/student_app/lib/app/component_gallery_page.dart",
        """
import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';

class ComponentGalleryPage extends StatefulWidget {
  const ComponentGalleryPage({super.key});

  @override
  State<ComponentGalleryPage> createState() => _ComponentGalleryPageState();
}

class _ComponentGalleryPageState extends State<ComponentGalleryPage> {
  bool senior = false;

  @override
  Widget build(BuildContext context) {
    final theme = senior ? NanoTheme.senior() : NanoTheme.junior();
    return Theme(
      data: theme,
      child: NanoScaffold(
        appBar: AppBar(
          title: const Text('Component gallery'),
          actions: [
            Row(
              children: [
                Text(senior ? 'Senior' : 'Junior'),
                Switch(
                  value: senior,
                  onChanged: (v) => setState(() => senior = v),
                ),
              ],
            ),
          ],
        ),
        body: ListView(
          children: [
            const SizedBox(height: NanoSpacing.md),
            const XpChip(xp: 560),
            const SizedBox(height: NanoSpacing.md),
            const CompanionSlot(),
            const SizedBox(height: NanoSpacing.md),
            if (!senior)
              JuniorActionCard(
                title: 'Math',
                subtitle: 'Numbers adventure',
                backgroundColor: NanoColors.worldMath,
                onTap: () {},
              )
            else
              const SeniorProgressCard(
                title: 'Genetics: The Code of Life',
                tag: 'Science',
                progress: 0.65,
                meta: '45 min',
              ),
            const SizedBox(height: NanoSpacing.md),
            const NanoOfflineBanner(),
            const SizedBox(height: NanoSpacing.xl),
            Text('States', style: theme.textTheme.titleLarge),
            const SizedBox(height: 120, child: NanoLoadingState()),
            const SizedBox(height: 160, child: NanoEmptyState()),
            SizedBox(
              height: 180,
              child: NanoErrorState(onRetry: () {}),
            ),
            const SizedBox(height: 160, child: NanoSuspendedState()),
            const SizedBox(height: NanoSpacing.xl),
            AdminMetricCard(
              label: 'Active schools',
              value: '12',
              icon: Icons.school_outlined,
            ),
            const SizedBox(height: NanoSpacing.md),
            TeacherTaskCard(
              title: 'Take attendance',
              subtitle: 'Class 5-A · Today',
              onTap: () {},
            ),
            const SizedBox(height: NanoSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
""",
    )

    print("FND-02 design system files written")


if __name__ == "__main__":
    main()
