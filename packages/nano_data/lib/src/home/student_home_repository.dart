import 'package:nano_domain/nano_domain.dart';

import '../xp/mission_repository.dart';
import '../xp/streak_repository.dart';
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
    bool independent,
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
    this.missionRepository,
    this.streakRepository,
    this.fixtureXp = 560,
    this.fixtureStreak = 7,
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

  /// XP-04: when set, Home plan comes from live missions.
  final MissionRepository? missionRepository;

  /// XP-05: when set, streak count (and gentle notice) come from the server.
  final StreakRepository? streakRepository;
  final int fixtureXp;
  final int fixtureStreak;

  var loadCount = 0;

  @override
  Future<StudentHomeSummary> loadHome({
    required String userId,
    required String learnerName,
    String companionName = 'Nori',
    bool flexEligible = false,
    bool independent = false,
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
    final XpBalance? balance =
        xpLedger == null ? null : await xpLedger!.balance();
    final xp = balance?.total ?? fixtureXp;
    final StreakSnapshot? streak =
        streakRepository == null ? null : await streakRepository!.current();
    final List<HomePlanItem> plan;
    if (failed.contains(HomeSection.missions)) {
      plan = const [];
    } else if (missionRepository != null) {
      plan = [
        for (final m in await missionRepository!.current())
          m.toHomePlanItem(urdu: false),
      ];
    } else {
      plan = missions;
    }
    var resolvedNotice = notice;
    if (streak != null &&
        streak.hasGentleNotice &&
        resolvedNotice == HomeNoticeKind.none) {
      resolvedNotice = HomeNoticeKind.streakGentle;
    }
    return StudentHomeSummary(
      learnerName: learnerName,
      companionName: companionName,
      updatedAt: servesCache ? now.subtract(cacheAge) : now,
      fromCache: servesCache,
      xp: xp,
      levelProgress: balance?.levelProgress,
      streakDays: streak?.current ?? fixtureStreak,
      unreadNotifications: 2,
      notice: resolvedNotice,
      failedSections: failed,
      continueItem: failed.contains(HomeSection.continueLearning)
          ? null
          : const ContinueLearningItem(
              id: 'lesson-animals',
              title: 'Animals Adventure',
              subjectId: 'science',
              progress: 0.42,
            ),
      missions: plan,
      subjects: failed.contains(HomeSection.subjects) ? const [] : subjects,
      flex: !flexEligible || failed.contains(HomeSection.flex)
          ? null
          : const FlexSummary(openTasks: 3, nextDueLabel: 'Due Friday'),
      independentSpotlight: !independent ||
              failed.contains(HomeSection.independentSpotlight)
          ? null
          : const IndependentSpotlight(
              kind: IndependentSpotlightKind.play,
              title: 'Shape Sort',
              body: 'A quick play keeps your streak warm.',
              deepLinkPath: '/games',
            ),
      latestUpdate: independent ||
              !includeUpdate ||
              failed.contains(HomeSection.updates)
          ? null
          : HomeUpdate(
              title: 'Ms Khan reviewed your quiz',
              body: 'Great work on fractions — try the bonus set next.',
              at: now.subtract(const Duration(hours: 2)),
            ),
    );
  }
}
