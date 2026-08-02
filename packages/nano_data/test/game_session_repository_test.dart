import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('fake session start and client completed without verify', () async {
    final repo = FakeGameSessionRepository();
    final start = await repo.startSession('v-number');
    expect(start.playToken, isNotEmpty);
    expect(start.allowedOrigins, contains('fixture://number_rush'));

    final result = await repo.reportClientCompleted(
      sessionId: start.sessionId,
      playToken: start.playToken,
      payload: {'raw_score': 3},
    );
    expect(result.verified, isFalse);
    expect(result.status, GameSessionStatus.completed);
  });
}
