import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('feedback respects disabled sound and haptics', () async {
    final feedback = NanoFeedback(
      preferences: const AccessibilityPreferences(
        soundEnabled: false,
        hapticsEnabled: false,
      ),
    );
    await feedback.success();
    expect(feedback.lastSoundCue, isNull);
    expect(feedback.hapticCount, 0);
  });

  test('feedback records cues when enabled', () async {
    final feedback = NanoFeedback();
    await feedback.playSound(NanoSoundCue.tap);
    expect(feedback.lastSoundCue, NanoSoundCue.tap);
  });

  testWidgets('motion resolves to zero under reduced motion', (tester) async {
    late Duration resolved;
    await tester.pumpWidget(
      NanoAccessibilityScope(
        preferences: const AccessibilityPreferences(reducedMotion: true),
        feedback: NanoFeedback(
          preferences: const AccessibilityPreferences(reducedMotion: true),
        ),
        child: Builder(
          builder: (context) {
            resolved = NanoMotion.resolve(context, NanoMotion.normal);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(resolved, Duration.zero);
  });
}
