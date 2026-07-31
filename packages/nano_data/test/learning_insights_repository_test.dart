import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('fake insights repository', () {
    test('returns subjects and a ranked resume suggestion', () async {
      final repository = FakeLearningInsightsRepository();
      final insights = await repository.loadInsights();

      expect(repository.loadCount, 1);
      expect(insights.subjects.length, 2);
      expect(insights.recommendation?.reason, NextUpReason.resume);
      expect(insights.alternatives.single.reason, NextUpReason.nextInSubject);
      expect(
        insights.suggestions.map((item) => item.rank),
        [1, 2],
      );
    });

    test('suggestions point at topics the fake catalog can open', () async {
      final catalog = await FakeLearningCatalogRepository(
        seniorEligible: true,
      ).loadCatalog();
      final insights = await FakeLearningInsightsRepository().loadInsights();
      final known = catalog.subjects
          .expand((subject) => subject.topics)
          .map((topic) => topic.topicVersionId)
          .toSet();

      for (final suggestion in insights.suggestions) {
        expect(known, contains(suggestion.topicVersionId));
      }
    });

    test('a finished learner gets no suggestion instead of a blank list',
        () async {
      final insights =
          await FakeLearningInsightsRepository(allFinished: true).loadInsights();

      expect(insights.isEmpty, isFalse);
      expect(insights.recommendation, isNull);
      expect(insights.subjects.single.isFinished, isTrue);
    });

    test('an empty repository reports nothing rather than throwing', () async {
      final insights =
          await FakeLearningInsightsRepository(empty: true).loadInsights();
      expect(insights.isEmpty, isTrue);
      expect(insights.recommendation, isNull);
    });

    test('failures surface so the page can offer a retry', () {
      expect(
        FakeLearningInsightsRepository(alwaysFail: true).loadInsights,
        throwsStateError,
      );
    });

    test('an untouched learner has locked topics counted separately', () async {
      final insights = await FakeLearningInsightsRepository(mathStarted: false)
          .loadInsights();
      final math = insights.subjects.first;

      expect(math.topicsCompleted, 0);
      expect(math.topicsLocked, 1);
      expect(math.isStarted, isFalse);
      // Locked content still counts toward the total so the learner sees why
      // the subject is not finished.
      expect(math.topicsTotal, 2);
    });
  });
}
