import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// ADM-03 platform user search and privileged account actions.
abstract class PlatformUserRepository {
  Future<List<PlatformUserSummary>> search({String query = ''});

  Future<PlatformUserSummary> setProfileStatus({
    required String userId,
    required MembershipStatus status,
    required String reason,
  });

  Future<void> replaceSchoolAdmin({
    required String schoolId,
    required String newUserId,
    required String reason,
  });

  /// Revokes all active sessions when [sessionId] is null.
  Future<int> revokeSessions({
    required String userId,
    required String reason,
    String? sessionId,
  });
}

class FakePlatformUserRepository implements PlatformUserRepository {
  FakePlatformUserRepository({List<PlatformUserSummary>? seed})
      : _users = List.of(
          seed ??
              [
                PlatformUserSummary(
                  id: TenancyFixtures.aliAlphaId,
                  displayName: 'Ali',
                  accountKind: AccountKind.schoolStudent,
                  status: MembershipStatus.active,
                  activeSessionCount: 1,
                  schoolSummaries: const [
                    UserSchoolSummary(
                      schoolId: TenancyFixtures.alphaSchoolId,
                      schoolCode: 'ALPHA01',
                      role: MembershipRole.student,
                      status: MembershipStatus.active,
                    ),
                  ],
                ),
                PlatformUserSummary(
                  id: TenancyFixtures.schoolAdminId,
                  displayName: 'Alpha Admin',
                  accountKind: AccountKind.schoolStaff,
                  status: MembershipStatus.active,
                  activeSessionCount: 1,
                  schoolSummaries: const [
                    UserSchoolSummary(
                      schoolId: TenancyFixtures.alphaSchoolId,
                      schoolCode: 'ALPHA01',
                      role: MembershipRole.schoolAdmin,
                      status: MembershipStatus.active,
                    ),
                  ],
                ),
                PlatformUserSummary(
                  id: TenancyFixtures.teacherId,
                  displayName: 'Teacher',
                  accountKind: AccountKind.teacher,
                  status: MembershipStatus.active,
                  activeSessionCount: 0,
                  schoolSummaries: const [
                    UserSchoolSummary(
                      schoolId: TenancyFixtures.alphaSchoolId,
                      schoolCode: 'ALPHA01',
                      role: MembershipRole.teacher,
                      status: MembershipStatus.active,
                    ),
                  ],
                ),
              ],
        );

  final List<PlatformUserSummary> _users;
  final statusReasons = <String>[];
  final replaceReasons = <String>[];
  final revokeReasons = <String>[];
  var revokedSessionCount = 0;

  @override
  Future<List<PlatformUserSummary>> search({String query = ''}) async {
    final q = query.trim().toLowerCase();
    return [
      for (final user in _users)
        if (q.isEmpty ||
            user.displayName.toLowerCase().contains(q) ||
            user.id.toLowerCase().contains(q))
          user,
    ];
  }

  @override
  Future<PlatformUserSummary> setProfileStatus({
    required String userId,
    required MembershipStatus status,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw StateError('A reason is required.');
    }
    if (status != MembershipStatus.active &&
        status != MembershipStatus.suspended) {
      throw StateError('Only active or suspended is allowed.');
    }
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) throw StateError('User not found.');
    statusReasons.add(reason.trim());
    final current = _users[index];
    final updated = PlatformUserSummary(
      id: current.id,
      displayName: current.displayName,
      accountKind: current.accountKind,
      status: status,
      schoolSummaries: current.schoolSummaries,
      activeSessionCount: current.activeSessionCount,
    );
    _users[index] = updated;
    return updated;
  }

  @override
  Future<void> replaceSchoolAdmin({
    required String schoolId,
    required String newUserId,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw StateError('A reason is required.');
    }
    PlatformUserSummary? newUser;
    for (final user in _users) {
      if (user.id == newUserId) newUser = user;
    }
    if (newUser == null) throw StateError('New admin not found.');
    if (newUser.accountKind == AccountKind.schoolStudent ||
        newUser.accountKind == AccountKind.independentStudent) {
      throw StateError('Only staff accounts can be school administrators.');
    }
    replaceReasons.add(reason.trim());
    var schoolCode = 'ALPHA01';
    for (var i = 0; i < _users.length; i++) {
      final user = _users[i];
      final nextSchools = <UserSchoolSummary>[];
      for (final school in user.schoolSummaries) {
        if (school.schoolId == schoolId) {
          schoolCode = school.schoolCode;
        }
        if (school.schoolId == schoolId &&
            school.role == MembershipRole.schoolAdmin &&
            school.status == MembershipStatus.active) {
          nextSchools.add(
            UserSchoolSummary(
              schoolId: school.schoolId,
              schoolCode: school.schoolCode,
              role: school.role,
              status: MembershipStatus.left,
            ),
          );
        } else {
          nextSchools.add(school);
        }
      }
      if (user.id == newUserId) {
        nextSchools
          ..removeWhere(
            (s) =>
                s.schoolId == schoolId &&
                s.role == MembershipRole.schoolAdmin,
          )
          ..add(
            UserSchoolSummary(
              schoolId: schoolId,
              schoolCode: schoolCode,
              role: MembershipRole.schoolAdmin,
              status: MembershipStatus.active,
            ),
          );
      }
      _users[i] = PlatformUserSummary(
        id: user.id,
        displayName: user.displayName,
        accountKind: user.accountKind,
        status: user.status,
        activeSessionCount: user.activeSessionCount,
        schoolSummaries: nextSchools,
      );
    }
  }

  @override
  Future<int> revokeSessions({
    required String userId,
    required String reason,
    String? sessionId,
  }) async {
    if (reason.trim().isEmpty) {
      throw StateError('A reason is required.');
    }
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) throw StateError('User not found.');
    revokeReasons.add(reason.trim());
    final current = _users[index];
    final count = sessionId == null
        ? current.activeSessionCount
        : (current.activeSessionCount > 0 ? 1 : 0);
    revokedSessionCount += count;
    _users[index] = PlatformUserSummary(
      id: current.id,
      displayName: current.displayName,
      accountKind: current.accountKind,
      status: current.status,
      schoolSummaries: current.schoolSummaries,
      activeSessionCount: sessionId == null
          ? 0
          : (current.activeSessionCount - count).clamp(0, 99),
    );
    return count;
  }
}

class SupabasePlatformUserRepository implements PlatformUserRepository {
  SupabasePlatformUserRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<PlatformUserSummary>> search({String query = ''}) async {
    final raw = await _client.rpc(
      'search_platform_users',
      params: {'p_query': query},
    );
    if (raw is! List) return const [];
    return [
      for (final row in raw.whereType<Map>())
        PlatformUserSummary.fromJson(Map<String, dynamic>.from(row)),
    ];
  }

  @override
  Future<PlatformUserSummary> setProfileStatus({
    required String userId,
    required MembershipStatus status,
    required String reason,
  }) async {
    final raw = await _client.rpc(
      'set_profile_status',
      params: {
        'p_user_id': userId,
        'p_status': status.wireName,
        'p_reason': reason,
      },
    );
    return PlatformUserSummary.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  @override
  Future<void> replaceSchoolAdmin({
    required String schoolId,
    required String newUserId,
    required String reason,
  }) async {
    await _client.rpc(
      'replace_school_admin',
      params: {
        'p_school_id': schoolId,
        'p_new_user_id': newUserId,
        'p_reason': reason,
      },
    );
  }

  @override
  Future<int> revokeSessions({
    required String userId,
    required String reason,
    String? sessionId,
  }) async {
    final raw = await _client.rpc(
      'admin_revoke_user_sessions',
      params: {
        'p_user_id': userId,
        'p_reason': reason,
        'p_session_id': sessionId,
      },
    );
    if (raw is num) return raw.toInt();
    if (raw is Map && raw['revoked_count'] is num) {
      return (raw['revoked_count'] as num).toInt();
    }
    return 0;
  }
}
