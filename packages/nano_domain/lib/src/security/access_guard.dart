import '../tenancy/tenancy_models.dart';

/// Client-side access decision mirroring SEC-03 server guards.
/// Server RLS remains authoritative once AUTH lands.
enum AccessDenialReason {
  none,
  schoolSuspended,
  membershipSuspended,
  profileSuspended,
  sessionRevoked,
  missingPermission,
}

class AccessDecision {
  const AccessDecision.allow()
      : allowed = true,
        reason = AccessDenialReason.none;

  const AccessDecision.deny(this.reason) : allowed = false;

  final bool allowed;
  final AccessDenialReason reason;
}

/// Evaluates school/membership/session suspension and permission checks.
abstract final class AccessGuard {
  static AccessDecision evaluate({
    required SchoolStatus schoolStatus,
    required MembershipStatus membershipStatus,
    required MembershipStatus profileStatus,
    required bool sessionRevoked,
    String? requiredPermission,
    Set<String> permissions = const {},
  }) {
    if (profileStatus != MembershipStatus.active) {
      return const AccessDecision.deny(AccessDenialReason.profileSuspended);
    }
    if (schoolStatus == SchoolStatus.suspended ||
        schoolStatus == SchoolStatus.archived) {
      return const AccessDecision.deny(AccessDenialReason.schoolSuspended);
    }
    if (membershipStatus != MembershipStatus.active) {
      return const AccessDecision.deny(AccessDenialReason.membershipSuspended);
    }
    if (sessionRevoked) {
      return const AccessDecision.deny(AccessDenialReason.sessionRevoked);
    }
    if (requiredPermission != null &&
        !permissions.contains(requiredPermission)) {
      return const AccessDecision.deny(AccessDenialReason.missingPermission);
    }
    return const AccessDecision.allow();
  }
}

class DeviceSession {
  const DeviceSession({
    required this.id,
    required this.userId,
    required this.deviceLabel,
    this.schoolId,
    this.revokedAt,
  });

  final String id;
  final String userId;
  final String? schoolId;
  final String deviceLabel;
  final DateTime? revokedAt;

  bool get isActive => revokedAt == null;
}

class AuditEvent {
  const AuditEvent({
    required this.id,
    required this.action,
    required this.targetType,
    this.actorUserId,
    this.schoolId,
    this.targetId,
    this.reason,
    this.requestId,
  });

  final String id;
  final String action;
  final String targetType;
  final String? actorUserId;
  final String? schoolId;
  final String? targetId;
  final String? reason;
  final String? requestId;
}

/// Fixture IDs matching SEC-03 seed rows.
abstract final class SecurityFixtures {
  static const activeSessionId = 'f1111111-1111-1111-1111-111111111111';
  static const revokedSessionId = 'f2222222-2222-2222-2222-222222222222';
  static const loginEventId = 'e1111111-1111-1111-1111-111111111111';
  static const auditEventId = 'a1111111-1111-1111-1111-111111111111';
  static const incidentId = 'c1111111-1111-1111-1111-111111111111';

  static const activeSession = DeviceSession(
    id: activeSessionId,
    userId: TenancyFixtures.aliAlphaId,
    schoolId: TenancyFixtures.alphaSchoolId,
    deviceLabel: 'Chrome / Windows',
  );

  static final revokedSession = DeviceSession(
    id: revokedSessionId,
    userId: TenancyFixtures.aliAlphaId,
    schoolId: TenancyFixtures.alphaSchoolId,
    deviceLabel: 'Old phone',
    revokedAt: DateTime.utc(2026, 7, 1),
  );
}
