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

  test('copyWith keeps untouched fields', () {
    final s = summary().copyWith(xp: 100, notice: HomeNoticeKind.maintenance);
    expect(s.learnerName, 'Ali');
    expect(s.xp, 100);
    expect(s.notice, HomeNoticeKind.maintenance);
    expect(s.fromCache, isFalse);
  });
}
