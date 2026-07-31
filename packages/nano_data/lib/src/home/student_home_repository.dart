import 'package:nano_domain/nano_domain.dart';

/// Aggregates the student home in one read.
///
/// Live data arrives with the LRN and XP modules; until then the app runs on
/// the fake below (UI-first per AGENTS.md).
abstract class StudentHomeRepository {
  Future<StudentHomeSummary> loadHome({
    required String userId,
    required String learnerName,
    String companionName,
  });
}

/// Deterministic home data with switchable failure and offline behaviour.
class FakeStudentHomeRepository implements StudentHomeRepository {
  FakeStudentHomeRepository({
    this.failOnce = false,
    this.alwaysFail = false,
    this.servesCache = false,
    this.notice = HomeNoticeKind.none,
    this.delay = Duration.zero,
    this.cacheAge = const Duration(hours: 3),
    this.subjects = const [],
    this.missions = const [],
  });

  bool failOnce;
  final bool alwaysFail;
  final bool servesCache;
  final HomeNoticeKind notice;
  final Duration delay;
  final Duration cacheAge;
  final List<LearningSubject> subjects;
  final List<HomePlanItem> missions;

  var loadCount = 0;

  @override
  Future<StudentHomeSummary> loadHome({
    required String userId,
    required String learnerName,
    String companionName = 'Nori',
  }) async {
    loadCount++;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (alwaysFail) {
      throw StateError('Home unavailable');
    }
    if (failOnce) {
      failOnce = false;
      throw StateError('Home unavailable');
    }
    final now = DateTime.now().toUtc();
    return StudentHomeSummary(
      learnerName: learnerName,
      companionName: companionName,
      updatedAt: servesCache ? now.subtract(cacheAge) : now,
      fromCache: servesCache,
      xp: 560,
      streakDays: 7,
      unreadNotifications: 2,
      notice: notice,
      continueItem: const ContinueLearningItem(
        id: 'lesson-animals',
        title: 'Animals Adventure',
        subjectId: 'science',
        progress: 0.42,
      ),
      missions: missions,
      subjects: subjects,
    );
  }
}
