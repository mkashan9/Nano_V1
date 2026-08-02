/// SOC-01 owner social handle + rotatable friend code.
class SocialIdentity {
  const SocialIdentity({
    this.username,
    required this.friendCode,
    this.friendCodeRotatedAt,
  });

  final String? username;
  final String friendCode;
  final DateTime? friendCodeRotatedAt;

  bool get hasUsername =>
      username != null && username!.trim().isNotEmpty;

  factory SocialIdentity.fromJson(Map<String, dynamic> json) {
    final rotated = json['friend_code_rotated_at'];
    return SocialIdentity(
      username: json['username'] as String?,
      friendCode: json['friend_code'] as String? ?? '',
      friendCodeRotatedAt: rotated is String ? DateTime.tryParse(rotated) : null,
    );
  }
}

/// Privacy-safe peer card from [lookup_limited_profile]. Never includes userId.
class LimitedProfile {
  const LimitedProfile({
    required this.socialLabel,
    this.username,
    required this.level,
    this.companionName,
    this.acceptsFriendRequests = true,
    this.achievementTitles = const [],
  });

  final String socialLabel;
  final String? username;
  final int level;
  final String? companionName;
  final bool acceptsFriendRequests;
  final List<String> achievementTitles;

  factory LimitedProfile.fromJson(Map<String, dynamic> json) {
    final rawAchievements = json['achievements'];
    final titles = <String>[];
    if (rawAchievements is List) {
      for (final item in rawAchievements) {
        if (item is String && item.isNotEmpty) titles.add(item);
      }
    }
    return LimitedProfile(
      socialLabel: json['social_label'] as String? ?? 'Learner',
      username: json['username'] as String?,
      level: (json['level'] as num?)?.toInt() ?? 1,
      companionName: json['companion_name'] as String?,
      acceptsFriendRequests: json['accepts_friend_requests'] as bool? ?? true,
      achievementTitles: titles,
    );
  }

  Map<String, Object?> toJson() => {
        'social_label': socialLabel,
        'username': username,
        'level': level,
        'companion_name': companionName,
        'accepts_friend_requests': acceptsFriendRequests,
        'achievements': achievementTitles,
      };

  static const forbiddenFields = <String>[
    'userId',
    'user_id',
    'email',
    'friend_code',
    'friendCode',
    'schoolName',
    'className',
    'guardianContact',
    'attendanceLabel',
    'latestMarkLabel',
    'payment',
  ];
}

/// Client-side username policy (mirrors server NS020).
class UsernamePolicy {
  static final RegExp pattern = RegExp(r'^[a-z][a-z0-9_]{2,19}$');

  static const reserved = <String>{
    'admin',
    'administrator',
    'nano',
    'nori',
    'support',
    'system',
    'teacher',
    'student',
    'null',
    'undefined',
    'me',
    'root',
    'mod',
    'moderator',
    'official',
  };

  static String? validate(String raw) {
    final clean = raw.trim().toLowerCase();
    if (!pattern.hasMatch(clean)) {
      return 'Username must be 3–20 chars: start with a letter, then letters, numbers, or _.';
    }
    if (reserved.contains(clean)) {
      return 'That username is reserved.';
    }
    return null;
  }

  static String normalize(String raw) => raw.trim().toLowerCase();
}
