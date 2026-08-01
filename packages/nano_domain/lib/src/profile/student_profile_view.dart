import '../home/student_home_summary.dart';
import '../l10n/nano_app_locale.dart';
import '../navigation/app_role.dart';
import '../xp/achievement.dart';

/// Learner-controlled visibility. Social modules read these, never the raw
/// profile.
class PrivacySettings {
  const PrivacySettings({
    required this.userId,
    this.discoverable = true,
    this.showAchievements = true,
    this.allowFriendRequests = true,
  });

  final String userId;
  final bool discoverable;
  final bool showAchievements;
  final bool allowFriendRequests;

  PrivacySettings copyWith({
    bool? discoverable,
    bool? showAchievements,
    bool? allowFriendRequests,
  }) {
    return PrivacySettings(
      userId: userId,
      discoverable: discoverable ?? this.discoverable,
      showAchievements: showAchievements ?? this.showAchievements,
      allowFriendRequests: allowFriendRequests ?? this.allowFriendRequests,
    );
  }

  factory PrivacySettings.fromRow(Map<String, dynamic> row) {
    return PrivacySettings(
      userId: row['user_id'] as String,
      discoverable: row['discoverable'] as bool? ?? true,
      showAchievements: row['show_achievements'] as bool? ?? true,
      allowFriendRequests: row['allow_friend_requests'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toRow() => {
        'user_id': userId,
        'discoverable': discoverable,
        'show_achievements': showAchievements,
        'allow_friend_requests': allowFriendRequests,
      };
}

class ProfileAchievement {
  const ProfileAchievement({
    required this.id,
    required this.title,
    required this.earnedAt,
    this.kind = AchievementKind.achievement,
    this.slug = '',
    this.isFeatured = false,
  });

  factory ProfileAchievement.fromAward(
    AchievementAward award, {
    required bool urdu,
    bool isFeatured = false,
  }) {
    return ProfileAchievement(
      id: award.awardId,
      title: award.titleFor(urdu: urdu),
      earnedAt: award.awardedAt,
      kind: award.kind,
      slug: award.slug,
      isFeatured: isFeatured,
    );
  }

  final String id;
  final String title;
  final DateTime earnedAt;
  final AchievementKind kind;
  final String slug;

  /// XP-06: pinned on Me (max three).
  final bool isFeatured;

  bool get isSticker => kind == AchievementKind.sticker;

  ProfileAchievement copyWith({bool? isFeatured}) {
    return ProfileAchievement(
      id: id,
      title: title,
      earnedAt: earnedAt,
      kind: kind,
      slug: slug,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }
}

/// The owner's view of their own profile. Includes private data that must
/// never reach a public or friend-visible surface.
class StudentProfileView {
  const StudentProfileView({
    required this.userId,
    required this.displayName,
    required this.role,
    this.companionName = 'Nori',
    this.locale = NanoAppLocale.en,
    this.schoolName,
    this.className,
    this.email,
    this.guardianContact,
    this.attendanceLabel,
    this.latestMarkLabel,
    this.xp = 0,
    this.streakDays = 0,
    this.completedTopics = 0,
    this.recommendedNext,
    this.achievements = const [],
    this.levelProgress,
  });

  final String userId;
  final String displayName;
  final AppRole role;
  final String companionName;
  final NanoAppLocale locale;
  final String? schoolName;
  final String? className;

  /// Private fields. Owner-only, and excluded from [PublicProfileProjection].
  final String? email;
  final String? guardianContact;
  final String? attendanceLabel;
  final String? latestMarkLabel;

  final int xp;
  final int streakDays;
  final int completedTopics;
  final String? recommendedNext;
  final List<ProfileAchievement> achievements;

  /// XP-02: server-owned level when the ledger balance carried one.
  final LevelProgress? levelProgress;

  LevelProgress get level => levelProgress ?? LevelProgress.fromXp(xp);

  bool get isSchoolLinked => schoolName != null;

  StudentProfileView copyWith({
    String? companionName,
    NanoAppLocale? locale,
    LevelProgress? levelProgress,
  }) {
    return StudentProfileView(
      userId: userId,
      displayName: displayName,
      role: role,
      companionName: companionName ?? this.companionName,
      locale: locale ?? this.locale,
      schoolName: schoolName,
      className: className,
      email: email,
      guardianContact: guardianContact,
      attendanceLabel: attendanceLabel,
      latestMarkLabel: latestMarkLabel,
      xp: xp,
      streakDays: streakDays,
      completedTopics: completedTopics,
      recommendedNext: recommendedNext,
      achievements: achievements,
      levelProgress: levelProgress ?? this.levelProgress,
    );
  }

  /// Initials for the avatar; never more than two characters.
  String get initials {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final single = parts.first;
      return (single.length == 1 ? single : single.substring(0, 2))
          .toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

/// What other learners may see. Built by stripping the owner-only fields, so
/// a social surface cannot leak email, guardian data, attendance, marks,
/// payment, or device information.
class PublicProfileProjection {
  const PublicProfileProjection({
    required this.displayName,
    required this.level,
    this.companionName,
    this.achievements = const [],
    this.discoverable = true,
    this.acceptsFriendRequests = true,
  });

  factory PublicProfileProjection.of(
    StudentProfileView view,
    PrivacySettings privacy,
  ) {
    return PublicProfileProjection(
      displayName: view.displayName,
      level: view.level.level,
      companionName: view.companionName,
      achievements: privacy.showAchievements ? view.achievements : const [],
      discoverable: privacy.discoverable,
      acceptsFriendRequests: privacy.allowFriendRequests,
    );
  }

  final String displayName;
  final int level;
  final String? companionName;
  final List<ProfileAchievement> achievements;
  final bool discoverable;
  final bool acceptsFriendRequests;

  /// Field names that must never appear in a public projection. Kept next to
  /// the projection so the rule is testable rather than aspirational.
  static const forbiddenFields = <String>[
    'email',
    'phone',
    'guardianContact',
    'attendanceLabel',
    'latestMarkLabel',
    'payment',
    'deviceLabel',
    'userAgent',
    'schoolName',
    'className',
    'userId',
  ];

  Map<String, Object?> toJson() => {
        'displayName': displayName,
        'level': level,
        'companionName': companionName,
        'achievements': [
          for (final achievement in achievements) achievement.title,
        ],
        'discoverable': discoverable,
        'acceptsFriendRequests': acceptsFriendRequests,
      };
}
