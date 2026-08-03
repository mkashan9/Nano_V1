import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  StudentHomeSummary summary({
    List<HomePlanItem> missions = const [],
    List<LearningSubject> subjects = const [],
    ContinueLearningItem? continueItem,
    DateTime? updatedAt,
  }) {
    return StudentHomeSummary(
      learnerName: 'Ali',
      updatedAt: updatedAt ?? DateTime.now().toUtc(),
      missions: missions,
      subjects: subjects,
      continueItem: continueItem,
    );
  }

  test('continue progress converts to a whole percentage', () {
    const item = ContinueLearningItem(
      id: 'l1',
      title: 'Animals',
      subjectId: 'science',
      progress: 0.426,
    );
    expect(item.percentComplete, 43);
  });

  test('junior missions cap at three with their XP total', () {
    final s = summary(
      missions: const [
        HomePlanItem(id: 'a', title: 'A', subtitle: 'x', xpReward: 10),
        HomePlanItem(id: 'b', title: 'B', subtitle: 'x', xpReward: 20),
        HomePlanItem(id: 'c', title: 'C', subtitle: 'x', xpReward: 30),
        HomePlanItem(id: 'd', title: 'D', subtitle: 'x', xpReward: 40),
      ],
    );
    expect(s.juniorMissions.length, 3);
    expect(s.missionXpAvailable, 60);
  });

  test('hasContent is false when there is nothing to resume or explore', () {
    expect(summary().hasContent, isFalse);
    expect(
      summary(
        subjects: const [
          LearningSubject(
            id: 'math',
            title: 'Math',
            progress: 0.1,
            worldColorValue: 0xFF000000,
          ),
        ],
      ).hasContent,
      isTrue,
    );
  });

  test('independent spotlight counts as content without Flex', () {
    final s = StudentHomeSummary(
      learnerName: 'Ali',
      updatedAt: DateTime.utc(2026, 8, 3),
      independentSpotlight: const IndependentSpotlight(
        kind: IndependentSpotlightKind.play,
        title: 'Shape Sort',
        body: 'Warm up',
      ),
    );
    expect(s.hasContent, isTrue);
    expect(s.flex, isNull);
  });

  test('freshness label degrades from minutes to days', () {
    final now = DateTime.now().toUtc();
    expect(summary(updatedAt: now).freshnessLabel, 'just now');
    expect(
      summary(updatedAt: now.subtract(const Duration(minutes: 20)))
          .freshnessLabel,
      '20 min ago',
    );
    expect(
      summary(updatedAt: now.subtract(const Duration(hours: 5))).freshnessLabel,
      '5 h ago',
    );
    expect(
      summary(updatedAt: now.subtract(const Duration(days: 2))).freshnessLabel,
      '2 d ago',
    );
  });

  group('senior additions', () {
    test('level derives from XP and reports the remainder', () {
      final progress = LevelProgress.fromXp(560);
      expect(progress.level, 3);
      expect(progress.xpIntoLevel, 60);
      expect(progress.xpToNextLevel, 190);
      expect(progress.fraction, closeTo(0.24, 0.001));
    });

    test('level never drops below one, even with no or negative XP', () {
      expect(LevelProgress.fromXp(0).level, 1);
      expect(LevelProgress.fromXp(-50).level, 1);
      expect(LevelProgress.fromXp(-50).xpIntoLevel, 0);
    });

    test('summary exposes level from its XP', () {
      expect(summary().copyWith(xp: 250).level.level, 2);
    });

    test('senior plan is the full mission list, not the junior three', () {
      final missions = [
        for (var i = 0; i < 5; i++)
          HomePlanItem(id: '$i', title: 'T$i', subtitle: 'x', xpReward: 10),
      ];
      final s = summary(missions: missions);
      expect(s.plan.length, 5);
      expect(s.juniorMissions.length, 3);
    });

    test('a failed section is partial, not empty', () {
      final s = summary(
        missions: const [
          HomePlanItem(id: 'a', title: 'A', subtitle: 'x', xpReward: 10),
        ],
      ).copyWith(failedSections: {HomeSection.subjects});
      expect(s.isPartial, isTrue);
      expect(s.failed(HomeSection.subjects), isTrue);
      expect(s.failed(HomeSection.missions), isFalse);
      expect(s.hasContent, isTrue);
    });

    test('flex shows only when present and its section loaded', () {
      final withFlex = summary().copyWith(
        flex: const FlexSummary(openTasks: 2, nextDueLabel: 'Due Friday'),
      );
      expect(withFlex.showsFlex, isTrue);
      expect(withFlex.flex!.hasWork, isTrue);
      expect(summary().showsFlex, isFalse);
      expect(
        withFlex.copyWith(failedSections: {HomeSection.flex}).showsFlex,
        isFalse,
      );
    });

    test('missions alone count as content for a partial home', () {
      final s = summary(
        missions: const [
          HomePlanItem(id: 'a', title: 'A', subtitle: 'x', xpReward: 10),
        ],
      );
      expect(s.hasContent, isTrue);
    });
  });

  test('copyWith keeps untouched fields', () {
    final s = summary().copyWith(xp: 100, notice: HomeNoticeKind.maintenance);
    expect(s.learnerName, 'Ali');
    expect(s.xp, 100);
    expect(s.notice, HomeNoticeKind.maintenance);
    expect(s.fromCache, isFalse);
  });
}
