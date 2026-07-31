import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('classroom mode disables sound/haptics and forces reduced motion', () {
    const prefs = AccessibilityPreferences(
      soundEnabled: true,
      hapticsEnabled: true,
      reducedMotion: false,
      classroomMode: true,
    );
    expect(prefs.effectiveSoundEnabled, isFalse);
    expect(prefs.effectiveHapticsEnabled, isFalse);
    expect(prefs.effectiveReducedMotion, isTrue);
  });

  test('copyWith preserves unset fields', () {
    const base = AccessibilityPreferences(textScale: 1.2);
    final next = base.copyWith(reducedMotion: true);
    expect(next.textScale, 1.2);
    expect(next.reducedMotion, isTrue);
  });
}
