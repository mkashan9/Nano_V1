import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('ScoreResult', () {
    test('reads a submit payload', () {
      final score = ScoreResult.fromRow({
        'attempt_id': 'a1',
        'score_percent': 100,
        'passed': true,
        'correct_count': 2,
        'total_count': 2,
        'idempotent': true,
        'scored_at': '2026-08-01T00:00:00Z',
      });
      expect(score.passed, isTrue);
      expect(score.idempotent, isTrue);
      expect(score.scorePercent, 100);
    });
  });

  group('QuizAttemptSession', () {
    test('maps resumed answers', () {
      final session = QuizAttemptSession.fromRow({
        'attempt_id': 'a1',
        'quiz_version_id': 'q1',
        'topic_version_id': 't1',
        'attempt_number': 2,
        'resumed': true,
        'answers': [
          {
            'question_version_id': 'qv1',
            'selected_option_id': 'b',
          },
        ],
      });
      expect(session.resumed, isTrue);
      expect(session.answers['qv1'], 'b');
    });
  });

  group('flow resume', () {
    test('junior resume lands on first unanswered', () {
      final quiz = TopicQuiz(
        id: 'q',
        topicVersionId: 't',
        title: 'T',
        items: const [
          QuizItem(
            sortOrder: 1,
            questionVersionId: 'qv1',
            stem: 'One?',
            options: [QuestionOption(id: 'a', label: 'A')],
          ),
          QuizItem(
            sortOrder: 2,
            questionVersionId: 'qv2',
            stem: 'Two?',
            options: [QuestionOption(id: 'a', label: 'A')],
          ),
        ],
      );
      final flow = JuniorQuizFlow.resume(quiz, {'qv1': 'a'});
      expect(flow.currentIndex, 1);
      expect(flow.selections['qv1'], 'a');
    });
  });
}
