import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('CompanionNamePolicy', () {
    test('defaults to Nori and accepts bilingual names', () {
      expect(CompanionNamePolicy.defaultName, 'Nori');
      expect(CompanionNamePolicy.validate('Nori'), isNull);
      expect(CompanionNamePolicy.validate('  Tara  '), isNull);
      expect(CompanionNamePolicy.validate('نور'), isNull);
    });

    test('rejects blank, overlong, and symbol-only names', () {
      expect(CompanionNamePolicy.validate('   '), isNotNull);
      expect(CompanionNamePolicy.validate('a' * 25), isNotNull);
      expect(CompanionNamePolicy.validate('!!!'), isNotNull);
      expect(CompanionNamePolicy.validate('123'), isNotNull);
    });

    test('collapses internal whitespace', () {
      expect(CompanionNamePolicy.normalize('  Little   Star '), 'Little Star');
    });
  });

  group('StudentPreferences', () {
    test('round-trips through a database row', () {
      final row = {
        'user_id': 'u1',
        'companion_name': 'Tara',
        'locale': 'ur',
        'sound_enabled': false,
        'haptics_enabled': true,
        'captions_enabled': true,
        'reduced_motion': true,
        'classroom_mode': false,
        'text_scale': 1.2,
      };
      final prefs = StudentPreferences.fromRow(row);
      expect(prefs.companionName, 'Tara');
      expect(prefs.locale, NanoAppLocale.ur);
      expect(prefs.accessibility.soundEnabled, isFalse);
      expect(prefs.accessibility.reducedMotion, isTrue);
      expect(prefs.toRow()['locale'], 'ur');
      expect(prefs.toRow()['companion_name'], 'Tara');
    });

    test('falls back to Nori when the stored name is blank', () {
      final prefs = StudentPreferences.fromRow({
        'user_id': 'u1',
        'companion_name': '  ',
        'locale': 'en',
      });
      expect(prefs.companionName, CompanionNamePolicy.defaultName);
    });
  });

  group('OnboardingStep preferences', () {
    test('includes the preferences step between experience and context', () {
      expect(OnboardingStep.experience.next, OnboardingStep.preferences);
      expect(OnboardingStep.preferences.next, OnboardingStep.context);
      expect(OnboardingStepX.fromWire('preferences'), OnboardingStep.preferences);
    });
  });
}
