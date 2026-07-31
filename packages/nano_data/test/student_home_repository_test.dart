import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  const subjects = [
    LearningSubject(
      id: 'math',
      title: 'Math',
      progress: 0.5,
      worldColorValue: 0xFF000000,
    ),
  ];

  test('load returns a resumable lesson and the learner identity', () async {
    final repo = FakeStudentHomeRepository(subjects: subjects);
    final summary = await repo.loadHome(
      userId: 'u1',
      learnerName: 'Ali',
      companionName: 'Bolt',
    );
    expect(summary.learnerName, 'Ali');
    expect(summary.companionName, 'Bolt');
    expect(summary.continueItem, isNotNull);
    expect(summary.hasContent, isTrue);
    expect(summary.fromCache, isFalse);
    expect(repo.loadCount, 1);
  });

  test('cache mode flags stale data with an older timestamp', () async {
    final repo = FakeStudentHomeRepository(
      servesCache: true,
      cacheAge: const Duration(hours: 4),
      subjects: subjects,
    );
    final summary = await repo.loadHome(userId: 'u1', learnerName: 'Ali');
    expect(summary.fromCache, isTrue);
    expect(summary.freshnessLabel, '4 h ago');
  });

  test('failOnce fails the first load and succeeds on retry', () async {
    final repo = FakeStudentHomeRepository(failOnce: true, subjects: subjects);
    await expectLater(
      repo.loadHome(userId: 'u1', learnerName: 'Ali'),
      throwsStateError,
    );
    final summary = await repo.loadHome(userId: 'u1', learnerName: 'Ali');
    expect(summary.hasContent, isTrue);
    expect(repo.loadCount, 2);
  });

  test('flex loads only for eligible learners', () async {
    final repo = FakeStudentHomeRepository(subjects: subjects);
    final ineligible = await repo.loadHome(userId: 'u1', learnerName: 'Ali');
    expect(ineligible.flex, isNull);

    final eligible = await repo.loadHome(
      userId: 'u1',
      learnerName: 'Ali',
      flexEligible: true,
    );
    expect(eligible.flex?.openTasks, 3);
    expect(eligible.showsFlex, isTrue);
  });

  test('a failing section still returns the rest of the home', () async {
    final repo = FakeStudentHomeRepository(
      subjects: subjects,
      missions: const [
        HomePlanItem(id: 'm1', title: 'Lesson', subtitle: 'Learn', xpReward: 40),
      ],
      failSections: const {HomeSection.subjects, HomeSection.updates},
    );
    final summary = await repo.loadHome(
      userId: 'u1',
      learnerName: 'Ali',
      flexEligible: true,
    );

    expect(summary.isPartial, isTrue);
    expect(summary.subjects, isEmpty);
    expect(summary.latestUpdate, isNull);
    expect(summary.continueItem, isNotNull);
    expect(summary.plan, hasLength(1));
    expect(summary.flex, isNotNull);
    expect(summary.hasContent, isTrue);
  });

  test('notice passes through for maintenance windows', () async {
    final repo = FakeStudentHomeRepository(
      notice: HomeNoticeKind.maintenance,
      subjects: subjects,
    );
    final summary = await repo.loadHome(userId: 'u1', learnerName: 'Ali');
    expect(summary.notice, HomeNoticeKind.maintenance);
  });
}
