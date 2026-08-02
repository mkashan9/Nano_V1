import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:nano_games/nano_games.dart';

void main() {
  test('play settings respect classroom mode gates', () {
    const open = GamePlaySettings();
    expect(open.effectiveSoundEnabled, isTrue);
    expect(open.effectiveHapticsEnabled, isTrue);

    const quiet = GamePlaySettings(
      soundEnabled: true,
      hapticsEnabled: true,
      classroomMode: true,
    );
    expect(quiet.effectiveSoundEnabled, isFalse);
    expect(quiet.effectiveHapticsEnabled, isFalse);
    expect(quiet.effectiveReducedMotion, isTrue);
    expect(quiet.toBridgeJson()['classroom_mode'], isTrue);
  });

  test('counting feedback skips when classroom mode is on', () async {
    final feedback = CountingGameFeedback(
      const GamePlaySettings(classroomMode: true),
    );
    await feedback.tick();
    await feedback.success();
    expect(feedback.soundAttempts, 0);
    expect(feedback.hapticAttempts, 0);
  });

  test('bridge session_started includes settings', () {
    final session = GameSessionStart(
      sessionId: 's1',
      playToken: 'tokentokentoken12',
      gameVersionId: 'v1',
      slug: 'number_rush',
      titleEn: 'Number Rush',
      entryKind: GameEntryKind.web,
      entryRef: 'fixture://number_rush',
      allowedOrigins: const ['fixture://number_rush'],
      expiresAt: DateTime.utc(2026, 8, 2, 14),
    );
    final bridge = GameBridgeController(
      session: session,
      settings: const GamePlaySettings(classroomMode: true),
    );
    final envelope = bridge.sessionStartedEnvelope();
    final settings =
        (envelope['payload'] as Map)['settings'] as Map<String, dynamic>;
    expect(settings['classroom_mode'], isTrue);
    expect(settings['sound_enabled'], isFalse);
  });
}
