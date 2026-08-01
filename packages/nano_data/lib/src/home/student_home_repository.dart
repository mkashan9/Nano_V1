import 'package:nano_domain/nano_domain.dart';

import '../xp/xp_ledger_repository.dart';

/// Aggregates the student home in one read.
///
/// Live data arrives with the LRN and XP modules; until then the app runs on
/// the fake below (UI-first per AGENTS.md).
abstract class StudentHomeRepository {
  Future<StudentHomeSummary> loadHome({
    required String userId,
    required String learnerName,
    String companionName,
    bool flexEligible,
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
    this.failSections = const {},
    this.includeUpdate = true,
    this.xpLedger,
    this.fixtureXp = 560,
  });

  bool failOnce;
  final bool alwaysFail;
  final bool servesCache;
  final HomeNoticeKind notice;
  final Duration delay;
  final Duration cacheAge;
  final List<LearningSubject> subjects;
  final List<HomePlanItem> missions;

  /// Sections that fail while the rest of the home still loads.
  final Set<HomeSection> failSections;
  final bool includeUpdate;

  /// XP-01: when set, Home reads the ledger total instead of [fixtureXp].
  final XpLedgerRepository? xpLedger;
  final int fixtureXp;

  var loadCount = 0;

  @override
  Future<StudentHomeSummary> loadHome({
    required String userId,
    required String learnerName,
    String companionName = 'Nori',
    bool flexEligible = false,
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
    final failed = failSections;
    final xp = xpLedger == null
        ? fixtureXp
        : (await xpLedger!.balance()).total;
    return StudentHomeSummary(
      learnerName: learnerName,
      companionName: companionName,
      updatedAt: servesCache ? now.subtract(cacheAge) : now,
      fromCache: servesCache,
      xp: xp,
      streakDays: 7,
      unreadNotifications: 2,
      notice: notice,
      failedSections: failed,
      continueItem: failed.contains(HomeSection.continueLearning)
          ? null
          : const ContinueLearningItem(
              id: 'lesson-animals',
              title: 'Animals Adventure',
              subjectId: 'science',
              progress: 0.42,
            ),
      missions: failed.contains(HomeSection.missions) ? const [] : missions,
      subjects: failed.contains(HomeSection.subjects) ? const [] : subjects,
      // Flex is a server-side entitlement; the fake honours the caller's
      // eligibility rather than letting the UI decide.
      flex: !flexEligible || failed.contains(HomeSection.flex)
          ? null
          : const FlexSummary(openTasks: 3, nextDueLabel: 'Due Friday'),
      latestUpdate: !includeUpdate || failed.contains(HomeSection.updates)
          ? null
          : HomeUpdate(
              title: 'Ms Khan reviewed your quiz',
              body: 'Great work on fractions — try the bonus set next.',
              at: now.subtract(const Duration(hours: 2)),
            ),
    );
  }
}
