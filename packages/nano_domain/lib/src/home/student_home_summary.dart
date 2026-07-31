import '../learning/home_plan_item.dart';
import '../learning/learning_subject.dart';

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

  bool get hasContent => continueItem != null || subjects.isNotEmpty;

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
    );
  }
}
