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
