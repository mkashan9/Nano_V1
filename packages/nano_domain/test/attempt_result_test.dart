import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

Map<String, dynamic> _row({
  bool passed = false,
  int? maxRetakes,
  int? retakesRemaining,
  bool canRetake = true,
}) {
  return {
    'attempt_id': 'attempt-1',
    'quiz_version_id': 'quiz-1',
    'topic_version_id': 'topic-1',
    'attempt_number': 2,
    'score_percent': 50,
    'passed': passed,
    'correct_count': 1,
    'total_count': 2,
    'pass_percent': 70,
    'quiz_title': 'Counting check',
    'quiz_title_ur': 'گنتی کی جانچ',
    'attempts_used': 2,
    'max_retakes': maxRetakes,
    'retakes_remaining': retakesRemaining,
    'can_retake': canRetake,
    'scored_at': '2026-08-01T06:00:00Z',
    'items': [
      {
        'sort_order': 2,
        'question_version_id': 'q2',
        'stem': 'What is 2 + 3?',
        'stem_ur': '۲ + ۳ کیا ہے؟',
        'options': [
          {'id': 'a', 'label': '4'},
          {'id': 'b', 'label': '5'},
        ],
        'selected_option_id': 'a',
        'correct_option_id': 'b',
        'was_correct': false,
        'explanation': 'Two plus three is five.',
        'explanation_ur': 'دو جمع تین پانچ ہے۔',
      },
      {
        'sort_order': 1,
        'question_version_id': 'q1',
        'stem': 'How many apples?',
        'options': [
          {'id': 'a', 'label': 'Three'},
          {'id': 'b', 'label': 'Five'},
        ],
        'selected_option_id': 'b',
        'correct_option_id': 'b',
        'was_correct': true,
        'explanation': 'Counting to five means there are five.',
      },
    ],
  };
}

void main() {
  group('AttemptResult', () {
    test('parses the server payload and orders the review', () {
      final result = AttemptResult.fromRow(_row());

      expect(result.attemptId, 'attempt-1');
      expect(result.attemptNumber, 2);
      expect(result.scorePercent, 50);
      expect(result.passed, isFalse);
      expect(result.passPercent, 70);
      expect(result.items.map((item) => item.sortOrder), [1, 2]);
      expect(result.missedItems.map((item) => item.questionVersionId), ['q2']);
    });

    test('pass state comes from the server, not from the percent', () {
      // 50% against a 70% pass mark, but the server said it passed.
      final result = AttemptResult.fromRow(_row(passed: true));

      expect(result.passed, isTrue);
      expect(result.needsReview, isFalse);
    });

    test('an uncapped quiz reports no retake budget', () {
      final result = AttemptResult.fromRow(_row());

      expect(result.isCapped, isFalse);
      expect(result.retakesRemaining, isNull);
      expect(result.canRetake, isTrue);
    });

    test('an exhausted budget refuses the retake', () {
      final result = AttemptResult.fromRow(
        _row(maxRetakes: 1, retakesRemaining: 0, canRetake: false),
      );

      expect(result.isCapped, isTrue);
      expect(result.retakesRemaining, 0);
      expect(result.canRetake, isFalse);
    });

    test('Urdu review falls back to English when a translation is missing', () {
      final result = AttemptResult.fromRow(_row());
      final translated = result.items.last;
      final untranslated = result.items.first;

      expect(translated.stemFor(NanoAppLocale.ur), '۲ + ۳ کیا ہے؟');
      expect(translated.explanationFor(NanoAppLocale.ur), 'دو جمع تین پانچ ہے۔');
      expect(untranslated.stemFor(NanoAppLocale.ur), 'How many apples?');
      expect(
        untranslated.explanationFor(NanoAppLocale.ur),
        'Counting to five means there are five.',
      );
    });

    test('review names both the chosen and the correct option', () {
      final missed = AttemptResult.fromRow(_row()).items.last;

      expect(missed.selectedLabelFor(NanoAppLocale.en), '4');
      expect(missed.correctLabelFor(NanoAppLocale.en), '5');
      expect(missed.skipped, isFalse);
      expect(missed.hasExplanation, isTrue);
    });

    test('an unanswered question reads as skipped', () {
      final item = AttemptReviewItem.fromRow({
        'sort_order': 1,
        'question_version_id': 'q1',
        'stem': 'Skipped?',
        'options': [
          {'id': 'a', 'label': 'Yes'},
        ],
        'correct_option_id': 'a',
        'was_correct': false,
      });

      expect(item.skipped, isTrue);
      expect(item.selectedLabelFor(NanoAppLocale.en), isNull);
      expect(item.hasExplanation, isFalse);
    });
  });

  group('QuizAttemptHistoryEntry', () {
    test('parses a submitted attempt', () {
      final entry = QuizAttemptHistoryEntry.fromRow({
        'attempt_id': 'attempt-1',
        'topic_version_id': 'topic-1',
        'quiz_version_id': 'quiz-1',
        'attempt_number': 3,
        'quiz_title': 'Counting check',
        'score_percent': 100,
        'passed': true,
        'submitted_at': '2026-08-01T06:00:00Z',
      });

      expect(entry.attemptNumber, 3);
      expect(entry.isScored, isTrue);
      expect(entry.passed, isTrue);
      expect(entry.submittedAt?.isUtc, isTrue);
    });

    test('an open attempt has no score yet', () {
      final entry = QuizAttemptHistoryEntry.fromRow({
        'attempt_id': 'attempt-2',
        'attempt_number': 1,
      });

      expect(entry.isScored, isFalse);
      expect(entry.passed, isNull);
    });
  });

  group('NextUpReason', () {
    test('an unpassed quiz becomes review work', () {
      expect(NextUpReason.fromName('review_quiz'), NextUpReason.reviewQuiz);
    });
  });
}
