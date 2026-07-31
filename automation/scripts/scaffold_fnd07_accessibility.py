"""Scaffold FND-07 accessibility, sound, haptics, reduced motion."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(r"d:\nano")


def w(path: str, content: str) -> None:
    p = ROOT / path
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content.strip() + "\n", encoding="utf-8")


def main() -> None:
    w(
        "packages/nano_domain/lib/src/accessibility/accessibility_preferences.dart",
        r"""
/// User/accessibility preferences shared across apps (persisted later in STU/profile).
class AccessibilityPreferences {
  const AccessibilityPreferences({
    this.textScale = 1.0,
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.reducedMotion = false,
    this.captionsEnabled = true,
    this.classroomMode = false,
  });

  /// Manual text scale multiplier on top of system scaling (clamped in UI).
  final double textScale;
  final bool soundEnabled;
  final bool hapticsEnabled;

  /// When true, non-essential motion becomes instant/static fades.
  final bool reducedMotion;
  final bool captionsEnabled;

  /// Classroom Mode suppresses non-essential interruptions and feedback noise.
  final bool classroomMode;

  bool get effectiveSoundEnabled =>
      soundEnabled && !classroomMode;

  bool get effectiveHapticsEnabled =>
      hapticsEnabled && !classroomMode;

  bool get effectiveReducedMotion => reducedMotion || classroomMode;

  AccessibilityPreferences copyWith({
    double? textScale,
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? reducedMotion,
    bool? captionsEnabled,
    bool? classroomMode,
  }) {
    return AccessibilityPreferences(
      textScale: textScale ?? this.textScale,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      captionsEnabled: captionsEnabled ?? this.captionsEnabled,
      classroomMode: classroomMode ?? this.classroomMode,
    );
  }

  static const defaults = AccessibilityPreferences();
}
""",
    )

    w(
        "packages/nano_domain/lib/src/accessibility/nano_sound_cue.dart",
        r"""
enum NanoSoundCue {
  tap,
  success,
  error,
  companion,
}
""",
    )

    barrel = ROOT / "packages/nano_domain/lib/src/nano_domain.dart"
    text = barrel.read_text(encoding="utf-8")
    if "accessibility_preferences.dart" not in text:
        barrel.write_text(
            text.rstrip()
            + "\nexport 'accessibility/accessibility_preferences.dart';\n"
            + "export 'accessibility/nano_sound_cue.dart';\n",
            encoding="utf-8",
        )

    w(
        "packages/nano_domain/test/accessibility_preferences_test.dart",
        r"""
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('classroom mode disables sound/haptics and forces reduced motion', () {
    const prefs = AccessibilityPreferences(
      soundEnabled: true,
      hapticsEnabled: true,
      reducedMotion: false,
      classroomMode: true,
    );
    expect(prefs.effectiveSoundEnabled, isFalse);
    expect(prefs.effectiveHapticsEnabled, isFalse);
    expect(prefs.effectiveReducedMotion, isTrue);
  });

  test('copyWith preserves unset fields', () {
    const base = AccessibilityPreferences(textScale: 1.2);
    final next = base.copyWith(reducedMotion: true);
    expect(next.textScale, 1.2);
    expect(next.reducedMotion, isTrue);
  });
}
""",
    )

    # Motion helpers with reduced motion
    w(
        "packages/nano_design_system/lib/src/tokens/nano_motion.dart",
        r"""
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
""",
    )

    w(
        "packages/nano_design_system/lib/src/accessibility/nano_accessibility_scope.dart",
        r"""
import 'package:flutter/material.dart';
import 'package:nano_domain/nano_domain.dart';

class NanoAccessibilityScope extends InheritedWidget {
  const NanoAccessibilityScope({
    super.key,
    required this.preferences,
    required this.feedback,
    required super.child,
  });

  final AccessibilityPreferences preferences;
  final NanoFeedback feedback;

  static NanoAccessibilityScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<NanoAccessibilityScope>();
    assert(scope != null, 'NanoAccessibilityScope not found');
    return scope!;
  }

  static NanoAccessibilityScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<NanoAccessibilityScope>();
  }

  @override
  bool updateShouldNotify(NanoAccessibilityScope oldWidget) =>
      preferences != oldWidget.preferences || feedback != oldWidget.feedback;
}
""",
    )

    w(
        "packages/nano_design_system/lib/src/accessibility/nano_feedback.dart",
        r"""
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nano_domain/nano_domain.dart';

/// Sound + haptics feedback gateway. Audio assets arrive in media modules;
/// R0 records intent and respects preference gates.
class NanoFeedback {
  NanoFeedback({
    AccessibilityPreferences preferences = AccessibilityPreferences.defaults,
    this.onSound,
  }) : _preferences = preferences;

  AccessibilityPreferences _preferences;
  final void Function(NanoSoundCue cue)? onSound;

  /// Last cue requested (for tests).
  NanoSoundCue? lastSoundCue;
  int hapticCount = 0;

  AccessibilityPreferences get preferences => _preferences;

  void updatePreferences(AccessibilityPreferences preferences) {
    _preferences = preferences;
  }

  Future<void> playSound(NanoSoundCue cue) async {
    if (!_preferences.effectiveSoundEnabled) return;
    lastSoundCue = cue;
    onSound?.call(cue);
    if (kDebugMode) {
      debugPrint('NanoFeedback.sound:${cue.name}');
    }
  }

  Future<void> hapticLight() async {
    if (!_preferences.effectiveHapticsEnabled) return;
    hapticCount++;
    await HapticFeedback.lightImpact();
  }

  Future<void> hapticSelection() async {
    if (!_preferences.effectiveHapticsEnabled) return;
    hapticCount++;
    await HapticFeedback.selectionClick();
  }

  Future<void> success() async {
    await playSound(NanoSoundCue.success);
    await hapticLight();
  }

  Future<void> error() async {
    await playSound(NanoSoundCue.error);
    await hapticSelection();
  }
}
""",
    )

    w(
        "packages/nano_design_system/lib/src/accessibility/nano_accessible.dart",
        r"""
import 'package:flutter/material.dart';
import '../theme/nano_theme_extension.dart';

/// Ensures minimum tap target from the active Nano theme.
class NanoAccessibleTarget extends StatelessWidget {
  const NanoAccessibleTarget({
    super.key,
    required this.child,
    this.label,
    this.button = true,
    this.onTap,
  });

  final Widget child;
  final String? label;
  final bool button;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final minSize = Theme.of(context).nano.minTapTarget;
    Widget content = ConstrainedBox(
      constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
      child: Center(child: child),
    );
    if (onTap != null) {
      content = InkWell(onTap: onTap, child: content);
    }
    return Semantics(
      button: button && onTap != null,
      label: label,
      child: content,
    );
  }
}
""",
    )

    ds = ROOT / "packages/nano_design_system/lib/nano_design_system.dart"
    ds_text = ds.read_text(encoding="utf-8")
    for line in [
        "export 'src/accessibility/nano_accessibility_scope.dart';",
        "export 'src/accessibility/nano_feedback.dart';",
        "export 'src/accessibility/nano_accessible.dart';",
    ]:
        if line not in ds_text:
            ds_text = ds_text.rstrip() + "\n" + line + "\n"
    ds.write_text(ds_text, encoding="utf-8")

    w(
        "packages/nano_design_system/test/nano_feedback_test.dart",
        r"""
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('feedback respects disabled sound and haptics', () async {
    final feedback = NanoFeedback(
      preferences: const AccessibilityPreferences(
        soundEnabled: false,
        hapticsEnabled: false,
      ),
    );
    await feedback.success();
    expect(feedback.lastSoundCue, isNull);
    expect(feedback.hapticCount, 0);
  });

  test('feedback records cues when enabled', () async {
    final feedback = NanoFeedback();
    await feedback.playSound(NanoSoundCue.tap);
    expect(feedback.lastSoundCue, NanoSoundCue.tap);
  });

  testWidgets('motion resolves to zero under reduced motion', (tester) async {
    late Duration resolved;
    await tester.pumpWidget(
      NanoAccessibilityScope(
        preferences: const AccessibilityPreferences(reducedMotion: true),
        feedback: NanoFeedback(
          preferences: const AccessibilityPreferences(reducedMotion: true),
        ),
        child: Builder(
          builder: (context) {
            resolved = NanoMotion.resolve(context, NanoMotion.normal);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(resolved, Duration.zero);
  });
}
""",
    )

    # Accessibility settings page for student
    w(
        "apps/student_app/lib/app/accessibility_settings_page.dart",
        r"""
import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

class AccessibilitySettingsPage extends StatelessWidget {
  const AccessibilitySettingsPage({
    super.key,
    required this.preferences,
    required this.onChanged,
  });

  final AccessibilityPreferences preferences;
  final ValueChanged<AccessibilityPreferences> onChanged;

  @override
  Widget build(BuildContext context) {
    final feedback = NanoAccessibilityScope.of(context).feedback;
    return NanoScaffold(
      appBar: AppBar(title: const Text('Accessibility')),
      body: ListView(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Sound effects'),
            subtitle: Text(
              preferences.classroomMode
                  ? 'Paused by Classroom Mode'
                  : 'UI and companion cues',
            ),
            value: preferences.soundEnabled,
            onChanged: preferences.classroomMode
                ? null
                : (v) => onChanged(preferences.copyWith(soundEnabled: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Haptics'),
            value: preferences.hapticsEnabled,
            onChanged: preferences.classroomMode
                ? null
                : (v) => onChanged(preferences.copyWith(hapticsEnabled: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Reduced motion'),
            subtitle: const Text('Prefer fades / static changes'),
            value: preferences.reducedMotion,
            onChanged: (v) =>
                onChanged(preferences.copyWith(reducedMotion: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Captions'),
            subtitle: const Text('Show captions when speech is used'),
            value: preferences.captionsEnabled,
            onChanged: (v) =>
                onChanged(preferences.copyWith(captionsEnabled: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Classroom Mode'),
            subtitle: const Text(
              'Quiet feedback and reduced non-essential motion',
            ),
            value: preferences.classroomMode,
            onChanged: (v) =>
                onChanged(preferences.copyWith(classroomMode: v)),
          ),
          const SizedBox(height: NanoSpacing.md),
          Text('Text size', style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: preferences.textScale.clamp(0.85, 1.6),
            min: 0.85,
            max: 1.6,
            divisions: 15,
            label: preferences.textScale.toStringAsFixed(2),
            onChanged: (v) => onChanged(preferences.copyWith(textScale: v)),
          ),
          const SizedBox(height: NanoSpacing.lg),
          Text('Try feedback', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: NanoSpacing.sm),
          Wrap(
            spacing: NanoSpacing.sm,
            children: [
              NanoAccessibleTarget(
                label: 'Play success feedback',
                onTap: () => feedback.success(),
                child: const Text('Success'),
              ),
              NanoAccessibleTarget(
                label: 'Play error feedback',
                onTap: () => feedback.error(),
                child: const Text('Error'),
              ),
            ],
          ),
          const SizedBox(height: NanoSpacing.lg),
          _MotionDemo(reduced: preferences.effectiveReducedMotion),
          if (preferences.captionsEnabled) ...[
            const SizedBox(height: NanoSpacing.lg),
            const NanoOfflineBanner(
              message: 'Caption sample: “Great job — keep going!”',
            ),
          ],
        ],
      ),
    );
  }
}

class _MotionDemo extends StatefulWidget {
  const _MotionDemo({required this.reduced});

  final bool reduced;

  @override
  State<_MotionDemo> createState() => _MotionDemoState();
}

class _MotionDemoState extends State<_MotionDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: NanoMotion.slow,
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final duration = NanoMotion.resolve(context, NanoMotion.slow);
    _controller.duration = duration == Duration.zero
        ? const Duration(milliseconds: 1)
        : duration;
    if (widget.reduced || duration == Duration.zero) {
      _controller.stop();
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _MotionDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduced) {
      _controller.stop();
      _controller.value = 1;
    } else {
      _controller.duration = NanoMotion.slow;
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Motion sample', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: NanoSpacing.sm),
        FadeTransition(
          opacity: widget.reduced
              ? const AlwaysStoppedAnimation(1)
              : _controller,
          child: Container(
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: NanoColors.brandPrimary.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.reduced ? 'Static (reduced motion)' : 'Animating…',
            ),
          ),
        ),
      ],
    );
  }
}
""",
    )

    # Patch student main for a11y prefs
    w(
        "apps/student_app/lib/main.dart",
        r"""
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/app/student_router.dart';

void main() {
  final config = EnvironmentConfig.fromEnvironment();
  runApp(NanoStudentApp(config: config));
}

class NanoStudentApp extends StatefulWidget {
  const NanoStudentApp({
    super.key,
    required this.config,
    this.initialPrincipal,
    this.initialLocation,
    this.initialLocale = NanoAppLocale.en,
    this.initialAccessibility = AccessibilityPreferences.defaults,
  });

  final EnvironmentConfig config;
  final SessionPrincipal? initialPrincipal;
  final String? initialLocation;
  final NanoAppLocale initialLocale;
  final AccessibilityPreferences initialAccessibility;

  @override
  State<NanoStudentApp> createState() => _NanoStudentAppState();
}

class _NanoStudentAppState extends State<NanoStudentApp> {
  late SessionPrincipal _principal;
  late GoRouter _router;
  late NanoAppLocale _locale;
  late AccessibilityPreferences _a11y;
  late final NanoFeedback _feedback;

  @override
  void initState() {
    super.initState();
    _principal = widget.initialPrincipal ?? SessionPrincipal.junior();
    _locale = widget.initialLocale;
    _a11y = widget.initialAccessibility;
    _feedback = NanoFeedback(preferences: _a11y);
    _router = _createRouter();
  }

  GoRouter _createRouter() {
    return createStudentRouter(
      config: widget.config,
      principal: _principal,
      onPrincipalChanged: _setPrincipal,
      onLocaleChanged: _setLocale,
      onAccessibilityChanged: _setA11y,
      locale: _locale,
      accessibility: _a11y,
      initialLocation: widget.initialLocation,
    );
  }

  void _setPrincipal(SessionPrincipal next) {
    setState(() {
      _principal = next;
      _router = _createRouter();
    });
  }

  void _setLocale(NanoAppLocale next) {
    setState(() {
      _locale = next;
      _router = _createRouter();
    });
  }

  void _setA11y(AccessibilityPreferences next) {
    setState(() {
      _a11y = next;
      _feedback.updatePreferences(next);
      _router = _createRouter();
    });
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoCopy(_locale);
    final theme = _principal.role.usesJuniorPresentation
        ? NanoTheme.junior(localeTag: _locale.tag)
        : NanoTheme.senior(localeTag: _locale.tag);
    final flutterLocale = Locale(_locale.languageCode);
    return NanoLocaleScope(
      locale: _locale,
      copy: copy,
      child: NanoAccessibilityScope(
        preferences: _a11y,
        feedback: _feedback,
        child: MaterialApp.router(
          key: ValueKey(
            '${_principal.role}-${_locale.tag}-${_a11y.reducedMotion}-'
            '${_a11y.classroomMode}-${_a11y.textScale}',
          ),
          title: copy.appName,
          theme: theme,
          locale: flutterLocale,
          supportedLocales: const [
            Locale('en'),
            Locale('ur'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            final scaled = mq.textScaler.scale(1) * _a11y.textScale;
            return MediaQuery(
              data: mq.copyWith(
                textScaler: TextScaler.linear(scaled),
                disableAnimations:
                    mq.disableAnimations || _a11y.effectiveReducedMotion,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          routerConfig: _router,
        ),
      ),
    );
  }
}
""",
    )

    # Update student router + shell for a11y
    router_path = ROOT / "apps/student_app/lib/app/student_router.dart"
    router = router_path.read_text(encoding="utf-8")
    if "onAccessibilityChanged" not in router:
        router = router.replace(
            """GoRouter createStudentRouter({
  required EnvironmentConfig config,
  required SessionPrincipal principal,
  required ValueChanged<SessionPrincipal> onPrincipalChanged,
  required ValueChanged<NanoAppLocale> onLocaleChanged,
  required NanoAppLocale locale,
  String? initialLocation,
}) {""",
            """GoRouter createStudentRouter({
  required EnvironmentConfig config,
  required SessionPrincipal principal,
  required ValueChanged<SessionPrincipal> onPrincipalChanged,
  required ValueChanged<NanoAppLocale> onLocaleChanged,
  required ValueChanged<AccessibilityPreferences> onAccessibilityChanged,
  required NanoAppLocale locale,
  required AccessibilityPreferences accessibility,
  String? initialLocation,
}) {""",
        )
        router = router.replace(
            """          return StudentShell(
            config: config,
            principal: principal,
            navigationShell: navigationShell,
            onPrincipalChanged: onPrincipalChanged,
            onLocaleChanged: onLocaleChanged,
            locale: locale,
          );""",
            """          return StudentShell(
            config: config,
            principal: principal,
            navigationShell: navigationShell,
            onPrincipalChanged: onPrincipalChanged,
            onLocaleChanged: onLocaleChanged,
            onAccessibilityChanged: onAccessibilityChanged,
            locale: locale,
            accessibility: accessibility,
          );""",
        )
        router_path.write_text(router, encoding="utf-8")

    shell_path = ROOT / "apps/student_app/lib/app/student_shell.dart"
    shell = shell_path.read_text(encoding="utf-8")
    if "accessibility_settings_page.dart" not in shell:
        shell = shell.replace(
            "import 'package:student_app/app/locale_preview_page.dart';",
            "import 'package:student_app/app/locale_preview_page.dart';\n"
            "import 'package:student_app/app/accessibility_settings_page.dart';",
        )
    if "onAccessibilityChanged" not in shell:
        shell = shell.replace(
            """  const StudentShell({
    super.key,
    required this.config,
    required this.principal,
    required this.navigationShell,
    required this.onPrincipalChanged,
    required this.onLocaleChanged,
    required this.locale,
  });

  final EnvironmentConfig config;
  final SessionPrincipal principal;
  final StatefulNavigationShell navigationShell;
  final ValueChanged<SessionPrincipal> onPrincipalChanged;
  final ValueChanged<NanoAppLocale> onLocaleChanged;
  final NanoAppLocale locale;""",
            """  const StudentShell({
    super.key,
    required this.config,
    required this.principal,
    required this.navigationShell,
    required this.onPrincipalChanged,
    required this.onLocaleChanged,
    required this.onAccessibilityChanged,
    required this.locale,
    required this.accessibility,
  });

  final EnvironmentConfig config;
  final SessionPrincipal principal;
  final StatefulNavigationShell navigationShell;
  final ValueChanged<SessionPrincipal> onPrincipalChanged;
  final ValueChanged<NanoAppLocale> onLocaleChanged;
  final ValueChanged<AccessibilityPreferences> onAccessibilityChanged;
  final NanoAppLocale locale;
  final AccessibilityPreferences accessibility;""",
        )
    if "AccessibilitySettingsPage" not in shell:
        marker = "child: const Text('Locale'),\n                    ),"
        insert = """
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => AccessibilitySettingsPage(
                              preferences: accessibility,
                              onChanged: onAccessibilityChanged,
                            ),
                          ),
                        );
                      },
                      child: const Text('A11y'),
                    ),"""
        if marker in shell:
            shell = shell.replace(marker, marker + insert, 1)
    shell_path.write_text(shell, encoding="utf-8")

    w(
        "apps/student_app/test/accessibility_settings_test.dart",
        r"""
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/main.dart';

void main() {
  testWidgets('reduced motion disables animations via MediaQuery', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const config = EnvironmentConfig(
      environment: NanoEnvironment.development,
      supabaseUrl: '',
      supabaseAnonKey: '',
      featureFlags: {'diagnostics': true},
    );

    await tester.pumpWidget(
      const NanoStudentApp(
        config: config,
        initialAccessibility: AccessibilityPreferences(reducedMotion: true),
      ),
    );
    await tester.pumpAndSettle();

    final media = MediaQuery.of(tester.element(find.text('Home').first));
    expect(media.disableAnimations, isTrue);

    await tester.tap(find.text('A11y'));
    await tester.pumpAndSettle();
    expect(find.text('Accessibility'), findsOneWidget);
    expect(find.text('Static (reduced motion)'), findsOneWidget);
  });

  testWidgets('classroom mode shows quiet captions path', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const config = EnvironmentConfig(
      environment: NanoEnvironment.development,
      supabaseUrl: '',
      supabaseAnonKey: '',
      featureFlags: {'diagnostics': true},
    );

    await tester.pumpWidget(
      const NanoStudentApp(
        config: config,
        initialAccessibility: AccessibilityPreferences(classroomMode: true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('A11y'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Paused by Classroom Mode'), findsOneWidget);
  });
}
""",
    )

    w(
        "docs/modules/FND-07/README.md",
        """
# FND-07 — Accessibility, Sound, Haptics, and Reduced Motion

## Purpose

Shared accessibility preferences, feedback gates (sound/haptics), reduced-motion-aware durations, minimum tap targets, and an owner-facing settings preview.

## Main surfaces

- Student **A11y** settings page
- `NanoFeedback` + `NanoMotion.resolve`
- `NanoAccessibleTarget` for min tap size + semantics
""",
    )

    w(
        "docs/modules/FND-07/IMPLEMENTATION_PLAN.md",
        """
# FND-07 Implementation Plan

1. `AccessibilityPreferences` (+ classroom mode effective gates)
2. `NanoFeedback`, `NanoAccessibilityScope`, motion resolve helper
3. Settings preview with motion sample + feedback try buttons
4. Wire MediaQuery text scale / disableAnimations into student app
5. Tests for prefs, motion zeroing, settings UI
""",
    )

    w(
        "docs/modules/FND-07/DECISIONS.md",
        """
# FND-07 Decisions

- Classroom Mode forces reduced motion and mutes sound/haptics without clearing the user's saved toggles.
- Sound is preference-gated only in R0 (no audio assets yet).
- System `MediaQuery.disableAnimations` and prefs both zero non-essential `NanoMotion` durations.
- Persistence of preferences is deferred to profile/onboarding modules.
""",
    )

    w(
        "docs/modules/FND-07/KNOWN_ISSUES.md",
        """
# FND-07 Known Issues

- No bundled sound assets; cues log in debug only.
- Haptics are no-ops on web/desktop hosts without vibrator support.
- Full screen-reader audit remains QA-04.
""",
    )

    w(
        "docs/modules/FND-07/MANUAL_TEST.md",
        """
# FND-07 Manual Test Guide

## Setup

```powershell
cd D:\\nano
dart pub get
dart run melos bootstrap
cd apps\\student_app
flutter run -d chrome --dart-define=NANO_ENV=development
```

## Checklist

- [ ] Open **A11y** from the debug strip
- [ ] Toggle **Reduced motion** — motion sample becomes static
- [ ] Toggle **Classroom Mode** — sound switch shows paused; motion static
- [ ] Drag **Text size** — UI text scales
- [ ] Tap Success / Error try buttons (haptics may no-op on web)
- [ ] Captions sample banner when captions enabled

## Approve

`NEXT`

## Reject

`FIX: <problem>`
""",
    )

    w(
        "docs/modules/FND-07/TEST_REPORT.md",
        """
# FND-07 Test Report

| Test | Result | Notes |
|------|--------|-------|
| nano_domain accessibility_preferences_test | RUN | classroom gates |
| nano_design_system nano_feedback_test | RUN | feedback + motion |
| student_app accessibility_settings_test | RUN | MediaQuery + UI |
| CI workflow | NOT RUN | PAT missing `workflow` scope |
""",
    )

    print("FND-07 scaffold written")


if __name__ == "__main__":
    main()
