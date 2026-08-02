import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('GameOriginPolicy', () {
    test('allows fixture and matching https hosts only', () {
      expect(
        GameOriginPolicy.originsForEntryRef('fixture://number_rush'),
        ['fixture://number_rush'],
      );
      expect(
        GameOriginPolicy.originsForEntryRef('https://games.example/play'),
        ['https://games.example'],
      );
      expect(GameOriginPolicy.originsForEntryRef('http://evil'), isEmpty);

      final allowed = ['fixture://number_rush', 'https://games.example'];
      expect(
        GameOriginPolicy.allowsNavigation(
          allowedOrigins: allowed,
          url: 'fixture://number_rush',
        ),
        isTrue,
      );
      expect(
        GameOriginPolicy.allowsNavigation(
          allowedOrigins: allowed,
          url: 'https://games.example/level/1',
        ),
        isTrue,
      );
      expect(
        GameOriginPolicy.allowsNavigation(
          allowedOrigins: allowed,
          url: 'https://evil.example/',
        ),
        isFalse,
      );
    });
  });

  group('GameBridgeMessage', () {
    test('accepts known types and rejects unknown or oversized', () {
      expect(
        GameBridgeMessage.tryParse({'type': 'ready'})?.kind,
        GameBridgeInboundKind.ready,
      );
      expect(GameBridgeMessage.tryParse({'type': 'hack'}), isNull);
      expect(
        GameBridgeMessage.tryParse({
          'type': 'completed',
          'payload': {'x': 'y' * 9000},
        }),
        isNull,
      );
    });
  });
}
