import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:nano_games/nano_games.dart';

void main() {
  test('native flutter surface gate accepts shape_sort fixture', () {
    final session = GameSessionStart(
      sessionId: 's1',
      playToken: 'tokentokentoken12',
      gameVersionId: 'v-shape',
      slug: 'shape_sort',
      titleEn: 'Shape Sort',
      entryKind: GameEntryKind.flutter,
      entryRef: 'fixture://shape_sort',
      allowedOrigins: const ['fixture://shape_sort'],
      expiresAt: DateTime.utc(2026, 8, 2, 14),
    );
    expect(canUseNativeFlutterSurface(session), isTrue);
    expect(canUseFixtureSurface(session), isFalse);
  });
}
