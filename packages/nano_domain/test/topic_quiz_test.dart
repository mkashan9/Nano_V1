import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('quiz policy', () {
    test('defaults preserve fixed order', () {
      const policy = QuizPolicy();
      expect(policy.preservesQuestionOrder, isTrue);
      expect(policy.passPercent, 70);
      expect(QuizOrderPolicy.fromName('shuffle'), QuizOrderPolicy.shuffle);
      expect(QuizOrderPolicy.fixed.wireName, 'fixed');
    });

    test('reads a policy row', () {
      final policy = QuizPolicy.fromRow({
        'pass_percent': 80,
        'timer_seconds': 120,
        'max_retakes': 2,
        'option_order_policy': 'shuffle',
        'question_order_policy': 'fixed',
        'locale_policy': 'en',
        'experience_policy': 'senior',
      });
      expect(policy.passPercent, 80);
      expect(policy.timerSeconds, 120);
      expect(policy.optionOrder, QuizOrderPolicy.shuffle);
      expect(policy.preservesQuestionOrder, isTrue);
    });
  });

  group('quiz item', () {
    test('maps authoring options with correctness', () {
      final item = QuizItem.fromRow({
        'sort_order': 2,
        'question_version_id': 'qv-1',
        'stem': 'What is 2 + 3?',
        'stem_ur': '۲ + ۳ کیا ہے؟',
        'options': [
          {'id': 'a', 'label': '4', 'is_correct': false},
          {'id': 'b', 'label': '5', 'is_correct': true},
        ],
      });
      expect(item.sortOrder, 2);
      expect(item.exposesCorrectness, isTrue);
      expect(item.stemFor(NanoAppLocale.ur), '۲ + ۳ کیا ہے؟');
    });

    test('learner options without is_correct are safe', () {
      final item = QuizItem.fromRow({
        'sort_order': 1,
        'question_version_id': 'qv-1',
        'stem': 'How many?',
        'options': [
          {'id': 'a', 'label': '1'},
          {'id': 'b', 'label': '2'},
        ],
      });
      expect(item.exposesCorrectness, isFalse);
    });
  });

  group('topic quiz', () {
    test('sorts items and reports learner safety', () {
      final quiz = TopicQuiz.fromRow({
        'quiz_version_id': 'quiz-1',
        'topic_version_id': 'topic-1',
        'topic_slug': 'counting',
        'topic_title': 'Counting',
        'status': 'published',
        'title': 'Counting check',
        'title_ur': 'گنتی',
        'pass_percent': 70,
        'question_order_policy': 'fixed',
        'items': [
          {
            'sort_order': 2,
            'question_version_id': 'qv-2',
            'stem': 'Second',
            'options': [
              {'id': 'a', 'label': 'A'},
            ],
          },
          {
            'sort_order': 1,
            'question_version_id': 'qv-1',
            'stem': 'First',
            'options': [
              {'id': 'a', 'label': 'A'},
            ],
          },
        ],
      });
      expect(quiz.items.map((i) => i.sortOrder).toList(), [1, 2]);
      expect(quiz.isPublished, isTrue);
      expect(quiz.isLearnerSafe, isTrue);
      expect(quiz.titleFor(NanoAppLocale.ur), 'گنتی');
    });
  });
}
