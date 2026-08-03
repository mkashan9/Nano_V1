/// COM-01 community discovery models (open / Discord-like; not school-gated).

enum CommunityVisibility {
  public,
  private;

  static CommunityVisibility parse(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'private':
        return CommunityVisibility.private;
      case 'public':
      default:
        return CommunityVisibility.public;
    }
  }

  String get wire => name;
}

enum CommunityMembershipStatus {
  none,
  active,
  pending,
  banned,
  left;

  static CommunityMembershipStatus parse(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'active':
        return CommunityMembershipStatus.active;
      case 'pending':
        return CommunityMembershipStatus.pending;
      case 'banned':
        return CommunityMembershipStatus.banned;
      case 'left':
        return CommunityMembershipStatus.left;
      default:
        return CommunityMembershipStatus.none;
    }
  }

  String get wire => name;
}

class CommunitySummary {
  const CommunitySummary({
    required this.id,
    required this.slug,
    required this.name,
    required this.summary,
    this.visibility = CommunityVisibility.public,
    this.memberCount = 0,
    this.myRole,
    this.myStatus = CommunityMembershipStatus.none,
    this.joinedAt,
  });

  final String id;
  final String slug;
  final String name;
  final String summary;
  final CommunityVisibility visibility;
  final int memberCount;
  final String? myRole;
  final CommunityMembershipStatus myStatus;
  final DateTime? joinedAt;

  bool get isMember => myStatus == CommunityMembershipStatus.active;

  factory CommunitySummary.fromJson(Map<String, dynamic> json) {
    return CommunitySummary(
      id: json['id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      visibility: CommunityVisibility.parse(json['visibility'] as String?),
      memberCount: json['member_count'] as int? ?? 0,
      myRole: json['my_role'] as String?,
      myStatus: CommunityMembershipStatus.parse(json['my_status'] as String?),
      joinedAt: _parseTime(json['joined_at']),
    );
  }
}

class CommunityDetail {
  const CommunityDetail({
    required this.id,
    required this.slug,
    required this.name,
    required this.summary,
    required this.rulesText,
    this.visibility = CommunityVisibility.public,
    this.memberCount = 0,
    this.myRole,
    this.myStatus = CommunityMembershipStatus.none,
    this.joinedAt,
    this.createdAt,
  });

  final String id;
  final String slug;
  final String name;
  final String summary;
  final String rulesText;
  final CommunityVisibility visibility;
  final int memberCount;
  final String? myRole;
  final CommunityMembershipStatus myStatus;
  final DateTime? joinedAt;
  final DateTime? createdAt;

  bool get isMember => myStatus == CommunityMembershipStatus.active;

  CommunitySummary get asSummary => CommunitySummary(
        id: id,
        slug: slug,
        name: name,
        summary: summary,
        visibility: visibility,
        memberCount: memberCount,
        myRole: myRole,
        myStatus: myStatus,
        joinedAt: joinedAt,
      );

  factory CommunityDetail.fromJson(Map<String, dynamic> json) {
    return CommunityDetail(
      id: json['id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      rulesText: json['rules_text'] as String? ?? '',
      visibility: CommunityVisibility.parse(json['visibility'] as String?),
      memberCount: json['member_count'] as int? ?? 0,
      myRole: json['my_role'] as String?,
      myStatus: CommunityMembershipStatus.parse(json['my_status'] as String?),
      joinedAt: _parseTime(json['joined_at']),
      createdAt: _parseTime(json['created_at']),
    );
  }

  bool get canManageRoles =>
      myRole == 'owner' || myRole == 'admin';
}

class CommunityMember {
  const CommunityMember({
    required this.userId,
    required this.displayName,
    required this.role,
    this.status = CommunityMembershipStatus.active,
    this.joinedAt,
    this.isSelf = false,
  });

  final String userId;
  final String displayName;
  final String role;
  final CommunityMembershipStatus status;
  final DateTime? joinedAt;
  final bool isSelf;

  factory CommunityMember.fromJson(Map<String, dynamic> json) {
    return CommunityMember(
      userId: json['user_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Member',
      role: json['role'] as String? ?? 'member',
      status: CommunityMembershipStatus.parse(json['status'] as String?),
      joinedAt: _parseTime(json['joined_at']),
      isSelf: json['is_self'] as bool? ?? false,
    );
  }
}

DateTime? _parseTime(Object? raw) {
  if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
  return null;
}
