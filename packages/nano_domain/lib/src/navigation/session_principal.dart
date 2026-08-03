import '../onboarding/onboarding_models.dart';
import '../tenancy/tenancy_models.dart';
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
    this.userId,
    this.schoolId,
    this.isAuthenticated = false,
    this.experienceTrack,
  });

  final AppRole role;
  final String displayName;
  final Set<String> permissions;
  final Map<String, bool> featureFlags;
  final bool flexEligible;
  final String? userId;
  final String? schoolId;
  final bool isAuthenticated;

  /// Which experience this learner is on, once onboarding has decided.
  ///
  /// Separate from [role] because the two answer different questions: the role
  /// is what a learner is entitled to, the track is how it should look. An
  /// independent learner can be six years old, and role alone cannot say so —
  /// every independent account is [AppRole.independentStudent] whatever their
  /// grade. Null means nobody has decided yet, and the role is the best guess
  /// available.
  final ExperienceTrack? experienceTrack;

  /// Whether this learner sees the Junior experience.
  ///
  /// The track wins when it is known, because it is the answer onboarding
  /// actually recorded; the role is the fallback for a session that has not
  /// loaded it yet.
  bool get usesJuniorPresentation => switch (experienceTrack) {
        ExperienceTrack.junior => true,
        ExperienceTrack.senior => false,
        null => role.usesJuniorPresentation,
      };

  bool hasPermission(String permission) => permissions.contains(permission);

  bool isFeatureEnabled(String flag) => featureFlags[flag] ?? false;

  String get homePath => '/';

  SessionPrincipal copyWith({
    AppRole? role,
    String? displayName,
    Set<String>? permissions,
    Map<String, bool>? featureFlags,
    bool? flexEligible,
    String? userId,
    String? schoolId,
    bool? isAuthenticated,
    ExperienceTrack? experienceTrack,
  }) {
    return SessionPrincipal(
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      permissions: permissions ?? this.permissions,
      featureFlags: featureFlags ?? this.featureFlags,
      flexEligible: flexEligible ?? this.flexEligible,
      userId: userId ?? this.userId,
      schoolId: schoolId ?? this.schoolId,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      experienceTrack: experienceTrack ?? this.experienceTrack,
    );
  }

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
          'teacher.feedback',
          'teacher.profile',
        },
      );

  factory SessionPrincipal.schoolAdmin({
    String displayName = 'School Admin',
    String? schoolId = TenancyFixtures.alphaSchoolId,
  }) =>
      SessionPrincipal(
        role: AppRole.schoolAdmin,
        displayName: displayName,
        schoolId: schoolId,
        permissions: const {
          'school.overview',
          'school.students',
          'school.teachers',
          'school.assignments',
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
          'platform.users',
          'platform.content',
          'platform.gamification',
          'platform.games',
          'platform.notifications',
          'platform.parentGuidance',
          'platform.moderation',
          'platform.communities',
          'platform.analytics',
          'platform.audit',
        },
      );
}
