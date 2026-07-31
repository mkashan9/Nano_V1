import 'package:nano_domain/nano_domain.dart';

/// AUTH fixture credentials (development only).
abstract final class AuthFixtures {
  static const aliEmail = 'ali@alpha.nano.dev';
  static const aliPassword = 'NanoAliDev1!';
  static const aliUserId = TenancyFixtures.aliAlphaId;
  static const aliSchoolId = TenancyFixtures.alphaSchoolId;

  static const teacherEmail = 'teacher@alpha.nano.dev';
  static const teacherPassword = 'NanoTeacherDev1!';
  static const teacherUserId = TenancyFixtures.teacherId;
  static const teacherSchoolId = TenancyFixtures.alphaSchoolId;

  static const platformEmail = 'platform@nano.dev';
  static const platformPassword = 'NanoPlatformDev1!';
  static const platformUserId = TenancyFixtures.platformAdminId;

  static const schoolAdminEmail = 'admin@alpha.nano.dev';
  static const schoolAdminPassword = 'NanoSchoolAdminDev1!';
  static const schoolAdminUserId = TenancyFixtures.schoolAdminId;
  static const schoolAdminSchoolId = TenancyFixtures.alphaSchoolId;
}

/// Result of resolving profile + membership after auth.users session exists.
class AuthBootstrap {
  const AuthBootstrap({
    required this.principal,
    required this.schoolStatus,
    required this.profileStatus,
    required this.membershipStatus,
  });

  final SessionPrincipal principal;
  final SchoolStatus schoolStatus;
  final MembershipStatus profileStatus;
  final MembershipStatus membershipStatus;

  bool get isBlocked =>
      AccessGuard.evaluate(
        schoolStatus: schoolStatus,
        membershipStatus: membershipStatus,
        profileStatus: profileStatus,
        sessionRevoked: false,
      ).allowed ==
      false;
}

abstract class AuthRepository {
  Future<AuthBootstrap> signInWithPassword({
    required String email,
    required String password,
  });

  Future<AuthBootstrap?> restoreSession();

  Future<void> signOut();

  Stream<bool> get authStateChanges;
}
