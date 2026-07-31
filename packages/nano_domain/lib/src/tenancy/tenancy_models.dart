/// Tenancy domain models (SEC-02).
enum SchoolStatus { active, suspended, archived }

enum MembershipRole { student, teacher, schoolAdmin }

enum MembershipStatus { active, suspended, left }

enum AccountKind {
  schoolStudent,
  independentStudent,
  teacher,
  schoolStaff,
  platform,
}

class School {
  const School({
    required this.id,
    required this.code,
    required this.name,
    required this.status,
  });

  final String id;
  final String code;
  final String name;
  final SchoolStatus status;
}

class Profile {
  const Profile({
    required this.id,
    required this.displayName,
    required this.accountKind,
    required this.status,
  });

  final String id;
  final String displayName;
  final AccountKind accountKind;
  final MembershipStatus status;

  bool get isIndependentStudent =>
      accountKind == AccountKind.independentStudent;
}

class SchoolMembership {
  const SchoolMembership({
    required this.id,
    required this.schoolId,
    required this.userId,
    required this.role,
    required this.status,
  });

  final String id;
  final String schoolId;
  final String userId;
  final MembershipRole role;
  final MembershipStatus status;
}

/// Deterministic fixture IDs matching SEC-02 seed rows.
abstract final class TenancyFixtures {
  static const alphaSchoolId = '11111111-1111-1111-1111-111111111111';
  static const betaSchoolId = '22222222-2222-2222-2222-222222222222';
  static const aliAlphaId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  static const binaBetaId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  static const teacherId = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
  static const platformAdminId = 'dddddddd-dddd-dddd-dddd-dddddddddddd';
  static const indieId = 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee';
  static const schoolAdminId = 'ffffffff-ffff-ffff-ffff-ffffffffffff';

  static const alpha = School(
    id: alphaSchoolId,
    code: 'ALPHA01',
    name: 'Alpha Academy',
    status: SchoolStatus.active,
  );

  static const beta = School(
    id: betaSchoolId,
    code: 'BETA02',
    name: 'Beta School',
    status: SchoolStatus.active,
  );
}
