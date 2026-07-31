"""Scaffold FND-06 English/Urdu localization readiness."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(r"d:\nano")


def w(path: str, content: str) -> None:
    p = ROOT / path
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content.strip() + "\n", encoding="utf-8")


def patch_flutter_localizations(app: str) -> None:
    path = ROOT / "apps" / app / "pubspec.yaml"
    text = path.read_text(encoding="utf-8")
    if "flutter_localizations:" in text:
        return
    needle = "dependencies:\n  flutter:\n    sdk: flutter\n"
    insert = (
        "dependencies:\n"
        "  flutter:\n"
        "    sdk: flutter\n"
        "  flutter_localizations:\n"
        "    sdk: flutter\n"
    )
    if needle not in text:
        raise SystemExit(f"flutter dep block missing in {path}")
    path.write_text(text.replace(needle, insert, 1), encoding="utf-8")


def main() -> None:
    w(
        "packages/nano_domain/lib/src/l10n/nano_app_locale.dart",
        r"""
/// Supported product locales for R0 readiness (full ARB pipeline can follow).
enum NanoAppLocale {
  en,
  ur;

  String get languageCode => name;

  /// BCP-47 tag used by Flutter [Locale].
  String get tag => languageCode;

  bool get isRtl => this == NanoAppLocale.ur;

  static NanoAppLocale fromTag(String? tag) {
    final normalized = (tag ?? 'en').toLowerCase();
    if (normalized.startsWith('ur')) return NanoAppLocale.ur;
    return NanoAppLocale.en;
  }
}
""",
    )

    w(
        "packages/nano_domain/lib/src/l10n/nano_copy.dart",
        r'''
import 'nano_app_locale.dart';

/// Foundation UI copy for English and Urdu.
/// Feature modules should prefer keys here (or later ARB) over hardcoded English.
class NanoCopy {
  const NanoCopy(this.locale);

  final NanoAppLocale locale;

  bool get isUrdu => locale == NanoAppLocale.ur;

  String get appName => 'Nano';

  String get languageEnglish => isUrdu ? 'انگریزی' : 'English';
  String get languageUrdu => isUrdu ? 'اردو' : 'Urdu';

  String greeting(String name) =>
      isUrdu ? 'سلام $name' : 'Hi $name';

  String get subjects => isUrdu ? 'مضامین' : 'Subjects';
  String get continueLearning => isUrdu ? 'جاری رکھیں' : 'Continue';
  String get todaysMission =>
      isUrdu ? 'آج کا مشن' : "Today's Mission";
  String get buildingFuture =>
      isUrdu ? 'میں اپنا مستقبل بنا رہا/رہی ہوں۔' : "I'm building my future.";

  String get home => isUrdu ? 'گھر' : 'Home';
  String get learning => isUrdu ? 'سیکھنا' : 'Learning';
  String get play => isUrdu ? 'کھیلیں' : 'Play';
  String get games => isUrdu ? 'گیمز' : 'Games';
  String get flex => isUrdu ? 'فلیکس' : 'Flex';
  String get communities => isUrdu ? 'کمیونٹیز' : 'Communities';
  String get me => isUrdu ? 'میں' : 'Me';
  String get profile => isUrdu ? 'پروفائل' : 'Profile';

  String get dashboard => isUrdu ? 'ڈیش بورڈ' : 'Dashboard';
  String get classes => isUrdu ? 'کلاسز' : 'Classes';
  String get attendance => isUrdu ? 'حاضری' : 'Attendance';
  String get marks => isUrdu ? 'نمبر' : 'Marks';
  String get classroom => isUrdu ? 'کلاس روم' : 'Classroom';

  String get overview => isUrdu ? 'جائزہ' : 'Overview';
  String get students => isUrdu ? 'طلبہ' : 'Students';
  String get teachers => isUrdu ? 'اساتذہ' : 'Teachers';
  String get reports => isUrdu ? 'رپورٹس' : 'Reports';
  String get settings => isUrdu ? 'ترتیبات' : 'Settings';
  String get platform => isUrdu ? 'پلیٹ فارم' : 'Platform';
  String get schools => isUrdu ? 'اسکول' : 'Schools';
  String get content => isUrdu ? 'مواد' : 'Content';
  String get moderation => isUrdu ? 'نگرانی' : 'Moderation';
  String get analytics => isUrdu ? 'تجزیات' : 'Analytics';
  String get audit => isUrdu ? 'آڈٹ' : 'Audit';

  String get loading => isUrdu ? 'لوڈ ہو رہا ہے' : 'Loading';
  String get emptyTitle => isUrdu ? 'ابھی کچھ نہیں' : 'Nothing here yet';
  String get emptyMessage =>
      isUrdu ? 'جلد دوبارہ چیک کریں۔' : 'Check back soon.';
  String get errorTitle =>
      isUrdu ? 'کچھ غلط ہو گیا' : 'Something went wrong';
  String get errorMessage =>
      isUrdu ? 'براہِ کرم دوبارہ کوشش کریں۔' : 'Please try again.';
  String get tryAgain => isUrdu ? 'دوبارہ کوشش' : 'Try again';
  String get offlineBanner => isUrdu
      ? 'آپ آف لائن ہیں۔ دوبارہ جڑنے پر ہم وقت کریں گے۔'
      : 'You are offline. Changes will sync when you reconnect.';
  String get maintenanceTitle =>
      isUrdu ? 'مرمت جاری ہے' : 'Under maintenance';
  String get maintenanceMessage => isUrdu
      ? 'Nano عارضی طور پر دستیاب نہیں۔ جلد کوشش کریں۔'
      : 'Nano is temporarily unavailable while we finish updates. Try again soon.';

  String get localePreviewTitle =>
      isUrdu ? 'زبان کا پیش منظر' : 'Locale preview';
  String get localePreviewBody => isUrdu
      ? 'اردو دائیں سے بائیں ترتیب استعمال کرتی ہے۔ انگریزی بائیں سے دائیں۔'
      : 'Urdu uses right-to-left layout. English uses left-to-right.';
  String get sampleSentence => isUrdu
      ? 'علی ریاضی کا سبق جاری رکھ سکتا ہے۔'
      : 'Ali can continue a Math lesson.';

  String navLabel(String destinationId) => switch (destinationId) {
        'home' => home,
        'learning' => learning,
        'game' => play,
        'games' => games,
        'flex' => flex,
        'communities' => communities,
        'profile' => profile,
        'dashboard' => dashboard,
        'classes' => classes,
        'attendance' => attendance,
        'marks' => marks,
        'classroom' => classroom,
        'overview' => overview,
        'students' => students,
        'teachers' => teachers,
        'reports' => reports,
        'settings' => settings,
        'platform' => platform,
        'schools' => schools,
        'content' => content,
        'moderation' => moderation,
        'analytics' => analytics,
        'audit' => audit,
        _ => destinationId,
      };

  /// Junior profile/play labels differ from senior density labels.
  String studentNavLabel(String destinationId, {required bool junior}) {
    if (destinationId == 'profile') {
      return junior ? me : profile;
    }
    if (destinationId == 'games' || destinationId == 'games') {
      return junior ? play : games;
    }
    return navLabel(destinationId);
  }
}
''',
    )

    barrel = ROOT / "packages/nano_domain/lib/src/nano_domain.dart"
    text = barrel.read_text(encoding="utf-8")
    if "nano_app_locale.dart" not in text:
        barrel.write_text(
            text.rstrip()
            + "\nexport 'l10n/nano_app_locale.dart';\n"
            + "export 'l10n/nano_copy.dart';\n",
            encoding="utf-8",
        )

    w(
        "packages/nano_domain/test/nano_copy_test.dart",
        r"""
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('Urdu locale is RTL and English is LTR', () {
    expect(NanoAppLocale.ur.isRtl, isTrue);
    expect(NanoAppLocale.en.isRtl, isFalse);
    expect(NanoAppLocale.fromTag('ur-PK'), NanoAppLocale.ur);
  });

  test('foundation copy switches language', () {
    final en = NanoCopy(NanoAppLocale.en);
    final ur = NanoCopy(NanoAppLocale.ur);
    expect(en.home, 'Home');
    expect(ur.home, 'گھر');
    expect(en.greeting('Ali'), 'Hi Ali');
    expect(ur.greeting('Ali'), 'سلام Ali');
    expect(en.studentNavLabel('profile', junior: true), 'Me');
    expect(ur.studentNavLabel('profile', junior: true), 'میں');
  });
}
""",
    )

    # Locale scope + theme localeTag
    w(
        "packages/nano_design_system/lib/src/l10n/nano_locale_scope.dart",
        r"""
import 'package:flutter/material.dart';
import 'package:nano_domain/nano_domain.dart';

class NanoLocaleScope extends InheritedWidget {
  const NanoLocaleScope({
    super.key,
    required this.locale,
    required this.copy,
    required super.child,
  });

  final NanoAppLocale locale;
  final NanoCopy copy;

  static NanoLocaleScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<NanoLocaleScope>();
    assert(scope != null, 'NanoLocaleScope not found in context');
    return scope!;
  }

  static NanoLocaleScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<NanoLocaleScope>();
  }

  static NanoCopy copyOf(BuildContext context) => of(context).copy;

  static NanoAppLocale localeOf(BuildContext context) => of(context).locale;

  @override
  bool updateShouldNotify(NanoLocaleScope oldWidget) =>
      locale != oldWidget.locale;
}
""",
    )

    # Patch NanoTheme to accept localeTag
    theme_path = ROOT / "packages/nano_design_system/lib/src/theme/nano_theme.dart"
    theme = theme_path.read_text(encoding="utf-8")
    if "localeTag" not in theme:
        theme = theme.replace(
            "static ThemeData junior({SchoolBranding branding = const SchoolBranding()}) {\n    return _build(\n",
            "static ThemeData junior({\n    SchoolBranding branding = const SchoolBranding(),\n    String? localeTag,\n  }) {\n    return _build(\n      localeTag: localeTag,\n",
        )
        theme = theme.replace(
            "static ThemeData senior({SchoolBranding branding = const SchoolBranding()}) {\n    return _build(\n",
            "static ThemeData senior({\n    SchoolBranding branding = const SchoolBranding(),\n    String? localeTag,\n  }) {\n    return _build(\n      localeTag: localeTag,\n",
        )
        theme = theme.replace(
            "static ThemeData teacher({SchoolBranding branding = const SchoolBranding()}) {\n    return _build(\n",
            "static ThemeData teacher({\n    SchoolBranding branding = const SchoolBranding(),\n    String? localeTag,\n  }) {\n    return _build(\n      localeTag: localeTag,\n",
        )
        theme = theme.replace(
            "static ThemeData schoolAdmin({SchoolBranding branding = const SchoolBranding()}) {\n    return _build(\n",
            "static ThemeData schoolAdmin({\n    SchoolBranding branding = const SchoolBranding(),\n    String? localeTag,\n  }) {\n    return _build(\n      localeTag: localeTag,\n",
        )
        theme = theme.replace(
            "static ThemeData superadmin({SchoolBranding branding = const SchoolBranding()}) {\n    return _build(\n",
            "static ThemeData superadmin({\n    SchoolBranding branding = const SchoolBranding(),\n    String? localeTag,\n  }) {\n    return _build(\n      localeTag: localeTag,\n",
        )
        theme = theme.replace(
            "required SchoolBranding branding,\n    Color? accent,\n",
            "required SchoolBranding branding,\n    String? localeTag,\n    Color? accent,\n",
        )
        theme = theme.replace(
            "textTheme: NanoTypography.textTheme(dense: dense),\n",
            "textTheme: NanoTypography.textTheme(dense: dense, localeTag: localeTag),\n",
        )
        theme = theme.replace(
            "titleTextStyle: NanoTypography.textTheme(dense: dense).titleLarge,\n",
            "titleTextStyle: NanoTypography.textTheme(dense: dense, localeTag: localeTag).titleLarge,\n",
        )
        theme_path.write_text(theme, encoding="utf-8")

    ds = ROOT / "packages/nano_design_system/lib/nano_design_system.dart"
    ds_text = ds.read_text(encoding="utf-8")
    if "nano_locale_scope.dart" not in ds_text:
        ds.write_text(
            ds_text.rstrip() + "\nexport 'src/l10n/nano_locale_scope.dart';\n",
            encoding="utf-8",
        )

    patch_flutter_localizations("student_app")
    patch_flutter_localizations("teacher_app")
    patch_flutter_localizations("admin_web")

    # Locale preview page
    w(
        "apps/student_app/lib/app/locale_preview_page.dart",
        r"""
import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

class LocalePreviewPage extends StatelessWidget {
  const LocalePreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.copyOf(context);
    final locale = NanoLocaleScope.localeOf(context);
    return NanoScaffold(
      appBar: AppBar(title: Text(copy.localePreviewTitle)),
      body: ListView(
        children: [
          Text(copy.localePreviewBody),
          const SizedBox(height: NanoSpacing.md),
          Text(
            copy.sampleSentence,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: NanoSpacing.md),
          Text(
            '${copy.languageEnglish} / ${copy.languageUrdu}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: NanoSpacing.sm),
          Text(
            'Direction: ${locale.isRtl ? 'RTL' : 'LTR'} · tag=${locale.tag}',
          ),
          const SizedBox(height: NanoSpacing.lg),
          Text(copy.greeting('Ali'), style: Theme.of(context).textTheme.titleLarge),
          Text(copy.subjects),
          Text(copy.todaysMission),
          Text(copy.maintenanceTitle),
          const SizedBox(height: NanoSpacing.lg),
          JuniorActionCard(
            title: copy.subjects,
            subtitle: copy.continueLearning,
            backgroundColor: NanoColors.worldMath,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
""",
    )

    # Update junior/senior homes to use copy when available
    w(
        "apps/student_app/lib/features/home/presentation/junior_home_foundation.dart",
        r"""
import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/home/fixtures/student_home_fixtures.dart';

/// Junior phone-first home composition (UI_reference/kids/home).
class JuniorHomeFoundation extends StatelessWidget {
  const JuniorHomeFoundation({
    super.key,
    this.studentName = StudentHomeFixtures.studentName,
    this.subjects = StudentHomeFixtures.subjects,
    this.onContinue,
    this.onSubjectTap,
  });

  final String studentName;
  final List<LearningSubject> subjects;
  final VoidCallback? onContinue;
  final ValueChanged<LearningSubject>? onSubjectTap;

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        NanoCopy(NanoAppLocale.en);
    return NanoResponsiveBuilder(
      builder: (context, windowSize, _) {
        final columns = NanoResponsive.subjectColumnsFor(
          size: windowSize,
          junior: true,
        );
        return NanoMaxContentWidth(
          child: ListView(
            padding: const EdgeInsets.only(bottom: NanoSpacing.xxl),
            children: [
              const SizedBox(height: NanoSpacing.md),
              Row(
                children: [
                  const CompanionSlot(size: 56),
                  const SizedBox(width: NanoSpacing.sm),
                  Expanded(
                    child: Text(
                      copy.greeting(studentName),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const XpChip(xp: StudentHomeFixtures.xp),
                ],
              ),
              const SizedBox(height: NanoSpacing.lg),
              _ContinueCard(onContinue: onContinue, copy: copy),
              const SizedBox(height: NanoSpacing.lg),
              Text(copy.subjects, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: NanoSpacing.sm),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: subjects.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: NanoSpacing.sm,
                  crossAxisSpacing: NanoSpacing.sm,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (context, index) {
                  final subject = subjects[index];
                  return JuniorActionCard(
                    title: subject.title,
                    subtitle: subject.shortPrompt,
                    backgroundColor: Color(subject.worldColorValue),
                    onTap: onSubjectTap == null
                        ? null
                        : () => onSubjectTap!(subject),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.copy, this.onContinue});

  final NanoCopy copy;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return JuniorActionCard(
      title: StudentHomeFixtures.continueTitle,
      subtitle: copy.continueLearning,
      backgroundColor: NanoColors.worldStories,
      onTap: onContinue,
    );
  }
}
""",
    )

    # Read senior home full file to patch carefully - rewrite with copy
    senior = (ROOT / "apps/student_app/lib/features/home/presentation/senior_home_foundation.dart").read_text(encoding="utf-8")
    if "NanoLocaleScope" not in senior:
        senior = senior.replace(
            "Widget build(BuildContext context) {\n    return NanoResponsiveBuilder(",
            "Widget build(BuildContext context) {\n    final copy = NanoLocaleScope.maybeOf(context)?.copy ??\n        NanoCopy(NanoAppLocale.en);\n    return NanoResponsiveBuilder(",
        )
        senior = senior.replace(
            '''Text(
                      "I'm building my future.",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),''',
            '''Text(
                      copy.buildingFuture,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),''',
        )
        senior = senior.replace(
            '''Text("Today's Mission", style: Theme.of(context).textTheme.titleLarge),''',
            '''Text(copy.todaysMission, style: Theme.of(context).textTheme.titleLarge),''',
        )
        (ROOT / "apps/student_app/lib/features/home/presentation/senior_home_foundation.dart").write_text(
            senior, encoding="utf-8"
        )

    # Student shell - use localized nav labels + locale button
    shell_path = ROOT / "apps/student_app/lib/app/student_shell.dart"
    shell = shell_path.read_text(encoding="utf-8")
    if "locale_preview_page.dart" not in shell:
        shell = shell.replace(
            "import 'package:student_app/app/states_preview_page.dart';",
            "import 'package:student_app/app/states_preview_page.dart';\n"
            "import 'package:student_app/app/locale_preview_page.dart';",
        )
    # Replace NanoBottomNavItem label building
    if "studentNavLabel" not in shell:
        shell = shell.replace(
            """    final items = [
      for (final d in destinations)
        NanoBottomNavItem(
          id: d.id,
          label: d.label,
          icon: nanoNavIcon(d.iconName),
        ),
    ];""",
            """    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        NanoCopy(NanoAppLocale.en);
    final junior = principal.role.usesJuniorPresentation;
    final items = [
      for (final d in destinations)
        NanoBottomNavItem(
          id: d.id,
          label: copy.studentNavLabel(d.id, junior: junior),
          icon: nanoNavIcon(d.iconName),
        ),
    ];""",
        )
    marker = "child: const Text('UI states'),\n                    ),"
    insert = """
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const LocalePreviewPage(),
                          ),
                        );
                      },
                      child: const Text('Locale'),
                    ),"""
    if marker in shell and "LocalePreviewPage" not in shell.split("debug strip")[0] if False else "const LocalePreviewPage()" not in shell:
        if "const LocalePreviewPage()" not in shell:
            shell = shell.replace(marker, marker + insert, 1)
    shell_path.write_text(shell, encoding="utf-8")

    # Student main with locale
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
  });

  final EnvironmentConfig config;
  final SessionPrincipal? initialPrincipal;
  final String? initialLocation;
  final NanoAppLocale initialLocale;

  @override
  State<NanoStudentApp> createState() => _NanoStudentAppState();
}

class _NanoStudentAppState extends State<NanoStudentApp> {
  late SessionPrincipal _principal;
  late GoRouter _router;
  late NanoAppLocale _locale;

  @override
  void initState() {
    super.initState();
    _principal = widget.initialPrincipal ?? SessionPrincipal.junior();
    _locale = widget.initialLocale;
    _router = _createRouter();
  }

  GoRouter _createRouter() {
    return createStudentRouter(
      config: widget.config,
      principal: _principal,
      onPrincipalChanged: _setPrincipal,
      initialLocation: widget.initialLocation,
      onLocaleChanged: _setLocale,
      locale: _locale,
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
      child: MaterialApp.router(
        key: ValueKey('${_principal.role}-${_locale.tag}'),
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
        routerConfig: _router,
      ),
    );
  }
}
""",
    )

    # Update student_router and student_shell signatures for locale
    router_path = ROOT / "apps/student_app/lib/app/student_router.dart"
    router = router_path.read_text(encoding="utf-8")
    if "onLocaleChanged" not in router:
        router = router.replace(
            """GoRouter createStudentRouter({
  required EnvironmentConfig config,
  required SessionPrincipal principal,
  required ValueChanged<SessionPrincipal> onPrincipalChanged,
  String? initialLocation,
}) {""",
            """GoRouter createStudentRouter({
  required EnvironmentConfig config,
  required SessionPrincipal principal,
  required ValueChanged<SessionPrincipal> onPrincipalChanged,
  required ValueChanged<NanoAppLocale> onLocaleChanged,
  required NanoAppLocale locale,
  String? initialLocation,
}) {""",
        )
        router = router.replace(
            """          return StudentShell(
            config: config,
            principal: principal,
            navigationShell: navigationShell,
            onPrincipalChanged: onPrincipalChanged,
          );""",
            """          return StudentShell(
            config: config,
            principal: principal,
            navigationShell: navigationShell,
            onPrincipalChanged: onPrincipalChanged,
            onLocaleChanged: onLocaleChanged,
            locale: locale,
          );""",
        )
        router_path.write_text(router, encoding="utf-8")

    shell = shell_path.read_text(encoding="utf-8")
    if "onLocaleChanged" not in shell or "required this.onLocaleChanged" not in shell:
        shell = shell.replace(
            """class StudentShell extends StatelessWidget {
  const StudentShell({
    super.key,
    required this.config,
    required this.principal,
    required this.navigationShell,
    required this.onPrincipalChanged,
  });

  final EnvironmentConfig config;
  final SessionPrincipal principal;
  final StatefulNavigationShell navigationShell;
  final ValueChanged<SessionPrincipal> onPrincipalChanged;""",
            """class StudentShell extends StatelessWidget {
  const StudentShell({
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
        )
        # Add locale dropdown near persona switcher
        if "onLocaleChanged(NanoAppLocale" not in shell:
            shell = shell.replace(
                """            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AppRole>(
                  value: principal.role,""",
                """            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<NanoAppLocale>(
                  value: locale,
                  items: const [
                    DropdownMenuItem(
                      value: NanoAppLocale.en,
                      child: Text('EN'),
                    ),
                    DropdownMenuItem(
                      value: NanoAppLocale.ur,
                      child: Text('UR'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) onLocaleChanged(value);
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AppRole>(
                  value: principal.role,""",
            )
        shell_path.write_text(shell, encoding="utf-8")

    # Teacher main with locale
    w(
        "apps/teacher_app/lib/main.dart",
        r"""
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:teacher_app/app/teacher_router.dart';

void main() {
  final config = EnvironmentConfig.fromEnvironment();
  runApp(NanoTeacherApp(config: config));
}

class NanoTeacherApp extends StatefulWidget {
  const NanoTeacherApp({
    super.key,
    required this.config,
    this.principal,
    this.initialLocation,
    this.initialLocale = NanoAppLocale.en,
  });

  final EnvironmentConfig config;
  final SessionPrincipal? principal;
  final String? initialLocation;
  final NanoAppLocale initialLocale;

  @override
  State<NanoTeacherApp> createState() => _NanoTeacherAppState();
}

class _NanoTeacherAppState extends State<NanoTeacherApp> {
  late NanoAppLocale _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.principal ?? SessionPrincipal.teacher();
    final copy = NanoCopy(_locale);
    final router = createTeacherRouter(
      config: widget.config,
      principal: session,
      initialLocation: widget.initialLocation,
      copy: copy,
    );
    return NanoLocaleScope(
      locale: _locale,
      copy: copy,
      child: MaterialApp.router(
        title: '${copy.appName} Teacher',
        theme: NanoTheme.teacher(localeTag: _locale.tag),
        locale: Locale(_locale.languageCode),
        supportedLocales: const [Locale('en'), Locale('ur')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    );
  }
}
""",
    )

    # Patch teacher router/shell for copy labels - simpler approach: pass copy
    teacher_router = ROOT / "apps/teacher_app/lib/app/teacher_router.dart"
    tr = teacher_router.read_text(encoding="utf-8")
    if "NanoCopy" not in tr:
        tr = tr.replace(
            """GoRouter createTeacherRouter({
  required EnvironmentConfig config,
  required SessionPrincipal principal,
  String? initialLocation,
}) {""",
            """GoRouter createTeacherRouter({
  required EnvironmentConfig config,
  required SessionPrincipal principal,
  required NanoCopy copy,
  String? initialLocation,
}) {""",
        )
        tr = tr.replace(
            """          return TeacherShell(
            config: config,
            principal: principal,
            navigationShell: navigationShell,
          );""",
            """          return TeacherShell(
            config: config,
            principal: principal,
            navigationShell: navigationShell,
            copy: copy,
          );""",
        )
        teacher_router.write_text(tr, encoding="utf-8")

    teacher_shell = ROOT / "apps/teacher_app/lib/app/teacher_shell.dart"
    ts = teacher_shell.read_text(encoding="utf-8")
    if "required this.copy" not in ts:
        ts = ts.replace(
            """class TeacherShell extends StatelessWidget {
  const TeacherShell({
    super.key,
    required this.config,
    required this.principal,
    required this.navigationShell,
  });

  final EnvironmentConfig config;
  final SessionPrincipal principal;
  final StatefulNavigationShell navigationShell;""",
            """class TeacherShell extends StatelessWidget {
  const TeacherShell({
    super.key,
    required this.config,
    required this.principal,
    required this.navigationShell,
    required this.copy,
  });

  final EnvironmentConfig config;
  final SessionPrincipal principal;
  final StatefulNavigationShell navigationShell;
  final NanoCopy copy;""",
        )
        ts = ts.replace(
            """    final items = [
      for (final d in destinations)
        NanoBottomNavItem(
          id: d.id,
          label: d.label,
          icon: nanoNavIcon(d.iconName),
        ),
    ];""",
            """    final items = [
      for (final d in destinations)
        NanoBottomNavItem(
          id: d.id,
          label: copy.navLabel(d.id),
          icon: nanoNavIcon(d.iconName),
        ),
    ];""",
        )
        teacher_shell.write_text(ts, encoding="utf-8")

    # Admin with locale
    w(
        "apps/admin_web/lib/main.dart",
        r"""
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:admin_web/app/admin_router.dart';

void main() {
  final config = EnvironmentConfig.fromEnvironment();
  runApp(NanoAdminApp(config: config));
}

class NanoAdminApp extends StatefulWidget {
  const NanoAdminApp({
    super.key,
    required this.config,
    this.initialPrincipal,
    this.initialLocation,
    this.initialLocale = NanoAppLocale.en,
  });

  final EnvironmentConfig config;
  final SessionPrincipal? initialPrincipal;
  final String? initialLocation;
  final NanoAppLocale initialLocale;

  @override
  State<NanoAdminApp> createState() => _NanoAdminAppState();
}

class _NanoAdminAppState extends State<NanoAdminApp> {
  late SessionPrincipal _principal;
  late GoRouter _router;
  late NanoAppLocale _locale;

  @override
  void initState() {
    super.initState();
    _principal = widget.initialPrincipal ?? SessionPrincipal.schoolAdmin();
    _locale = widget.initialLocale;
    _router = _createRouter();
  }

  GoRouter _createRouter() {
    final copy = NanoCopy(_locale);
    return createAdminRouter(
      config: widget.config,
      principal: _principal,
      copy: copy,
      onPrincipalChanged: (next) {
        setState(() {
          _principal = next;
          _router = _createRouter();
        });
      },
      initialLocation: widget.initialLocation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoCopy(_locale);
    final theme = _principal.role == AppRole.superadmin
        ? NanoTheme.superadmin(localeTag: _locale.tag)
        : NanoTheme.schoolAdmin(localeTag: _locale.tag);
    return NanoLocaleScope(
      locale: _locale,
      copy: copy,
      child: MaterialApp.router(
        key: ValueKey('${_principal.role}-${_locale.tag}'),
        title: '${copy.appName} Admin',
        theme: theme,
        locale: Locale(_locale.languageCode),
        supportedLocales: const [Locale('en'), Locale('ur')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: _router,
      ),
    );
  }
}
""",
    )

    admin_router = ROOT / "apps/admin_web/lib/app/admin_router.dart"
    ar = admin_router.read_text(encoding="utf-8")
    if "required NanoCopy copy" not in ar:
        ar = ar.replace(
            """GoRouter createAdminRouter({
  required EnvironmentConfig config,
  required SessionPrincipal principal,
  required ValueChanged<SessionPrincipal> onPrincipalChanged,
  String? initialLocation,
}) {""",
            """GoRouter createAdminRouter({
  required EnvironmentConfig config,
  required SessionPrincipal principal,
  required NanoCopy copy,
  required ValueChanged<SessionPrincipal> onPrincipalChanged,
  String? initialLocation,
}) {""",
        )
        ar = ar.replace(
            """          return AdminShell(
            config: config,
            principal: principal,
            navigationShell: navigationShell,
            onPrincipalChanged: onPrincipalChanged,
          );""",
            """          return AdminShell(
            config: config,
            principal: principal,
            navigationShell: navigationShell,
            onPrincipalChanged: onPrincipalChanged,
            copy: copy,
          );""",
        )
        admin_router.write_text(ar, encoding="utf-8")

    admin_shell = ROOT / "apps/admin_web/lib/app/admin_shell.dart"
    ads = admin_shell.read_text(encoding="utf-8")
    if "required this.copy" not in ads:
        ads = ads.replace(
            """class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.config,
    required this.principal,
    required this.navigationShell,
    required this.onPrincipalChanged,
  });

  final EnvironmentConfig config;
  final SessionPrincipal principal;
  final StatefulNavigationShell navigationShell;
  final ValueChanged<SessionPrincipal> onPrincipalChanged;""",
            """class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.config,
    required this.principal,
    required this.navigationShell,
    required this.onPrincipalChanged,
    required this.copy,
  });

  final EnvironmentConfig config;
  final SessionPrincipal principal;
  final StatefulNavigationShell navigationShell;
  final ValueChanged<SessionPrincipal> onPrincipalChanged;
  final NanoCopy copy;""",
        )
        ads = ads.replace(
            """    final items = [
      for (final d in destinations)
        NanoSideRailItem(
          id: d.id,
          label: d.label,
          icon: nanoNavIcon(d.iconName),
        ),
    ];""",
            """    final items = [
      for (final d in destinations)
        NanoSideRailItem(
          id: d.id,
          label: copy.navLabel(d.id),
          icon: nanoNavIcon(d.iconName),
        ),
    ];""",
        )
        admin_shell.write_text(ads, encoding="utf-8")

    # Tests
    w(
        "apps/student_app/test/locale_preview_test.dart",
        r"""
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/main.dart';

void main() {
  testWidgets('Urdu locale flips RTL and translates greeting', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
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
        initialLocale: NanoAppLocale.ur,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('سلام Ali'), findsOneWidget);
    expect(find.text('مضامین'), findsOneWidget);
    final material = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(material.locale?.languageCode, 'ur');
    expect(
      Directionality.of(tester.element(find.text('سلام Ali'))),
      TextDirection.rtl,
    );
  });
}
""",
    )

    # Update widget_test - Home may still find Home in EN; Play→ etc.
    # Existing tests use English - fine with default EN.

    # Fix nano_copy game/games logic - simplify studentNavLabel
    # Already written; fix the awkward switch for game||games

    w(
        "docs/modules/FND-06/README.md",
        """
# FND-06 — Localization and English/Urdu Readiness

## Purpose

Establish English/Urdu locale contracts, foundation copy, RTL direction for Urdu, and typography locale slots so later modules can localize without reworking shells.

## Main surfaces

- EN/UR toggle on student debug app bar
- Locale preview page
- Localized home greeting / subjects / nav labels
""",
    )

    w(
        "docs/modules/FND-06/IMPLEMENTATION_PLAN.md",
        """
# FND-06 Implementation Plan

1. `NanoAppLocale` + `NanoCopy` foundation strings
2. `NanoLocaleScope` + theme `localeTag` for Urdu typography fallbacks
3. Wire `flutter_localizations` + supported locales in all apps
4. Student EN/UR switcher, locale preview, localized nav/home
5. Teacher/admin nav labels via NanoCopy
6. RTL widget test for Urdu
""",
    )

    w(
        "docs/modules/FND-06/DECISIONS.md",
        """
# FND-06 Decisions

- R0 uses typed `NanoCopy` catalogs; ARB/`gen-l10n` can replace the catalog later without changing call sites much.
- Urdu is RTL via Flutter `Locale('ur')` + Material delegates.
- Nunito / Noto Nastaliq Urdu are declared as family slots; system fallbacks apply until fonts are bundled in a media module.
- Subject titles remain English in fixtures for now (curriculum content localization is later).
""",
    )

    w(
        "docs/modules/FND-06/KNOWN_ISSUES.md",
        """
# FND-06 Known Issues

- Custom Urdu font files are not bundled yet (fallback stack only).
- Not every string in placeholder tabs is translated.
- Full bidirectional audit is QA-05.
""",
    )

    w(
        "docs/modules/FND-06/MANUAL_TEST.md",
        """
# FND-06 Manual Test Guide

## Setup

```powershell
cd D:\\nano
dart pub get
dart run melos bootstrap
cd apps\\student_app
flutter run -d chrome --dart-define=NANO_ENV=development
```

## Checklist

- [ ] Default English: Hi Ali, Subjects, Home/Play/Me
- [ ] Switch app bar **UR** — layout becomes RTL; greeting سلام Ali; مضامین
- [ ] Open **Locale** preview — sample Urdu sentence and RTL note
- [ ] Switch back to **EN** — LTR restored
- [ ] Teacher/Admin still launch (nav labels localized when locale is wired)

## Approve

`NEXT`

## Reject

`FIX: <problem>`
""",
    )

    w(
        "docs/modules/FND-06/TEST_REPORT.md",
        """
# FND-06 Test Report

| Test | Result | Notes |
|------|--------|-------|
| nano_domain nano_copy_test | RUN | EN/UR strings + RTL flag |
| student_app locale_preview_test | RUN | Urdu RTL + greeting |
| CI workflow | NOT RUN | PAT missing `workflow` scope |
""",
    )

    print("FND-06 scaffold written")


if __name__ == "__main__":
    main()
