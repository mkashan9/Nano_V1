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
      id: 'learning',
      label: 'Learn',
      path: '/learning',
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
      id: 'profile',
      label: 'Profile',
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
      id: 'feedback',
      label: 'Feedback',
      path: '/feedback',
      iconName: 'feedback',
      requiredPermission: 'teacher.feedback',
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
      id: 'assignments',
      label: 'Assignments',
      path: '/assignments',
      iconName: 'fact_check',
      requiredPermission: 'school.assignments',
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
      id: 'users',
      label: 'Users',
      path: '/users',
      iconName: 'badge',
      requiredPermission: 'platform.users',
    ),
    NavDestination(
      id: 'content',
      label: 'Content',
      path: '/content',
      iconName: 'library_books',
      requiredPermission: 'platform.content',
    ),
    NavDestination(
      id: 'gamification',
      label: 'Gamification',
      path: '/gamification',
      iconName: 'emoji_events',
      requiredPermission: 'platform.gamification',
    ),
    NavDestination(
      id: 'gameAdmin',
      label: 'Games',
      path: '/game-admin',
      iconName: 'sports_esports',
      requiredPermission: 'platform.games',
    ),
    NavDestination(
      id: 'notifications',
      label: 'Notifications',
      path: '/notifications',
      iconName: 'notifications',
      requiredPermission: 'platform.notifications',
    ),
    NavDestination(
      id: 'parentGuidance',
      label: 'Parent guidance',
      path: '/parent-guidance',
      iconName: 'family_restroom',
      requiredPermission: 'platform.parentGuidance',
    ),
    NavDestination(
      id: 'moderation',
      label: 'Moderation',
      path: '/moderation',
      iconName: 'gavel',
      requiredPermission: 'platform.moderation',
    ),
    NavDestination(
      id: 'communityControls',
      label: 'Community controls',
      path: '/community-controls',
      iconName: 'groups',
      requiredPermission: 'platform.communities',
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
      label: 'Security',
      path: '/audit',
      iconName: 'history',
      requiredPermission: 'platform.audit',
    ),
    NavDestination(
      id: 'pilot',
      label: 'Pilot',
      path: '/pilot',
      iconName: 'fact_check',
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
