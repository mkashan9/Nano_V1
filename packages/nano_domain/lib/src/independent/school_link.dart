import '../navigation/app_role.dart';
import '../navigation/session_principal.dart';
import '../onboarding/onboarding_models.dart';
import '../tenancy/tenancy_models.dart';

/// IND-04 school invitation preview for an independent learner.
class SchoolInvitePreview {
  const SchoolInvitePreview({
    required this.code,
    required this.schoolId,
    required this.schoolName,
    this.schoolStatus = SchoolStatus.active,
  });

  final String code;
  final String schoolId;
  final String schoolName;
  final SchoolStatus schoolStatus;

  bool get isLinkable => schoolStatus == SchoolStatus.active;

  factory SchoolInvitePreview.fromJson(Map<String, dynamic> json) {
    final statusRaw = '${json['school_status'] ?? 'active'}';
    return SchoolInvitePreview(
      code: (json['code'] as String? ?? '').trim().toUpperCase(),
      schoolId: json['school_id'] as String? ?? '',
      schoolName: json['school_name'] as String? ?? '',
      schoolStatus: switch (statusRaw) {
        'suspended' => SchoolStatus.suspended,
        'archived' => SchoolStatus.archived,
        _ => SchoolStatus.active,
      },
    );
  }
}

/// Result of linking an independent account to a school.
class SchoolLinkResult {
  const SchoolLinkResult({
    required this.schoolId,
    required this.schoolName,
    required this.schoolCode,
    required this.principal,
    this.progressPreserved = true,
  });

  final String schoolId;
  final String schoolName;
  final String schoolCode;
  final SessionPrincipal principal;
  final bool progressPreserved;
}

enum SchoolLinkDenial {
  none,
  notIndependent,
  invalidCode,
  schoolUnavailable,
  alreadyLinked,
}

class SchoolLinkDecision {
  const SchoolLinkDecision.allow()
      : allowed = true,
        reason = SchoolLinkDenial.none;

  const SchoolLinkDecision.deny(this.reason) : allowed = false;

  final bool allowed;
  final SchoolLinkDenial reason;
}

/// Client-side school-link rules. Server remains authoritative when live.
abstract final class SchoolLinkPolicy {
  static String normalizeCode(String raw) =>
      raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');

  static bool looksLikeCode(String raw) {
    final code = normalizeCode(raw);
    return code.length >= 4 && code.length <= 16;
  }

  static SchoolLinkDecision canPreview({
    required AppRole role,
    required String? schoolId,
  }) {
    if (role != AppRole.independentStudent) {
      return const SchoolLinkDecision.deny(SchoolLinkDenial.notIndependent);
    }
    if (schoolId != null && schoolId.isNotEmpty) {
      return const SchoolLinkDecision.deny(SchoolLinkDenial.alreadyLinked);
    }
    return const SchoolLinkDecision.allow();
  }

  static SchoolLinkDecision canLink({
    required AppRole role,
    required String? schoolId,
    required SchoolInvitePreview preview,
  }) {
    final gate = canPreview(role: role, schoolId: schoolId);
    if (!gate.allowed) return gate;
    if (!preview.isLinkable) {
      return const SchoolLinkDecision.deny(SchoolLinkDenial.schoolUnavailable);
    }
    return const SchoolLinkDecision.allow();
  }

  /// After a successful link the learner becomes a school senior by default.
  /// Junior presentation still follows [ExperienceTrack] when known.
  static SessionPrincipal linkedPrincipal(
    SessionPrincipal current, {
    required String schoolId,
  }) {
    final track = current.experienceTrack ?? ExperienceTrack.senior;
    return current.copyWith(
      role: track == ExperienceTrack.junior
          ? AppRole.juniorStudent
          : AppRole.seniorStudent,
      schoolId: schoolId,
      flexEligible: true,
      experienceTrack: track,
    );
  }
}
