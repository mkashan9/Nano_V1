import 'package:nano_data/nano_data.dart';
import 'package:test/test.dart';

void main() {
  group('fake learner quiz', () {
    test('returns learner-safe counting quiz', () async {
      final repository = FakeLearnerQuizRepository();
      final quiz = await repository.quizForTopic(
        '40000000-0000-0000-0000-000000000001',
      );
      expect(quiz, isNotNull);
      expect(quiz!.isLearnerSafe, isTrue);
      expect(quiz.items.length, greaterThanOrEqualTo(2));
      expect(quiz.items.every((item) => !item.exposesCorrectness), isTrue);
    });

    test('returns null for unknown topics', () async {
      final repository = FakeLearnerQuizRepository();
      expect(
        await repository.quizForTopic('00000000-0000-0000-0000-000000000099'),
        isNull,
      );
    });

    test('failures surface', () {
      expect(
        () => FakeLearnerQuizRepository(alwaysFail: true)
            .quizForTopic('40000000-0000-0000-0000-000000000001'),
        throwsStateError,
      );
    });
  });
}
