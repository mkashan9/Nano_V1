import 'package:nano_data/nano_data.dart';
import 'package:test/test.dart';

const _counting = 'tv-counting-1';
const _q1 = '51000000-0000-0000-0000-000000000001';
const _q2 = '51000000-0000-0000-0000-000000000002';

Future<String> _answerAll(
  FakeQuizAttemptRepository attempts, {
  bool correctly = true,
}) async {
  final session = await attempts.startOrResume(_counting);
  await attempts.saveAnswer(
    attemptId: session.attemptId,
    questionVersionId: _q1,
    selectedOptionId: correctly ? 'b' : 'a',
  );
  await attempts.saveAnswer(
    attemptId: session.attemptId,
    questionVersionId: _q2,
    selectedOptionId: correctly ? 'b' : 'a',
  );
  return session.attemptId;
}

void main() {
  group('fake attempt results', () {
    test('results are refused until the attempt is submitted', () async {
      final attempts = FakeQuizAttemptRepository();
      final attemptId = await _answerAll(attempts);

      await expectLater(attempts.result(attemptId), throwsStateError);

      await attempts.submit(attemptId);
      expect((await attempts.result(attemptId)).items, isNotEmpty);
    });

    test('the review names the correct option and explains it', () async {
      final attempts = FakeQuizAttemptRepository();
      final attemptId = await _answerAll(attempts, correctly: false);
      await attempts.submit(attemptId);

      final result = await attempts.result(attemptId);

      expect(result.scorePercent, 0);
      expect(result.passed, isFalse);
      expect(result.items.length, 2);
      final first = result.items.first;
      expect(first.wasCorrect, isFalse);
      expect(first.selectedOptionId, 'a');
      expect(first.correctOptionId, 'b');
      expect(first.explanation, isNotEmpty);
    });

    test('the learner quiz itself still hides correctness', () async {
      // The review is the only place correctness appears, and only after
      // submit; the quiz a learner answers must stay clean.
      final quiz = await FakeLearnerQuizRepository().quizForTopic(_counting);

      expect(quiz!.isLearnerSafe, isTrue);
      expect(quiz.items.every((item) => item.explanation.isEmpty), isTrue);
    });

    test('a retake opens the next attempt and keeps the history', () async {
      final attempts = FakeQuizAttemptRepository();
      final first = await _answerAll(attempts, correctly: false);
      await attempts.submit(first);

      final second = await _answerAll(attempts);
      await attempts.submit(second);

      final history = await attempts.history(topicVersionId: _counting);
      expect(history.map((entry) => entry.attemptNumber), [2, 1]);
      expect(history.first.scorePercent, 100);
      expect(history.last.scorePercent, 0);

      final result = await attempts.result(second);
      expect(result.attemptNumber, 2);
      expect(result.attemptsUsed, 2);
    });

    test('an exhausted retake budget refuses a new attempt', () async {
      final attempts = FakeQuizAttemptRepository(maxRetakes: 1);
      final first = await _answerAll(attempts, correctly: false);
      await attempts.submit(first);

      final firstResult = await attempts.result(first);
      expect(firstResult.retakesRemaining, 1);
      expect(firstResult.canRetake, isTrue);

      final second = await _answerAll(attempts, correctly: false);
      await attempts.submit(second);

      final secondResult = await attempts.result(second);
      expect(secondResult.retakesRemaining, 0);
      expect(secondResult.canRetake, isFalse);

      await expectLater(attempts.startOrResume(_counting), throwsStateError);
    });

    test('history only lists submitted attempts', () async {
      final attempts = FakeQuizAttemptRepository();
      await _answerAll(attempts);

      expect(await attempts.history(), isEmpty);
    });
  });
}
