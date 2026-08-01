import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

TopicQuiz _safeQuiz({int questions = 3}) {
  return TopicQuiz(
    id: 'quiz-1',
    topicVersionId: 'topic-1',
    title: 'Practice',
    status: QuestionStatus.published,
    items: [
      for (var i = 1; i <= questions; i++)
        QuizItem(
          sortOrder: i,
          questionVersionId: 'qv-$i',
          stem: 'Question $i?',
          options: const [
            QuestionOption(id: 'a', label: 'A'),
            QuestionOption(id: 'b', label: 'B'),
          ],
        ),
    ],
  );
}

void main() {
  group('SeniorQuizFlow', () {
    test('starts on question one with no review', () {
      final flow = SeniorQuizFlow.start(_safeQuiz());
      expect(flow.currentIndex, 0);
      expect(flow.reviewing, isFalse);
      expect(flow.allAnswered, isFalse);
    });

    test('rejects authoring rows that leak correctness', () {
      expect(
        () => SeniorQuizFlow.start(
          TopicQuiz(
            id: 'bad',
            topicVersionId: 't',
            title: 'Bad',
            items: const [
              QuizItem(
                sortOrder: 1,
                questionVersionId: 'qv',
                stem: 'Q?',
                options: [
                  QuestionOption(id: 'a', label: 'A', isCorrect: true),
                ],
              ),
            ],
          ),
        ),
        throwsArgumentError,
      );
    });

    test('jump and previous/next preserve selections', () {
      var flow = SeniorQuizFlow.start(_safeQuiz())
          .select('a')
          .goNext()
          .select('b')
          .jumpTo(0);
      expect(flow.currentIndex, 0);
      expect(flow.selectedOptionId, 'a');
      flow = flow.goNext();
      expect(flow.selectedOptionId, 'b');
      expect(flow.answeredCount, 2);
    });

    test('review lists unanswered and finish requires all', () {
      var flow = SeniorQuizFlow.start(_safeQuiz()).select('a').enterReview();
      expect(flow.reviewing, isTrue);
      expect(flow.unansweredIndexes, [1, 2]);
      expect(flow.canFinish, isFalse);
      flow = flow.jumpTo(1).select('a').jumpTo(2).select('b');
      expect(flow.allAnswered, isTrue);
      flow = flow.enterReview().finish();
      expect(flow.finished, isTrue);
    });
  });
}
