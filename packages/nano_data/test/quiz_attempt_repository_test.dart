import 'package:nano_data/nano_data.dart';
import 'package:test/test.dart';

void main() {
  group('fake quiz attempt', () {
    test('resume preserves answers', () async {
      final repository = FakeQuizAttemptRepository();
      final first = await repository.startOrResume(
        '40000000-0000-0000-0000-000000000001',
      );
      await repository.saveAnswer(
        attemptId: first.attemptId,
        questionVersionId: '51000000-0000-0000-0000-000000000001',
        selectedOptionId: 'b',
      );
      final resumed = await repository.startOrResume(
        '40000000-0000-0000-0000-000000000001',
      );
      expect(resumed.resumed, isTrue);
      expect(resumed.answers['51000000-0000-0000-0000-000000000001'], 'b');
    });

    test('submit scores on the repository, not the client flow', () async {
      final repository = FakeQuizAttemptRepository();
      final session = await repository.startOrResume(
        '40000000-0000-0000-0000-000000000001',
      );
      await repository.saveAnswer(
        attemptId: session.attemptId,
        questionVersionId: '51000000-0000-0000-0000-000000000001',
        selectedOptionId: 'b',
      );
      await repository.saveAnswer(
        attemptId: session.attemptId,
        questionVersionId: '51000000-0000-0000-0000-000000000002',
        selectedOptionId: 'b',
      );
      final score = await repository.submit(session.attemptId);
      expect(score.scorePercent, 100);
      expect(score.passed, isTrue);

      final again = await repository.submit(session.attemptId);
      expect(again.idempotent, isTrue);
      expect(again.scorePercent, score.scorePercent);
    });
  });
}
