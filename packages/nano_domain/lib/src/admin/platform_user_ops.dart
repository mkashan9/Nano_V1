import '../tenancy/tenancy_models.dart';

/// ADM-03 safe user row for platform search — no contact or school marks.
class PlatformUserSummary {
  const PlatformUserSummary({
    required this.id,
    required this.displayName,
    required this.accountKind,
    required this.status,
    this.schoolSummaries = const [],
    this.activeSessionCount = 0,
  });

  final String id;
  final String displayName;
  final AccountKind accountKind;
  final MembershipStatus status;
  final List<UserSchoolSummary> schoolSummaries;
  final int activeSessionCount;

  bool get isSuspended => status == MembershipStatus.suspended;

  factory PlatformUserSummary.fromJson(Map<String, dynamic> json) {
    if (!_privacySafe(json)) {
      throw StateError('User summary failed privacy review.');
    }
    final schoolsRaw = json['schools'];
    return PlatformUserSummary(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      accountKind: _kindFrom(json['account_kind'] as String? ?? ''),
      status: _statusFrom(json['status'] as String? ?? 'active'),
      activeSessionCount: (json['active_session_count'] as num?)?.toInt() ?? 0,
      schoolSummaries: [
        if (schoolsRaw is List)
          for (final row in schoolsRaw.whereType<Map>())
            UserSchoolSummary.fromJson(Map<String, dynamic>.from(row)),
      ],
    );
  }

  static bool _privacySafe(Map<String, dynamic> row) {
    const forbidden = {
      'email',
      'guardian',
      'guardian_contact',
      'phone',
      'attendance',
      'marks',
      'latest_mark',
      'payment',
    };
    for (final key in row.keys) {
      if (forbidden.contains(key.toLowerCase())) return false;
    }
    return true;
  }

  static AccountKind _kindFrom(String value) => switch (value) {
        'independent_student' => AccountKind.independentStudent,
        'teacher' => AccountKind.teacher,
        'school_staff' => AccountKind.schoolStaff,
        'platform' => AccountKind.platform,
        _ => AccountKind.schoolStudent,
      };

  static MembershipStatus _statusFrom(String value) => switch (value) {
        'suspended' => MembershipStatus.suspended,
        'left' => MembershipStatus.left,
        _ => MembershipStatus.active,
      };
}

class UserSchoolSummary {
  const UserSchoolSummary({
    required this.schoolId,
    required this.schoolCode,
    required this.role,
    required this.status,
  });

  final String schoolId;
  final String schoolCode;
  final MembershipRole role;
  final MembershipStatus status;

  factory UserSchoolSummary.fromJson(Map<String, dynamic> json) {
    return UserSchoolSummary(
      schoolId: json['school_id'] as String? ?? '',
      schoolCode: json['school_code'] as String? ?? '',
      role: switch (json['role'] as String? ?? 'student') {
        'teacher' => MembershipRole.teacher,
        'school_admin' => MembershipRole.schoolAdmin,
        _ => MembershipRole.student,
      },
      status: switch (json['status'] as String? ?? 'active') {
        'suspended' => MembershipStatus.suspended,
        'left' => MembershipStatus.left,
        _ => MembershipStatus.active,
      },
    );
  }
}

extension MembershipStatusWire on MembershipStatus {
  String get wireName => switch (this) {
        MembershipStatus.active => 'active',
        MembershipStatus.suspended => 'suspended',
        MembershipStatus.left => 'left',
      };
}
