import '../learning/home_plan_item.dart';
import '../learning/learning_subject.dart';
import '../xp/level_progress.dart';

export '../xp/level_progress.dart' show LevelProgress;

/// A resumable lesson. Progress drives the junior "keep going" card.
class ContinueLearningItem {
  const ContinueLearningItem({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.progress,
  });

  final String id;
  final String title;
  final String subjectId;
  final double progress;

  int get percentComplete => (progress.clamp(0.0, 1.0) * 100).round();
}

/// Non-blocking notices the home screen may show above content.
enum HomeNoticeKind { none, maintenance, accessWarning }

/// Independently loaded parts of the home, so one failure never blanks the
/// whole screen (handbook STU-02: "Home renders with partial data when one
/// source fails").
enum HomeSection { continueLearning, missions, subjects, flex, updates }

/// Flex snapshot for school-eligible seniors only.
class FlexSummary {
  const FlexSummary({
    required this.openTasks,
    this.nextDueLabel,
  });

  final int openTasks;
  final String? nextDueLabel;

  bool get hasWork => openTasks > 0;
}

/// The latest relevant update: teacher feedback, a school notice, a result.
class HomeUpdate {
  const HomeUpdate({
    required this.title,
    required this.body,
    required this.at,
  });

  final String title;
  final String body;
  final DateTime at;
}

/// Everything the student home needs, aggregated in one read.
///
/// Junior and senior presentations consume the same summary; only the
/// composition differs.
class StudentHomeSummary {
  const StudentHomeSummary({
    required this.learnerName,
    required this.updatedAt,
    this.companionName = 'Nori',
    this.xp = 0,
    this.streakDays = 0,
    this.continueItem,
    this.missions = const [],
    this.subjects = const [],
    this.unreadNotifications = 0,
    this.notice = HomeNoticeKind.none,
    this.fromCache = false,
    this.flex,
    this.latestUpdate,
    this.failedSections = const {},
    this.levelProgress,
  });

  final String learnerName;
  final DateTime updatedAt;
  final String companionName;
  final int xp;
  final int streakDays;
  final ContinueLearningItem? continueItem;
  final List<HomePlanItem> missions;
  final List<LearningSubject> subjects;
  final int unreadNotifications;
  final HomeNoticeKind notice;

  /// True when served from cache, so the UI can show an offline timestamp.
  final bool fromCache;

  /// Present only for school-eligible learners; independents never get one.
  final FlexSummary? flex;

  final HomeUpdate? latestUpdate;

  /// Sections whose source failed. They render an inline notice instead of
  /// taking down the rest of the home.
  final Set<HomeSection> failedSections;

  /// XP-02: server-owned level when the ledger balance carried one.
  final LevelProgress? levelProgress;

  bool get hasContent =>
      continueItem != null ||
      subjects.isNotEmpty ||
      missions.isNotEmpty ||
      flex != null ||
      latestUpdate != null;

  bool failed(HomeSection section) => failedSections.contains(section);

  bool get isPartial => failedSections.isNotEmpty;

  LevelProgress get level => levelProgress ?? LevelProgress.fromXp(xp);

  bool get showsFlex => flex != null && !failed(HomeSection.flex);

  /// Senior plan shows the whole day, unlike the capped junior list.
  List<HomePlanItem> get plan => missions;

  /// Junior missions stay short; a long list overwhelms young learners.
  List<HomePlanItem> get juniorMissions => missions.take(3).toList(growable: false);

  int get missionXpAvailable =>
      juniorMissions.fold(0, (sum, item) => sum + item.xpReward);

  String get freshnessLabel {
    final age = DateTime.now().toUtc().difference(updatedAt.toUtc());
    if (age.inMinutes < 1) return 'just now';
    if (age.inHours < 1) return '${age.inMinutes} min ago';
    if (age.inDays < 1) return '${age.inHours} h ago';
    return '${age.inDays} d ago';
  }

  StudentHomeSummary copyWith({
    String? learnerName,
    DateTime? updatedAt,
    String? companionName,
    int? xp,
    int? streakDays,
    ContinueLearningItem? continueItem,
    List<HomePlanItem>? missions,
    List<LearningSubject>? subjects,
    int? unreadNotifications,
    HomeNoticeKind? notice,
    bool? fromCache,
    FlexSummary? flex,
    HomeUpdate? latestUpdate,
    Set<HomeSection>? failedSections,
    LevelProgress? levelProgress,
  }) {
    return StudentHomeSummary(
      learnerName: learnerName ?? this.learnerName,
      updatedAt: updatedAt ?? this.updatedAt,
      companionName: companionName ?? this.companionName,
      xp: xp ?? this.xp,
      streakDays: streakDays ?? this.streakDays,
      continueItem: continueItem ?? this.continueItem,
      missions: missions ?? this.missions,
      subjects: subjects ?? this.subjects,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      notice: notice ?? this.notice,
      fromCache: fromCache ?? this.fromCache,
      flex: flex ?? this.flex,
      latestUpdate: latestUpdate ?? this.latestUpdate,
      failedSections: failedSections ?? this.failedSections,
      levelProgress: levelProgress ?? this.levelProgress,
    );
  }
}
