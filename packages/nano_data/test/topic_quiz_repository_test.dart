import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('fake topic quiz', () {
    test('lists seeded published quizzes in topic order', () async {
      final repository = FakeTopicQuizRepository();
      final items = await repository.listQuizzes();
      expect(items.length, 3);
      expect(items.map((i) => i.topicSlug).toList(), [
        'addition',
        'counting',
        'living-things',
      ]);
      expect(items.every((item) => item.status == QuestionStatus.published), isTrue);
    });

    test('createDraft attaches ordered published questions', () async {
      final repository = FakeTopicQuizRepository();
      final draft = await repository.createDraft(
        topicVersionId: '40000000-0000-0000-0000-000000000006',
        title: 'Ecosystems check',
        questionVersionIds: const [
          '51000000-0000-0000-0000-000000000001',
          '51000000-0000-0000-0000-000000000002',
        ],
      );
      expect(draft.status, QuestionStatus.draft);
      expect(draft.items.map((i) => i.sortOrder).toList(), [1, 2]);
      expect(repository.createCount, 1);
    });

    test('publish retires prior published quiz on the same topic', () async {
      final repository = FakeTopicQuizRepository();
      final counting = (await repository.listQuizzes())
          .firstWhere((q) => q.topicSlug == 'counting');
      final draft = await repository.createDraft(
        topicVersionId: counting.topicVersionId,
        title: 'Counting revised',
        questionVersionIds: [counting.items.first.questionVersionId],
      );
      final published = await repository.publish(draft.id);
      expect(published.status, QuestionStatus.published);
      expect(repository.publishCount, 1);

      final items = await repository.listQuizzes();
      final prior = items.firstWhere((q) => q.id == counting.id);
      expect(prior.status, QuestionStatus.retired);

      final retired = await repository.retire(published.id);
      expect(retired.status, QuestionStatus.retired);
    });

    test('search filters by title', () async {
      final repository = FakeTopicQuizRepository();
      final items = await repository.listQuizzes(query: 'living');
      expect(items.single.topicSlug, 'living-things');
    });

    test('failures surface', () {
      expect(
        FakeTopicQuizRepository(alwaysFail: true).listQuizzes,
        throwsStateError,
      );
    });
  });
}
