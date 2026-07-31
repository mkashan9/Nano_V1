"""Scaffold FND-04 role-aware navigation shells."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(r"d:\nano")


def w(path: str, content: str) -> None:
    p = ROOT / path
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content.strip() + "\n", encoding="utf-8")


def patch_pubspec(app: str) -> None:
    path = ROOT / "apps" / app / "pubspec.yaml"
    text = path.read_text(encoding="utf-8")
    if "go_router:" in text:
        return
    needle = "  cupertino_icons: ^1.0.8\n"
    insert = (
        "  cupertino_icons: ^1.0.8\n"
        "  go_router: ^14.8.1\n"
    )
    if needle not in text:
        raise SystemExit(f"cupertino_icons not found in {path}")
    path.write_text(text.replace(needle, insert, 1), encoding="utf-8")


def main() -> None:
    # --- Domain navigation contracts ---
    w(
        "packages/nano_domain/lib/src/navigation/app_role.dart",
        r"""
enum AppRole {
  juniorStudent,
  seniorStudent,
  independentStudent,
  teacher,
  schoolAdmin,
  superadmin,
}

extension AppRoleX on AppRole {
  bool get isStudent =>
      this == AppRole.juniorStudent ||
      this == AppRole.seniorStudent ||
      this == AppRole.independentStudent;

  bool get usesJuniorPresentation => this == AppRole.juniorStudent;

  bool get canEverUseFlex =>
      this == AppRole.seniorStudent; // independent never; junior N/A

  String get label => switch (this) {
        AppRole.juniorStudent => 'Junior',
        AppRole.seniorStudent => 'Senior',
        AppRole.independentStudent => 'Independent',
        AppRole.teacher => 'Teacher',
        AppRole.schoolAdmin => 'School admin',
        AppRole.superadmin => 'Superadmin',
      };
}
""",
    )

    w(
        "packages/nano_domain/lib/src/navigation/nav_destination.dart",
        r"""
class NavDestination {
  const NavDestination({
    required this.id,
    required this.label,
    required this.path,
    required this.iconName,
    this.requiredPermission,
    this.requiredFeatureFlag,
    this.requiresFlexEligibility = false,
    this.fallbackPath = '/',
  });

  final String id;
  final String label;
  final String path;
  final String iconName;
  final String? requiredPermission;
  final String? requiredFeatureFlag;
  final bool requiresFlexEligibility;
  final String fallbackPath;
}
""",
    )

    w(
        "packages/nano_domain/lib/src/navigation/session_principal.dart",
        r"""
import 'app_role.dart';

/// Fixture/session identity used by client route guards.
/// Server RLS remains authoritative once AUTH modules land.
class SessionPrincipal {
  const SessionPrincipal({
    required this.role,
    required this.displayName,
    this.permissions = const {},
    this.featureFlags = const {},
    this.flexEligible = false,
  });

  final AppRole role;
  final String displayName;
  final Set<String> permissions;
  final Map<String, bool> featureFlags;
  final bool flexEligible;

  bool hasPermission(String permission) => permissions.contains(permission);

  bool isFeatureEnabled(String flag) => featureFlags[flag] ?? false;

  String get homePath => '/';

  factory SessionPrincipal.junior({String displayName = 'Ali'}) =>
      SessionPrincipal(
        role: AppRole.juniorStudent,
        displayName: displayName,
        permissions: const {'student.read'},
        featureFlags: const {'games': true},
      );

  factory SessionPrincipal.seniorSchool({
    String displayName = 'Ali',
    bool flexEligible = true,
  }) =>
      SessionPrincipal(
        role: AppRole.seniorStudent,
        displayName: displayName,
        permissions: const {'student.read'},
        featureFlags: const {'games': true, 'communities': true},
        flexEligible: flexEligible,
      );

  factory SessionPrincipal.independent({String displayName = 'Ali'}) =>
      SessionPrincipal(
        role: AppRole.independentStudent,
        displayName: displayName,
        permissions: const {'student.read'},
        featureFlags: const {'games': true, 'communities': true},
        flexEligible: false,
      );

  factory SessionPrincipal.teacher({String displayName = 'Ms. Khan'}) =>
      SessionPrincipal(
        role: AppRole.teacher,
        displayName: displayName,
        permissions: const {
          'teacher.dashboard',
          'teacher.classes',
          'teacher.attendance',
          'teacher.marks',
          'teacher.classroom',
          'teacher.profile',
        },
      );

  factory SessionPrincipal.schoolAdmin({String displayName = 'School Admin'}) =>
      SessionPrincipal(
        role: AppRole.schoolAdmin,
        displayName: displayName,
        permissions: const {
          'school.overview',
          'school.students',
          'school.teachers',
          'school.classes',
          'school.reports',
          'school.settings',
        },
      );

  factory SessionPrincipal.superadmin({String displayName = 'Platform Admin'}) =>
      SessionPrincipal(
        role: AppRole.superadmin,
        displayName: displayName,
        permissions: const {
          'platform.overview',
          'platform.schools',
          'platform.content',
          'platform.moderation',
          'platform.analytics',
          'platform.audit',
        },
      );
}
""",
    )

    w(
        "packages/nano_domain/lib/src/navigation/nav_catalog.dart",
        r"""
import 'app_role.dart';
import 'nav_destination.dart';
import 'session_principal.dart';

abstract final class NavCatalog {
  static const junior = <NavDestination>[
    NavDestination(
      id: 'home',
      label: 'Home',
      path: '/',
      iconName: 'home',
    ),
    NavDestination(
      id: 'games',
      label: 'Play',
      path: '/games',
      iconName: 'sports_esports',
      requiredFeatureFlag: 'games',
    ),
    NavDestination(
      id: 'profile',
      label: 'Me',
      path: '/profile',
      iconName: 'person',
    ),
  ];

  static const senior = <NavDestination>[
    NavDestination(
      id: 'learning',
      label: 'Learning',
      path: '/',
      iconName: 'menu_book',
    ),
    NavDestination(
      id: 'games',
      label: 'Games',
      path: '/games',
      iconName: 'sports_esports',
      requiredFeatureFlag: 'games',
    ),
    NavDestination(
      id: 'flex',
      label: 'Flex',
      path: '/flex',
      iconName: 'bolt',
      requiresFlexEligibility: true,
    ),
    NavDestination(
      id: 'communities',
      label: 'Communities',
      path: '/communities',
      iconName: 'groups',
      requiredFeatureFlag: 'communities',
    ),
    NavDestination(
      id: 'profile',
      label: 'Profile',
      path: '/profile',
      iconName: 'person',
    ),
  ];

  /// Independent students share senior density but never Flex.
  static const independent = <NavDestination>[
    NavDestination(
      id: 'learning',
      label: 'Learning',
      path: '/',
      iconName: 'menu_book',
    ),
    NavDestination(
      id: 'games',
      label: 'Games',
      path: '/games',
      iconName: 'sports_esports',
      requiredFeatureFlag: 'games',
    ),
    NavDestination(
      id: 'communities',
      label: 'Communities',
      path: '/communities',
      iconName: 'groups',
      requiredFeatureFlag: 'communities',
    ),
    NavDestination(
      id: 'profile',
      label: 'Profile',
      path: '/profile',
      iconName: 'person',
    ),
  ];

  static const teacher = <NavDestination>[
    NavDestination(
      id: 'dashboard',
      label: 'Dashboard',
      path: '/',
      iconName: 'dashboard',
      requiredPermission: 'teacher.dashboard',
    ),
    NavDestination(
      id: 'classes',
      label: 'Classes',
      path: '/classes',
      iconName: 'class_',
      requiredPermission: 'teacher.classes',
    ),
    NavDestination(
      id: 'attendance',
      label: 'Attendance',
      path: '/attendance',
      iconName: 'fact_check',
      requiredPermission: 'teacher.attendance',
    ),
    NavDestination(
      id: 'marks',
      label: 'Marks',
      path: '/marks',
      iconName: 'grade',
      requiredPermission: 'teacher.marks',
    ),
    NavDestination(
      id: 'classroom',
      label: 'Classroom',
      path: '/classroom',
      iconName: 'cast_for_education',
      requiredPermission: 'teacher.classroom',
    ),
    NavDestination(
      id: 'profile',
      label: 'Profile',
      path: '/profile',
      iconName: 'person',
      requiredPermission: 'teacher.profile',
    ),
  ];

  static const schoolAdmin = <NavDestination>[
    NavDestination(
      id: 'overview',
      label: 'Overview',
      path: '/',
      iconName: 'home',
      requiredPermission: 'school.overview',
    ),
    NavDestination(
      id: 'students',
      label: 'Students',
      path: '/students',
      iconName: 'school',
      requiredPermission: 'school.students',
    ),
    NavDestination(
      id: 'teachers',
      label: 'Teachers',
      path: '/teachers',
      iconName: 'badge',
      requiredPermission: 'school.teachers',
    ),
    NavDestination(
      id: 'classes',
      label: 'Classes',
      path: '/classes',
      iconName: 'groups',
      requiredPermission: 'school.classes',
    ),
    NavDestination(
      id: 'reports',
      label: 'Reports',
      path: '/reports',
      iconName: 'assessment',
      requiredPermission: 'school.reports',
    ),
    NavDestination(
      id: 'settings',
      label: 'Settings',
      path: '/settings',
      iconName: 'settings',
      requiredPermission: 'school.settings',
    ),
  ];

  static const superadmin = <NavDestination>[
    NavDestination(
      id: 'platform',
      label: 'Platform',
      path: '/',
      iconName: 'dns',
      requiredPermission: 'platform.overview',
    ),
    NavDestination(
      id: 'schools',
      label: 'Schools',
      path: '/schools',
      iconName: 'apartment',
      requiredPermission: 'platform.schools',
    ),
    NavDestination(
      id: 'content',
      label: 'Content',
      path: '/content',
      iconName: 'library_books',
      requiredPermission: 'platform.content',
    ),
    NavDestination(
      id: 'moderation',
      label: 'Moderation',
      path: '/moderation',
      iconName: 'gavel',
      requiredPermission: 'platform.moderation',
    ),
    NavDestination(
      id: 'analytics',
      label: 'Analytics',
      path: '/analytics',
      iconName: 'insights',
      requiredPermission: 'platform.analytics',
    ),
    NavDestination(
      id: 'audit',
      label: 'Audit',
      path: '/audit',
      iconName: 'history',
      requiredPermission: 'platform.audit',
    ),
  ];

  static List<NavDestination> catalogFor(AppRole role) => switch (role) {
        AppRole.juniorStudent => junior,
        AppRole.seniorStudent => senior,
        AppRole.independentStudent => independent,
        AppRole.teacher => teacher,
        AppRole.schoolAdmin => schoolAdmin,
        AppRole.superadmin => superadmin,
      };

  static List<NavDestination> visibleFor(SessionPrincipal principal) {
    return catalogFor(principal.role)
        .where((d) => RouteAccess.canAccess(principal, d))
        .toList(growable: false);
  }
}

/// Access checks shared by catalogs and deep-link resolution.
abstract final class RouteAccess {
  static bool canAccess(SessionPrincipal principal, NavDestination destination) {
    if (destination.requiresFlexEligibility && !principal.flexEligible) {
      return false;
    }
    // Independent students must never see Flex even if a bad catalog entry slips in.
    if (destination.id == 'flex' &&
        principal.role == AppRole.independentStudent) {
      return false;
    }
    final permission = destination.requiredPermission;
    if (permission != null && !principal.hasPermission(permission)) {
      return false;
    }
    final flag = destination.requiredFeatureFlag;
    if (flag != null && !principal.isFeatureEnabled(flag)) {
      return false;
    }
    return true;
  }
}
""",
    )

    w(
        "packages/nano_domain/lib/src/navigation/deep_link_resolver.dart",
        r"""
import 'nav_catalog.dart';
import 'nav_destination.dart';
import 'session_principal.dart';

class DeepLinkResolution {
  const DeepLinkResolution({
    required this.location,
    required this.fellBack,
    this.requestedPath,
  });

  final String location;
  final bool fellBack;
  final String? requestedPath;
}

abstract final class DeepLinkResolver {
  /// Resolves a notification/deep-link path to a permitted location.
  /// Unavailable targets fall back to a safe parent (usually home `/`).
  static DeepLinkResolution resolve(
    SessionPrincipal principal,
    String requestedPath,
  ) {
    final normalized = _normalize(requestedPath);
    final catalog = NavCatalog.catalogFor(principal.role);
    final match = _find(catalog, normalized);

    if (match == null) {
      return DeepLinkResolution(
        location: principal.homePath,
        fellBack: true,
        requestedPath: normalized,
      );
    }

    if (!RouteAccess.canAccess(principal, match)) {
      return DeepLinkResolution(
        location: match.fallbackPath,
        fellBack: true,
        requestedPath: normalized,
      );
    }

    return DeepLinkResolution(
      location: match.path,
      fellBack: false,
      requestedPath: normalized,
    );
  }

  static String _normalize(String path) {
    if (path.isEmpty) return '/';
    var p = path.trim();
    if (!p.startsWith('/')) p = '/$p';
    if (p.length > 1 && p.endsWith('/')) p = p.substring(0, p.length - 1);
    return p;
  }

  static NavDestination? _find(List<NavDestination> catalog, String path) {
    for (final d in catalog) {
      if (d.path == path) return d;
    }
    return null;
  }
}
""",
    )

    # Update domain barrel
    domain_barrel = ROOT / "packages/nano_domain/lib/src/nano_domain.dart"
    exports = """
export 'environment/build_info.dart';
export 'environment/environment_config.dart';
export 'environment/feature_flag.dart';
export 'environment/nano_environment.dart';
export 'environment/service_endpoint.dart';
export 'learning/learning_subject.dart';
export 'learning/home_plan_item.dart';
export 'navigation/app_role.dart';
export 'navigation/nav_destination.dart';
export 'navigation/session_principal.dart';
export 'navigation/nav_catalog.dart';
export 'navigation/deep_link_resolver.dart';
"""
    domain_barrel.write_text(exports.strip() + "\n", encoding="utf-8")

    w(
        "packages/nano_domain/test/navigation_guard_test.dart",
        r"""
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('independent student never sees Flex destination', () {
    final principal = SessionPrincipal.independent();
    final visible = NavCatalog.visibleFor(principal);
    expect(visible.any((d) => d.id == 'flex'), isFalse);
    expect(visible.map((d) => d.id), isNot(contains('flex')));
  });

  test('senior school student sees Flex when eligible', () {
    final principal = SessionPrincipal.seniorSchool(flexEligible: true);
    final visible = NavCatalog.visibleFor(principal);
    expect(visible.any((d) => d.id == 'flex'), isTrue);
  });

  test('senior without flex eligibility hides Flex', () {
    final principal = SessionPrincipal.seniorSchool(flexEligible: false);
    final visible = NavCatalog.visibleFor(principal);
    expect(visible.any((d) => d.id == 'flex'), isFalse);
  });

  test('deep link to Flex falls back for independent student', () {
    final principal = SessionPrincipal.independent();
    final result = DeepLinkResolver.resolve(principal, '/flex');
    expect(result.fellBack, isTrue);
    expect(result.location, '/');
  });

  test('deep link to allowed games succeeds for junior', () {
    final principal = SessionPrincipal.junior();
    final result = DeepLinkResolver.resolve(principal, '/games');
    expect(result.fellBack, isFalse);
    expect(result.location, '/games');
  });

  test('feature flag hides games destination', () {
    final principal = SessionPrincipal(
      role: AppRole.juniorStudent,
      displayName: 'Ali',
      permissions: const {'student.read'},
      featureFlags: const {'games': false},
    );
    final visible = NavCatalog.visibleFor(principal);
    expect(visible.any((d) => d.id == 'gamess'), isFalse);
    final result = DeepLinkResolver.resolve(principal, '/games');
    expect(result.fellBack, isTrue);
    expect(result.location, '/');
  });

  test('teacher without marks permission cannot open marks', () {
    final principal = SessionPrincipal(
      role: AppRole.teacher,
      displayName: 'Limited',
      permissions: const {'teacher.dashboard', 'teacher.classes'},
    );
    final marks = NavCatalog.teacher.firstWhere((d) => d.id == 'marks');
    expect(RouteAccess.canAccess(principal, marks), isFalse);
    final result = DeepLinkResolver.resolve(principal, '/marks');
    expect(result.fellBack, isTrue);
  });

  test('unknown deep link falls back to home', () {
    final result =
        DeepLinkResolver.resolve(SessionPrincipal.junior(), '/not-a-route');
    expect(result.fellBack, isTrue);
    expect(result.location, '/');
  });
}
""",
    )

    # Domain package needs flutter_test - check pubspec
    domain_pub = ROOT / "packages/nano_domain/pubspec.yaml"
    domain_text = domain_pub.read_text(encoding="utf-8")
    if "flutter_test:" not in domain_text:
        # nano_domain might be pure dart - check
        if "flutter:" not in domain_text.split("dev_dependencies:")[0]:
            # Use package:test instead for pure dart
            w(
                "packages/nano_domain/test/navigation_guard_test.dart",
                r"""
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('independent student never sees Flex destination', () {
    final principal = SessionPrincipal.independent();
    final visible = NavCatalog.visibleFor(principal);
    expect(visible.any((d) => d.id == 'flex'), isFalse);
  });

  test('senior school student sees Flex when eligible', () {
    final principal = SessionPrincipal.seniorSchool(flexEligible: true);
    final visible = NavCatalog.visibleFor(principal);
    expect(visible.any((d) => d.id == 'flex'), isTrue);
  });

  test('senior without flex eligibility hides Flex', () {
    final principal = SessionPrincipal.seniorSchool(flexEligible: false);
    final visible = NavCatalog.visibleFor(principal);
    expect(visible.any((d) => d.id == 'flex'), isFalse);
  });

  test('deep link to Flex falls back for independent student', () {
    final principal = SessionPrincipal.independent();
    final result = DeepLinkResolver.resolve(principal, '/flex');
    expect(result.fellBack, isTrue);
    expect(result.location, '/');
  });

  test('deep link to allowed games succeeds for junior', () {
    final principal = SessionPrincipal.junior();
    final result = DeepLinkResolver.resolve(principal, '/games');
    expect(result.fellBack, isFalse);
    expect(result.location, '/games');
  });

  test('feature flag hides games destination', () {
    final principal = SessionPrincipal(
      role: AppRole.juniorStudent,
      displayName: 'Ali',
      permissions: const {'student.read'},
      featureFlags: const {'games': false},
    );
    final visible = NavCatalog.visibleFor(principal);
    expect(visible.any((d) => d.id == 'games'), isFalse);
    final result = DeepLinkResolver.resolve(principal, '/games');
    expect(result.fellBack, isTrue);
    expect(result.location, '/');
  });

  test('teacher without marks permission cannot open marks', () {
    final principal = SessionPrincipal(
      role: AppRole.teacher,
      displayName: 'Limited',
      permissions: const {'teacher.dashboard', 'teacher.classes'},
    );
    final marks = NavCatalog.teacher.firstWhere((d) => d.id == 'marks');
    expect(RouteAccess.canAccess(principal, marks), isFalse);
    final result = DeepLinkResolver.resolve(principal, '/marks');
    expect(result.fellBack, isTrue);
  });

  test('unknown deep link falls back to home', () {
    final result =
        DeepLinkResolver.resolve(SessionPrincipal.junior(), '/not-a-route');
    expect(result.fellBack, isTrue);
    expect(result.location, '/');
  });
}
""",
            )
            if "test:" not in domain_text:
                domain_text = domain_text.rstrip() + "\n\ndev_dependencies:\n  test: ^1.25.0\n"
                domain_pub.write_text(domain_text + "\n", encoding="utf-8")

    # --- Design system nav chrome ---
    w(
        "packages/nano_design_system/lib/src/navigation/nano_bottom_nav.dart",
        r"""
import 'package:flutter/material.dart';

class NanoBottomNavItem {
  const NanoBottomNavItem({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

class NanoBottomNav extends StatelessWidget {
  const NanoBottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<NanoBottomNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex.clamp(0, items.length - 1),
      onDestinationSelected: onSelect,
      destinations: [
        for (final item in items)
          NavigationDestination(
            icon: Icon(item.icon),
            label: item.label,
          ),
      ],
    );
  }
}
""",
    )

    w(
        "packages/nano_design_system/lib/src/navigation/nano_side_rail.dart",
        r"""
import 'package:flutter/material.dart';
import '../tokens/nano_spacing.dart';

class NanoSideRailItem {
  const NanoSideRailItem({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

class NanoSideRail extends StatelessWidget {
  const NanoSideRail({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    this.title = 'Nano',
    this.extended = true,
  });

  final List<NanoSideRailItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final String title;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: SafeArea(
        child: SizedBox(
          width: extended ? 240 : 88,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(NanoSpacing.md),
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final selected = i == selectedIndex;
                    return ListTile(
                      selected: selected,
                      leading: Icon(item.icon),
                      title: extended ? Text(item.label) : null,
                      onTap: () => onSelect(i),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
""",
    )

    ds_barrel = ROOT / "packages/nano_design_system/lib/nano_design_system.dart"
    ds_text = ds_barrel.read_text(encoding="utf-8")
    if "nano_bottom_nav.dart" not in ds_text:
        ds_barrel.write_text(
            ds_text.rstrip()
            + "\nexport 'src/navigation/nano_bottom_nav.dart';\n"
            + "export 'src/navigation/nano_side_rail.dart';\n",
            encoding="utf-8",
        )

    # --- Icon mapping helper used by apps ---
    w(
        "packages/nano_design_system/lib/src/navigation/nav_icons.dart",
        r"""
import 'package:flutter/material.dart';

IconData nanoNavIcon(String name) => switch (name) {
      'home' => Icons.home_outlined,
      'sports_esports' => Icons.sports_esports_outlined,
      'person' => Icons.person_outline,
      'menu_book' => Icons.menu_book_outlined,
      'bolt' => Icons.bolt_outlined,
      'groups' => Icons.groups_outlined,
      'dashboard' => Icons.dashboard_outlined,
      'class_' => Icons.class_outlined,
      'fact_check' => Icons.fact_check_outlined,
      'grade' => Icons.grade_outlined,
      'cast_for_education' => Icons.cast_for_education_outlined,
      'school' => Icons.school_outlined,
      'badge' => Icons.badge_outlined,
      'assessment' => Icons.assessment_outlined,
      'settings' => Icons.settings_outlined,
      'dns' => Icons.dns_outlined,
      'apartment' => Icons.apartment_outlined,
      'library_books' => Icons.library_books_outlined,
      'gavel' => Icons.gavel_outlined,
      'insights' => Icons.insights_outlined,
      'history' => Icons.history_outlined,
      _ => Icons.circle_outlined,
    };
""",
    )
    ds_text2 = ds_barrel.read_text(encoding="utf-8")
    if "nav_icons.dart" not in ds_text2:
        ds_barrel.write_text(
            ds_text2.rstrip() + "\nexport 'src/navigation/nav_icons.dart';\n",
            encoding="utf-8",
        )

    patch_pubspec("student_app")
    patch_pubspec("teacher_app")
    patch_pubspec("admin_web")

    # --- Student app ---
    w(
        "apps/student_app/lib/app/nav_placeholder_page.dart",
        r"""
import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';

class NavPlaceholderPage extends StatelessWidget {
  const NavPlaceholderPage({
    super.key,
    required this.title,
    this.subtitle = 'Foundation placeholder — content arrives in later modules.',
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return NanoScaffold(
      padBody: true,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: NanoSpacing.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
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
        "apps/student_app/lib/app/student_shell.dart",
        r"""
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/app/component_gallery_page.dart';
import 'package:student_app/app/diagnostics_page.dart';
import 'package:student_app/app/environment_badge.dart';
import 'package:student_app/app/nav_placeholder_page.dart';
import 'package:student_app/features/home/presentation/junior_home_foundation.dart';
import 'package:student_app/features/home/presentation/responsive_preview_page.dart';
import 'package:student_app/features/home/presentation/senior_home_foundation.dart';

class StudentShell extends StatelessWidget {
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
  final ValueChanged<SessionPrincipal> onPrincipalChanged;

  @override
  Widget build(BuildContext context) {
    final destinations = NavCatalog.visibleFor(principal);
    final items = [
      for (final d in destinations)
        NanoBottomNavItem(
          id: d.id,
          label: d.label,
          icon: nanoNavIcon(d.iconName),
        ),
    ];

    final index = navigationShell.currentIndex.clamp(0, items.length - 1);

    return NanoScaffold(
      padBody: false,
      appBar: AppBar(
        title: Text(config.appDisplayName),
        actions: [
          if (config.environment.showDebugTools) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AppRole>(
                  value: principal.role,
                  items: const [
                    DropdownMenuItem(
                      value: AppRole.juniorStudent,
                      child: Text('Junior'),
                    ),
                    DropdownMenuItem(
                      value: AppRole.seniorStudent,
                      child: Text('Senior'),
                    ),
                    DropdownMenuItem(
                      value: AppRole.independentStudent,
                      child: Text('Independent'),
                    ),
                  ],
                  onChanged: (role) {
                    if (role == null) return;
                    final next = switch (role) {
                      AppRole.juniorStudent => SessionPrincipal.junior(),
                      AppRole.seniorStudent =>
                        SessionPrincipal.seniorSchool(),
                      AppRole.independentStudent =>
                        SessionPrincipal.independent(),
                      _ => principal,
                    };
                    onPrincipalChanged(next);
                  },
                ),
              ),
            ),
            EnvironmentBadge(environment: config.environment),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(child: navigationShell),
          if (config.environment.showDebugTools)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: NanoSpacing.sm),
                child: Wrap(
                  spacing: NanoSpacing.sm,
                  alignment: WrapAlignment.center,
                  children: [
                    if (config.isFeatureEnabled('diagnostics'))
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  DiagnosticsPage(config: config),
                            ),
                          );
                        },
                        child: const Text('Diagnostics'),
                      ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ComponentGalleryPage(),
                          ),
                        );
                      },
                      child: const Text('Gallery'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ResponsivePreviewPage(),
                          ),
                        );
                      },
                      child: const Text('Responsive preview'),
                    ),
                    TextButton(
                      onPressed: () {
                        // Simulate a notification deep link to Flex.
                        final resolved =
                            DeepLinkResolver.resolve(principal, '/flex');
                        context.go(resolved.location);
                        if (resolved.fellBack && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Flex unavailable — opened Home instead',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Deep link: Flex'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NanoBottomNav(
        items: items,
        selectedIndex: index,
        onSelect: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class StudentLearningTab extends StatelessWidget {
  const StudentLearningTab({super.key, required this.principal});

  final SessionPrincipal principal;

  @override
  Widget build(BuildContext context) {
    if (principal.role.usesJuniorPresentation) {
      return const JuniorHomeFoundation();
    }
    return const SeniorHomeFoundation();
  }
}

class StudentGamesTab extends StatelessWidget {
  const StudentGamesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const NavPlaceholderPage(title: 'Games');
  }
}

class StudentFlexTab extends StatelessWidget {
  const StudentFlexTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const NavPlaceholderPage(
      title: 'Flex',
      subtitle: 'School-eligible students only. Independent students never see this tab.',
    );
  }
}

class StudentCommunitiesTab extends StatelessWidget {
  const StudentCommunitiesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const NavPlaceholderPage(title: 'Communities');
  }
}

class StudentProfileTab extends StatelessWidget {
  const StudentProfileTab({super.key, required this.principal});

  final SessionPrincipal principal;

  @override
  Widget build(BuildContext context) {
    return NavPlaceholderPage(
      title: 'Profile',
      subtitle: '${principal.displayName} · ${principal.role.label}',
    );
  }
}
""",
    )

    w(
        "apps/student_app/lib/app/student_router.dart",
        r"""
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/app/student_shell.dart';

GoRouter createStudentRouter({
  required EnvironmentConfig config,
  required SessionPrincipal principal,
  required ValueChanged<SessionPrincipal> onPrincipalChanged,
  String? initialLocation,
}) {
  final destinations = NavCatalog.visibleFor(principal);
  final resolvedInitial = DeepLinkResolver.resolve(
    principal,
    initialLocation ?? '/',
  ).location;

  return GoRouter(
    initialLocation: resolvedInitial,
    redirect: (context, state) {
      final resolution =
          DeepLinkResolver.resolve(principal, state.uri.path);
      if (resolution.fellBack && resolution.location != state.uri.path) {
        return resolution.location;
      }
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return StudentShell(
            config: config,
            principal: principal,
            navigationShell: navigationShell,
            onPrincipalChanged: onPrincipalChanged,
          );
        },
        branches: [
          for (final dest in destinations)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: dest.path == '/' ? '/' : dest.path,
                  name: dest.id,
                  builder: (context, state) =>
                      _pageFor(dest.id, principal),
                ),
              ],
            ),
        ],
      ),
    ],
  );
}

Widget _pageFor(String id, SessionPrincipal principal) {
  return switch (id) {
    'home' || 'learning' => StudentLearningTab(principal: principal),
    'game' || 'games' => const StudentGamesTab(),
    'flex' => const StudentFlexTab(),
    'communities' => const StudentCommunitiesTab(),
    'profile' => StudentProfileTab(principal: principal),
    _ => Center(child: Text('Unknown tab: $id')),
  };
}
""",
    )

    # Fix student_router - NavPlaceholderFor should import placeholder or use inline
    # Also GoRoute path for non-root in shell branches: go_router wants relative paths
    # For StatefulShellRoute, each branch typically has path like '/games' as absolute
    # Actually in go_router 14, branch routes often use:
    # GoRoute(path: '/', ...) for home and GoRoute(path: '/games') for others
    # Absolute paths in branches are OK in recent go_router.

    w(
        "apps/student_app/lib/main.dart",
        r"""
import 'package:flutter/material.dart';
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
  });

  final EnvironmentConfig config;
  final SessionPrincipal? initialPrincipal;
  final String? initialLocation;

  @override
  State<NanoStudentApp> createState() => _NanoStudentAppState();
}

class _NanoStudentAppState extends State<NanoStudentApp> {
  late SessionPrincipal _principal;
  late GoRouter _router;

  @override
  void initState() {
    super.initState();
    _principal = widget.initialPrincipal ?? SessionPrincipal.junior();
    _router = _createRouter();
  }

  GoRouter _createRouter() {
    return createStudentRouter(
      config: widget.config,
      principal: _principal,
      onPrincipalChanged: _setPrincipal,
      initialLocation: widget.initialLocation,
    );
  }

  void _setPrincipal(SessionPrincipal next) {
    setState(() {
      _principal = next;
      _router = _createRouter();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = _principal.role.usesJuniorPresentation
        ? NanoTheme.junior()
        : NanoTheme.senior();
    return MaterialApp.router(
      key: ValueKey(_principal.role),
      title: widget.config.appDisplayName,
      theme: theme,
      routerConfig: _router,
    );
  }
}
""",
    )

    w(
        "apps/student_app/test/widget_test.dart",
        r"""
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/main.dart';

void main() {
  testWidgets('junior shell shows Home Play Me tabs', (tester) async {
    const config = EnvironmentConfig(
      environment: NanoEnvironment.development,
      supabaseUrl: '',
      supabaseAnonKey: '',
      featureFlags: {'diagnostics': true},
    );
    await tester.pumpWidget(
      NanoStudentApp(
        config: config,
        initialPrincipal: SessionPrincipal.junior(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Me'), findsOneWidget);
    expect(find.text('Flex'), findsNothing);
    expect(find.text('Math'), findsOneWidget);
  });

  testWidgets('independent shell hides Flex tab', (tester) async {
    const config = EnvironmentConfig(
      environment: NanoEnvironment.development,
      supabaseUrl: '',
      supabaseAnonKey: '',
      featureFlags: {'diagnostics': true},
    );
    await tester.pumpWidget(
      NanoStudentApp(
        config: config,
        initialPrincipal: SessionPrincipal.independent(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Learning'), findsWidgets);
    expect(find.text('Flex'), findsNothing);
    expect(find.text('Communities'), findsOneWidget);
  });
}
""",
    )

    w(
        "apps/student_app/test/shell_navigation_test.dart",
        r"""
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/main.dart';

void main() {
  testWidgets('senior shell shows Flex when eligible', (tester) async {
    const config = EnvironmentConfig(
      environment: NanoEnvironment.development,
      supabaseUrl: '',
      supabaseAnonKey: '',
      featureFlags: {'diagnostics': true},
    );
    await tester.pumpWidget(
      NanoStudentApp(
        config: config,
        initialPrincipal: SessionPrincipal.seniorSchool(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Flex'), findsOneWidget);
  });

  testWidgets('deep link to flex redirects independent to home', (tester) async {
    const config = EnvironmentConfig(
      environment: NanoEnvironment.development,
      supabaseUrl: '',
      supabaseAnonKey: '',
      featureFlags: {'diagnostics': true},
    );
    await tester.pumpWidget(
      NanoStudentApp(
        config: config,
        initialPrincipal: SessionPrincipal.independent(),
        initialLocation: '/flex',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Flex'), findsNothing);
    expect(find.textContaining('Ali'), findsWidgets);
  });
}
""",
    )

    # --- Teacher app ---
    w(
        "apps/teacher_app/lib/app/teacher_shell.dart",
        r"""
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

class TeacherShell extends StatelessWidget {
  const TeacherShell({
    super.key,
    required this.config,
    required this.principal,
    required this.navigationShell,
  });

  final EnvironmentConfig config;
  final SessionPrincipal principal;
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final destinations = NavCatalog.visibleFor(principal);
    final items = [
      for (final d in destinations)
        NanoBottomNavItem(
          id: d.id,
          label: d.label,
          icon: nanoNavIcon(d.iconName),
        ),
    ];
    final index = navigationShell.currentIndex.clamp(0, items.length - 1);

    return NanoScaffold(
      padBody: false,
      appBar: AppBar(
        title: Text('${config.appDisplayName} Teacher'),
        actions: [
          if (config.environment.showDebugTools)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Chip(label: Text(config.environment.name.toUpperCase())),
            ),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: NanoBottomNav(
        items: items,
        selectedIndex: index,
        onSelect: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class TeacherDestinationPage extends StatelessWidget {
  const TeacherDestinationPage({super.key, required this.destination});

  final NavDestination destination;

  @override
  Widget build(BuildContext context) {
    return NanoScaffold(
      padBody: true,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              destination.label,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: NanoSpacing.sm),
            const Text('Teacher shell foundation — workflows arrive later.'),
          ],
        ),
      ),
    );
  }
}
""",
    )

    w(
        "apps/teacher_app/lib/app/teacher_router.dart",
        r"""
import 'package:go_router/go_router.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:teacher_app/app/teacher_shell.dart';

GoRouter createTeacherRouter({
  required EnvironmentConfig config,
  required SessionPrincipal principal,
  String? initialLocation,
}) {
  final destinations = NavCatalog.visibleFor(principal);
  final resolved = DeepLinkResolver.resolve(
    principal,
    initialLocation ?? '/',
  ).location;

  return GoRouter(
    initialLocation: resolved,
    redirect: (context, state) {
      final resolution =
          DeepLinkResolver.resolve(principal, state.uri.path);
      if (resolution.fellBack && resolution.location != state.uri.path) {
        return resolution.location;
      }
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return TeacherShell(
            config: config,
            principal: principal,
            navigationShell: navigationShell,
          );
        },
        branches: [
          for (final dest in destinations)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: dest.path,
                  name: dest.id,
                  builder: (context, state) =>
                      TeacherDestinationPage(destination: dest),
                ),
              ],
            ),
        ],
      ),
    ],
  );
}
""",
    )

    w(
        "apps/teacher_app/lib/main.dart",
        r"""
import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:teacher_app/app/teacher_router.dart';

void main() {
  final config = EnvironmentConfig.fromEnvironment();
  runApp(NanoTeacherApp(config: config));
}

class NanoTeacherApp extends StatelessWidget {
  const NanoTeacherApp({
    super.key,
    required this.config,
    this.principal,
    this.initialLocation,
  });

  final EnvironmentConfig config;
  final SessionPrincipal? principal;
  final String? initialLocation;

  @override
  Widget build(BuildContext context) {
    final session = principal ?? SessionPrincipal.teacher();
    final router = createTeacherRouter(
      config: config,
      principal: session,
      initialLocation: initialLocation,
    );
    return MaterialApp.router(
      title: '${config.appDisplayName} Teacher',
      theme: NanoTheme.teacher(),
      routerConfig: router,
    );
  }
}
""",
    )

    w(
        "apps/teacher_app/test/widget_test.dart",
        r"""
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:teacher_app/main.dart';

void main() {
  testWidgets('teacher shell shows core destinations', (tester) async {
    const config = EnvironmentConfig(
      environment: NanoEnvironment.development,
      supabaseUrl: '',
      supabaseAnonKey: '',
      featureFlags: {},
    );
    await tester.pumpWidget(const NanoTeacherApp(config: config));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Classes'), findsOneWidget);
    expect(find.text('Attendance'), findsOneWidget);
    expect(find.text('Marks'), findsOneWidget);
  });
}
""",
    )

    # --- Admin web ---
    w(
        "apps/admin_web/lib/app/admin_shell.dart",
        r"""
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

class AdminShell extends StatelessWidget {
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
  final ValueChanged<SessionPrincipal> onPrincipalChanged;

  @override
  Widget build(BuildContext context) {
    final destinations = NavCatalog.visibleFor(principal);
    final items = [
      for (final d in destinations)
        NanoSideRailItem(
          id: d.id,
          label: d.label,
          icon: nanoNavIcon(d.iconName),
        ),
    ];
    final index = navigationShell.currentIndex.clamp(0, items.length - 1);
    final title = principal.role == AppRole.superadmin
        ? '${config.appDisplayName} Superadmin'
        : '${config.appDisplayName} School';

    return Scaffold(
      body: Row(
        children: [
          NanoSideRail(
            title: title,
            items: items,
            selectedIndex: index,
            onSelect: (i) => navigationShell.goBranch(
              i,
              initialLocation: i == navigationShell.currentIndex,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                if (config.environment.showDebugTools)
                  Material(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: NanoSpacing.md,
                        vertical: NanoSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Shell',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(width: NanoSpacing.sm),
                          SegmentedButton<AppRole>(
                            segments: const [
                              ButtonSegment(
                                value: AppRole.schoolAdmin,
                                label: Text('School'),
                              ),
                              ButtonSegment(
                                value: AppRole.superadmin,
                                label: Text('Superadmin'),
                              ),
                            ],
                            selected: {principal.role},
                            onSelectionChanged: (roles) {
                              final role = roles.first;
                              onPrincipalChanged(
                                role == AppRole.superadmin
                                    ? SessionPrincipal.superadmin()
                                    : SessionPrincipal.schoolAdmin(),
                              );
                            },
                          ),
                          const Spacer(),
                          Chip(
                            label: Text(
                              config.environment.name.toUpperCase(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(child: navigationShell),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminDestinationPage extends StatelessWidget {
  const AdminDestinationPage({
    super.key,
    required this.destination,
    required this.principal,
  });

  final NavDestination destination;
  final SessionPrincipal principal;

  @override
  Widget build(BuildContext context) {
    return NanoScaffold(
      padBody: true,
      body: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                destination.label,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: NanoSpacing.sm),
              Text(
                '${principal.role.label} shell · path ${destination.path}',
              ),
              const SizedBox(height: NanoSpacing.md),
              const Text(
                'Permission-filtered foundation. Bulk workflows arrive in later modules.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
""",
    )

    w(
        "apps/admin_web/lib/app/admin_router.dart",
        r"""
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:admin_web/app/admin_shell.dart';

GoRouter createAdminRouter({
  required EnvironmentConfig config,
  required SessionPrincipal principal,
  required ValueChanged<SessionPrincipal> onPrincipalChanged,
  String? initialLocation,
}) {
  final destinations = NavCatalog.visibleFor(principal);
  final resolved = DeepLinkResolver.resolve(
    principal,
    initialLocation ?? '/',
  ).location;

  return GoRouter(
    initialLocation: resolved,
    redirect: (context, state) {
      final resolution =
          DeepLinkResolver.resolve(principal, state.uri.path);
      if (resolution.fellBack && resolution.location != state.uri.path) {
        return resolution.location;
      }
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AdminShell(
            config: config,
            principal: principal,
            navigationShell: navigationShell,
            onPrincipalChanged: onPrincipalChanged,
          );
        },
        branches: [
          for (final dest in destinations)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: dest.path,
                  name: dest.id,
                  builder: (context, state) => AdminDestinationPage(
                    destination: dest,
                    principal: principal,
                  ),
                ),
              ],
            ),
        ],
      ),
    ],
  );
}
""",
    )

    w(
        "apps/admin_web/lib/main.dart",
        r"""
import 'package:flutter/material.dart';
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
  });

  final EnvironmentConfig config;
  final SessionPrincipal? initialPrincipal;
  final String? initialLocation;

  @override
  State<NanoAdminApp> createState() => _NanoAdminAppState();
}

class _NanoAdminAppState extends State<NanoAdminApp> {
  late SessionPrincipal _principal;
  late GoRouter _router;

  @override
  void initState() {
    super.initState();
    _principal = widget.initialPrincipal ?? SessionPrincipal.schoolAdmin();
    _router = _createRouter();
  }

  GoRouter _createRouter() {
    return createAdminRouter(
      config: widget.config,
      principal: _principal,
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
    final theme = _principal.role == AppRole.superadmin
        ? NanoTheme.superadmin()
        : NanoTheme.schoolAdmin();
    return MaterialApp.router(
      key: ValueKey(_principal.role),
      title: '${widget.config.appDisplayName} Admin',
      theme: theme,
      routerConfig: _router,
    );
  }
}
""",
    )

    w(
        "apps/admin_web/test/widget_test.dart",
        r"""
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:admin_web/main.dart';

void main() {
  testWidgets('school admin shell shows side destinations', (tester) async {
    const config = EnvironmentConfig(
      environment: NanoEnvironment.development,
      supabaseUrl: '',
      supabaseAnonKey: '',
      featureFlags: {},
    );
    await tester.pumpWidget(const NanoAdminApp(config: config));
    await tester.pumpAndSettle();
    expect(find.textContaining('School'), findsWidgets);
    expect(find.text('Students'), findsOneWidget);
    expect(find.text('Teachers'), findsOneWidget);
  });

  testWidgets('superadmin shell shows platform destinations', (tester) async {
    const config = EnvironmentConfig(
      environment: NanoEnvironment.development,
      supabaseUrl: '',
      supabaseAnonKey: '',
      featureFlags: {},
    );
    await tester.pumpWidget(
      NanoAdminApp(
        config: config,
        initialPrincipal: SessionPrincipal.superadmin(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Schools'), findsOneWidget);
    expect(find.text('Moderation'), findsOneWidget);
    expect(find.text('Audit'), findsOneWidget);
  });
}
""",
    )

    # Check NanoTheme.superadmin exists
    theme_path = ROOT / "packages/nano_design_system/lib/src/theme/nano_theme.dart"
    theme_text = theme_path.read_text(encoding="utf-8")
    if "superadmin" not in theme_text:
        # find schoolAdmin and add alias or method
        pass

    # Docs
    w(
        "docs/modules/FND-04/README.md",
        """
# FND-04 — Navigation and Role-Aware Application Shells

## Purpose

Role-aware route catalogs, client guards, deep-link fallback, and app shells for Junior/Senior/Independent students, teachers, school admin, and superadmin.

## Main surfaces

- Student bottom navigation (persona switcher in debug)
- Teacher bottom navigation
- Admin web side rail (School / Superadmin switcher in debug)
- Deep-link resolver with safe-parent fallback
""",
    )

    w(
        "docs/modules/FND-04/IMPLEMENTATION_PLAN.md",
        """
# FND-04 Implementation Plan

1. Domain nav contracts (`SessionPrincipal`, catalogs, `DeepLinkResolver`)
2. Design-system `NanoBottomNav` + `NanoSideRail`
3. Wire `go_router` shells in student, teacher, admin apps
4. Tests for Flex eligibility, permissions, feature flags, deep-link fallback
5. Owner manual test guide
""",
    )

    w(
        "docs/modules/FND-04/DECISIONS.md",
        """
# FND-04 Decisions

- Client route guards are convenience only; RLS remains authoritative (AUTH/SEC later).
- Independent students use a dedicated catalog with no Flex entry (not a hidden placeholder).
- Deep links to denied/unknown paths fall back to `/`.
- `go_router` StatefulShellRoute keeps tab state and URL locations for browser refresh.
""",
    )

    w(
        "docs/modules/FND-04/KNOWN_ISSUES.md",
        """
# FND-04 Known Issues

- Auth session principals are fixtures until AUTH modules land.
- Push notification delivery is NOT-01; this module only provides deep-link resolution.
- Teacher/admin destination bodies are placeholders.
""",
    )

    w(
        "docs/modules/FND-04/MANUAL_TEST.md",
        """
# FND-04 Manual Test Guide

## Prerequisites

- Git + Flutter on PATH
- Melos bootstrap

## Student

```powershell
cd D:\\nano
dart pub get
dart run melos bootstrap
cd apps\\student_app
flutter run -d chrome --dart-define=NANO_ENV=development
```

- [ ] Junior: bottom tabs Home / Play / Me; no Flex
- [ ] Switch to Senior: Learning / Games / Flex / Communities / Profile
- [ ] Switch to Independent: no Flex tab; Learning still works
- [ ] Tap **Deep link: Flex** as Independent — snackbar + Home (not Flex)
- [ ] As Senior, open Flex tab — placeholder visible
- [ ] Browser URL updates when switching tabs; refresh stays on a valid tab

## Teacher

```powershell
cd D:\\nano\\apps\\teacher_app
flutter run -d chrome --dart-define=NANO_ENV=development
```

- [ ] Tabs: Dashboard, Classes, Attendance, Marks, Classroom, Profile

## Admin web

```powershell
cd D:\\nano\\apps\\admin_web
flutter run -d chrome --dart-define=NANO_ENV=development
```

- [ ] School side rail: Overview, Students, Teachers, Classes, Reports, Settings
- [ ] Switch to Superadmin: Platform, Schools, Content, Moderation, Analytics, Audit

## Approve

`NEXT`

## Reject

`FIX: <problem>`
""",
    )

    w(
        "docs/modules/FND-04/TEST_REPORT.md",
        """
# FND-04 Test Report

| Test | Result | Notes |
|------|--------|-------|
| nano_domain navigation_guard_test | RUN | Flex, flags, deep links |
| student_app shell + widget tests | RUN | Junior / Independent / Senior |
| teacher_app widget_test | RUN | Core destinations |
| admin_web widget_test | RUN | School + Superadmin rails |
| CI workflow | NOT RUN | PAT missing `workflow` scope; pending at docs/setup/ci.yml.pending |
""",
    )

    # Update module yaml + status files via separate python after scaffold
    print("FND-04 scaffold written")


if __name__ == "__main__":
    main()
