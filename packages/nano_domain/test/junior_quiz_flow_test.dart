import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

TopicQuiz _safeQuiz({int questions = 2}) {
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
  group('JuniorQuizFlow', () {
    test('starts on the first question with ready mood', () {
      final flow = JuniorQuizFlow.start(_safeQuiz());
      expect(flow.currentIndex, 0);
      expect(flow.mood, CompanionQuizMood.ready);
      expect(flow.hasSelection, isFalse);
      expect(flow.finished, isFalse);
    });

    test('rejects authoring rows that leak correctness', () {
      expect(
        () => JuniorQuizFlow.start(
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

    test('select then advance walks one question per screen', () {
      var flow = JuniorQuizFlow.start(_safeQuiz());
      flow = flow.select('b');
      expect(flow.mood, CompanionQuizMood.encouraging);
      expect(flow.canAdvance, isTrue);
      flow = flow.advance();
      expect(flow.currentIndex, 1);
      expect(flow.selectedOptionId, isNull);
      flow = flow.select('a').advance();
      expect(flow.finished, isTrue);
      expect(flow.mood, CompanionQuizMood.finished);
      expect(flow.promptFor(NanoAppLocale.en), contains('score will be saved later'));
    });

    test('cannot advance without a selection', () {
      final flow = JuniorQuizFlow.start(_safeQuiz());
      expect(flow.advance().currentIndex, 0);
    });
  });
}
