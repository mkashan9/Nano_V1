/// SAFE-04 community feature entitlements and admin policy snapshots.

class CommunityEntitlements {
  const CommunityEntitlements({
    required this.communitiesEnabled,
    required this.platformEnabled,
    this.schoolEnabled,
    required this.juniorBlocked,
    required this.reason,
  });

  final bool communitiesEnabled;
  final bool platformEnabled;
  final bool? schoolEnabled;
  final bool juniorBlocked;
  final String reason;

  factory CommunityEntitlements.fromJson(Map<String, dynamic> json) {
    return CommunityEntitlements(
      communitiesEnabled: json['communities_enabled'] as bool? ?? false,
      platformEnabled: json['platform_enabled'] as bool? ?? false,
      schoolEnabled: json['school_enabled'] as bool?,
      juniorBlocked: json['junior_blocked'] as bool? ?? false,
      reason: json['reason'] as String? ?? 'ok',
    );
  }

  static const disabled = CommunityEntitlements(
    communitiesEnabled: false,
    platformEnabled: false,
    schoolEnabled: false,
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
      communitiesEnabled: json['communities_enabled'] as bool? ?? false,
      updatedAt: _parseTime(json['updated_at']),
      updatedBy: json['updated_by'] as String?,
    );
  }
}

class SchoolCommunityPolicy {
  const SchoolCommunityPolicy({
    required this.schoolId,
    required this.communitiesEnabled,
    this.schoolName,
    this.updatedAt,
    this.updatedBy,
  });

  final String schoolId;
  final bool communitiesEnabled;
  final String? schoolName;
  final DateTime? updatedAt;
  final String? updatedBy;

  factory SchoolCommunityPolicy.fromJson(Map<String, dynamic> json) {
    return SchoolCommunityPolicy(
      schoolId: json['school_id'] as String? ?? '',
      communitiesEnabled: json['communities_enabled'] as bool? ?? false,
      schoolName: json['school_name'] as String?,
      updatedAt: _parseTime(json['updated_at']),
      updatedBy: json['updated_by'] as String?,
    );
  }
}

DateTime? _parseTime(Object? raw) {
  if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
  return null;
}
