/// SAFE-04 open Communities entitlements + platform emergency kill switch.
/// Schools do not gate Communities (owner decision: Discord-like freedom).

class CommunityEntitlements {
  const CommunityEntitlements({
    required this.communitiesEnabled,
    required this.platformEnabled,
    required this.juniorBlocked,
    required this.reason,
  });

  final bool communitiesEnabled;
  final bool platformEnabled;
  final bool juniorBlocked;
  final String reason;

  factory CommunityEntitlements.fromJson(Map<String, dynamic> json) {
    return CommunityEntitlements(
      communitiesEnabled: json['communities_enabled'] as bool? ?? false,
      platformEnabled: json['platform_enabled'] as bool? ?? true,
      juniorBlocked: json['junior_blocked'] as bool? ?? false,
      reason: json['reason'] as String? ?? 'ok',
    );
  }

  static const disabled = CommunityEntitlements(
    communitiesEnabled: false,
    platformEnabled: true,
    juniorBlocked: true,
    reason: 'junior_blocked',
  );
}

class PlatformCommunityPolicy {
  const PlatformCommunityPolicy({
    required this.communitiesEnabled,
    this.updatedAt,
    this.updatedBy,
  });

  final bool communitiesEnabled;
  final DateTime? updatedAt;
  final String? updatedBy;

  factory PlatformCommunityPolicy.fromJson(Map<String, dynamic> json) {
    return PlatformCommunityPolicy(
      communitiesEnabled: json['communities_enabled'] as bool? ?? true,
      updatedAt: _parseTime(json['updated_at']),
      updatedBy: json['updated_by'] as String?,
    );
  }
}

DateTime? _parseTime(Object? raw) {
  if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
  return null;
}
