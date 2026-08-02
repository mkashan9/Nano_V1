import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('fake session verifies completion and awards XP', () async {
    final repo = FakeGameSessionRepository();
    final start = await repo.startSession('v-number');
    expect(start.playToken, isNotEmpty);

    final result = await repo.reportClientCompleted(
      sessionId: start.sessionId,
      playToken: start.playToken,
      payload: {
        'session_id': start.sessionId,
        'raw_score': 3,
        'duration_ms': 1200,
        'nonce': 'fixture-nonce-001',
      },
    );
    expect(result.verified, isTrue);
    expect(result.xpAwarded, 20);
    expect(result.status, GameSessionStatus.completed);
  });

  test('fake session rejects impossible score', () async {
    final repo = FakeGameSessionRepository();
    final start = await repo.startSession('v-number');
    final result = await repo.reportClientCompleted(
      sessionId: start.sessionId,
      playToken: start.playToken,
      payload: {
        'session_id': start.sessionId,
        'raw_score': 99999,
        'duration_ms': 100,
        'nonce': 'fixture-nonce-bad',
      },
    );
    expect(result.verified, isFalse);
    expect(result.xpAwarded, 0);
  });

  test('fake session blocks disabled versions and reports kill status',
      () async {
    final repo = FakeGameSessionRepository(
      disabledVersionIds: {'v-number'},
    );
    expect(
      () => repo.startSession('v-number'),
      throwsA(isA<GameSessionBlocked>()),
    );

    final live = FakeGameSessionRepository();
    final start = await live.startSession('v-number');
    live.forceAbortActive();
    final status = await live.getPlayStatus(start.sessionId);
    expect(status.killSwitch, isTrue);
    expect(status.status, GameSessionStatus.aborted);
  });
}
