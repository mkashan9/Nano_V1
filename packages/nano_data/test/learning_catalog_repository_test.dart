import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('junior catalog hides senior-only subjects and locks addition', () async {
    final repo = FakeLearningCatalogRepository();
    final catalog = await repo.loadCatalog();
    expect(catalog.subjects.map((s) => s.slug), ['math']);
    final math = catalog.subjects.single;
    expect(math.topics.last.isLocked, isTrue);
    expect(math.topics.last.blockingTitles, ['Counting to 20']);
    expect(catalog.topicVersionIds, {
      'tv-counting-1',
      'tv-addition-1',
    });
  });

  test('senior catalog reveals science against the same math versions', () async {
    final junior = await FakeLearningCatalogRepository().loadCatalog();
    final senior =
        await FakeLearningCatalogRepository(seniorEligible: true).loadCatalog();
    expect(senior.subjects.map((s) => s.slug), ['math', 'science']);
    expect(
      junior.topicVersionIds.intersection(senior.topicVersionIds),
      junior.topicVersionIds,
    );
  });

  test('completing counting unlocks addition and enables resume', () async {
    final repo = FakeLearningCatalogRepository(
      countingCompleted: true,
      additionStarted: true,
    );
    final math = (await repo.loadSubject('subject-math'))!;
    expect(math.topics.first.isCompleted, isTrue);
    expect(math.topics.last.isLocked, isFalse);
    expect(math.nextTopic?.canResume, isTrue);
    expect(math.nextTopic?.resumeSeconds, 90);
  });

  test('loadSubject returns null for an invisible subject', () async {
    final repo = FakeLearningCatalogRepository();
    expect(await repo.loadSubject('subject-science'), isNull);
  });

  test('failOnce recovers on the next read', () async {
    final repo = FakeLearningCatalogRepository(failOnce: true);
    await expectLater(repo.loadCatalog(), throwsStateError);
    final catalog = await repo.loadCatalog();
    expect(catalog.subjects, isNotEmpty);
    expect(repo.loadCount, 2);
  });

  test('empty and cache modes are available to the UI', () async {
    final empty = await FakeLearningCatalogRepository(empty: true).loadCatalog();
    expect(empty.isEmpty, isTrue);

    final cached =
        await FakeLearningCatalogRepository(servesCache: true).loadCatalog();
    expect(cached.fromCache, isTrue);
  });
}
