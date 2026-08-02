import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:nano_games/nano_games.dart';

void main() {
  test('bridge accepts ready/completed and rejects unknown', () {
    final session = GameSessionStart(
      sessionId: 's1',
      playToken: 'tok',
      gameVersionId: 'v1',
      slug: 'number_rush',
      titleEn: 'Number Rush',
      entryKind: GameEntryKind.web,
      entryRef: 'fixture://number_rush',
      allowedOrigins: const ['fixture://number_rush'],
      expiresAt: DateTime.utc(2026, 8, 2, 14),
    );
    var rejected = false;
    final bridge = GameBridgeController(
      session: session,
      onUnknownOrOversized: () => rejected = true,
    );

    expect(bridge.handleInbound({'type': 'ready'}), isTrue);
    expect(bridge.ready, isTrue);
    expect(bridge.handleInbound({'type': 'open-devtools'}), isFalse);
    expect(rejected, isTrue);
    expect(
      bridge.handleInbound({
        'type': 'completed',
        'payload': {'raw_score': 2, 'session_id': 's1'},
      }),
      isTrue,
    );
    expect(bridge.lastCompleted?.payload['raw_score'], 2);
    expect(bridge.sessionStartedEnvelope()['type'], 'session_started');
    expect(
      (bridge.sessionStartedEnvelope()['payload'] as Map)['signed_token'],
      'tok',
    );
  });
}
