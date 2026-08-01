import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('question options', () {
    test('maps a row including correctness', () {
      final option = QuestionOption.fromRow({
        'id': 'b',
        'label': 'Five',
        'label_ur': 'پانچ',
        'is_correct': true,
      });
      expect(option.isCorrect, isTrue);
      expect(option.labelFor(NanoAppLocale.ur), 'پانچ');
      expect(option.toLearnerRow().containsKey('is_correct'), isFalse);
    });
  });

  group('question version', () {
    test('reads a bank row', () {
      final question = QuestionVersion.fromRow({
        'question_version_id': 'qv-1',
        'question_id': 'q-1',
        'slug': 'counting-how-many',
        'version': 2,
        'status': 'published',
        'kind': 'multiple_choice',
        'stem': 'How many?',
        'stem_ur': 'کتنے؟',
        'options': [
          {'id': 'a', 'label': '1', 'is_correct': false},
          {'id': 'b', 'label': '2', 'is_correct': true},
        ],
        'explanation': 'Because.',
        'difficulty': 'easy',
        'locale_policy': 'both',
        'provenance': 'seed',
        'stem_hash': 'abc',
        'published_at': '2026-08-01T00:00:00Z',
      });

      expect(question.id, 'qv-1');
      expect(question.status, QuestionStatus.published);
      expect(question.correctOption?.id, 'b');
      expect(question.stemFor(NanoAppLocale.ur), 'کتنے؟');
      expect(question.status.isEditable, isFalse);
    });

    test('carries duplicate warnings from create_question_draft', () {
      final question = QuestionVersion.fromRow({
        'question_version_id': 'qv-2',
        'question_id': 'q-2',
        'slug': 'dup',
        'status': 'draft',
        'stem': 'How many?',
        'options': [
          {'id': 'a', 'label': '1', 'is_correct': true},
          {'id': 'b', 'label': '2', 'is_correct': false},
        ],
        'duplicates': [
          {
            'question_id': 'q-1',
            'question_version_id': 'qv-1',
            'slug': 'counting-how-many',
            'stem': 'How many?',
            'status': 'published',
            'version': 1,
          },
        ],
      });
      expect(question.hasDuplicates, isTrue);
      expect(question.duplicates.single.slug, 'counting-how-many');
    });
  });

  group('preview policy', () {
    test('normalizes stems the way the server hashes them', () {
      expect(
        QuestionPreviewPolicy.normalizeStem('  HOW many   apples  '),
        'how many apples',
      );
    });

    test('rejects options without exactly one correct answer', () {
      expect(
        QuestionPreviewPolicy.optionsValid(
          kind: QuestionKind.multipleChoice,
          options: const [
            QuestionOption(id: 'a', label: 'A'),
            QuestionOption(id: 'b', label: 'B'),
          ],
        ),
        isFalse,
      );
      expect(
        QuestionPreviewPolicy.optionsValid(
          kind: QuestionKind.trueFalse,
          options: const [
            QuestionOption(id: 'yes', label: 'Yes', isCorrect: true),
            QuestionOption(id: 'no', label: 'No'),
          ],
        ),
        isTrue,
      );
      expect(
        QuestionPreviewPolicy.optionsValid(
          kind: QuestionKind.trueFalse,
          options: const [
            QuestionOption(id: 'yes', label: 'Yes', isCorrect: true),
          ],
        ),
        isFalse,
      );
    });
  });

  group('wire names', () {
    test('round-trip kind and status', () {
      expect(QuestionKind.fromName('true_false'), QuestionKind.trueFalse);
      expect(QuestionKind.multipleChoice.wireName, 'multiple_choice');
      expect(QuestionStatus.fromName('retired'), QuestionStatus.retired);
      expect(QuestionDifficulty.fromName('hard'), QuestionDifficulty.hard);
    });
  });
}
