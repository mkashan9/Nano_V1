import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('FakeStudentPreferencesRepository', () {
    test('starts with Nori defaults', () async {
      final repo = FakeStudentPreferencesRepository();
      final prefs = await repo.load('u1');
      expect(prefs.companionName, 'Nori');
      expect(prefs.locale, NanoAppLocale.en);
      expect(prefs.accessibility.soundEnabled, isTrue);
    });

    test('persists companion name, locale, and accessibility', () async {
      final repo = FakeStudentPreferencesRepository();
      await repo.save(
        const StudentPreferences(
          userId: 'u1',
          companionName: 'Tara',
          locale: NanoAppLocale.ur,
          accessibility: AccessibilityPreferences(soundEnabled: false),
        ),
      );
      final reloaded = await repo.load('u1');
      expect(reloaded.companionName, 'Tara');
      expect(reloaded.locale, NanoAppLocale.ur);
      expect(reloaded.accessibility.soundEnabled, isFalse);
    });

    test('rejects blank companion names', () async {
      final repo = FakeStudentPreferencesRepository();
      expect(
        () => repo.save(
          const StudentPreferences(userId: 'u1', companionName: '   '),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
