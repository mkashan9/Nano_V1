import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// MED-10: a learner who asked for stillness gets stillness.
///
/// This is the file that matters most in the module. Idle motion is a nicety;
/// overriding an accessibility preference is a harm, and the ways it happens
/// are all quiet ones — a tier table that outvotes a setting, a partial
/// implementation that slows motion instead of stopping it, a system-level
/// preference nobody read.
void main() {
  // Opt back in, or every assertion below would pass for the wrong reason: the
  // harness would have stopped the motion, not the accessibility preference.
  setUp(() => NoriLivingArt.debugAmbientMotionEnabled = true);
  tearDown(() => NoriLivingArt.debugAmbientMotionEnabled = false);

  Future<void> pumpStage(
    WidgetTester tester, {
    required AccessibilityPreferences preferences,
    CompanionMood mood = CompanionMood.celebration,
    bool platformDisablesAnimations = false,
  }) async {
    final stage = NanoLocaleScope(
      locale: NanoAppLocale.en,
      copy: const NanoCopy(NanoAppLocale.en),
      child: NanoAccessibilityScope(
        preferences: preferences,
        feedback: NanoFeedback(preferences: preferences),
        child: MaterialApp(
          home: Scaffold(
            body: CompanionStage(
              reaction: CompanionReaction(
                event: CompanionEvent.appOpen,
                mood: mood,
                script: const CompanionScript(
                  id: 'greeting-2',
                  text: 'Hello again.',
                ),
                // The loudest tier, so nothing can be excused as "this mood is
                // quiet anyway".
                tier: CompanionAssetTier.localAnimation,
                prominent: true,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      platformDisablesAnimations
          ? MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: stage,
            )
          : stage,
    );
    await tester.pump();
  }

  bool isMoving(WidgetTester tester) => find
      .descendant(
        of: find.byType(NoriLivingArt),
        matching: find.byType(Transform),
      )
      .evaluate()
      .isNotEmpty;

  testWidgets('by default Nori is alive', (tester) async {
    await pumpStage(tester, preferences: AccessibilityPreferences.defaults);

    expect(isMoving(tester), isTrue,
        reason: 'the control case must actually move, or nothing below proves '
            'anything');
  });

  testWidgets('reduced motion stops it completely, not partly', (tester) async {
    await pumpStage(
      tester,
      preferences: const AccessibilityPreferences(reducedMotion: true),
    );

    expect(isMoving(tester), isFalse);

    // And it stays stopped: a transform that appears one frame later is the
    // same failure, just harder to see.
    await tester.pump(const Duration(seconds: 1));
    expect(isMoving(tester), isFalse);
  });

  testWidgets('Classroom Mode stops it too, without reduced motion being set',
      (tester) async {
    // classroomMode implies effectiveReducedMotion. If this ever regresses,
    // a classroom of thirty screens starts breathing at once.
    await pumpStage(
      tester,
      preferences: const AccessibilityPreferences(classroomMode: true),
    );

    expect(isMoving(tester), isFalse);
  });

  testWidgets('the system setting is honoured even when the app setting is not',
      (tester) async {
    // A learner who turned it on at the OS level never visited our settings
    // screen, and should not have to.
    await pumpStage(
      tester,
      preferences: AccessibilityPreferences.defaults,
      platformDisablesAnimations: true,
    );

    expect(isMoving(tester), isFalse);
  });

  testWidgets('every mood is silenced, not just the loud one', (tester) async {
    for (final mood in CompanionMood.values) {
      await pumpStage(
        tester,
        mood: mood,
        preferences: const AccessibilityPreferences(reducedMotion: true),
      );
      expect(isMoving(tester), isFalse, reason: '${mood.name} kept moving');
    }
  });

  testWidgets('the picture is still there, just still', (tester) async {
    // Stopping motion must not cost the drawing. Reduced motion is a request
    // for calm, not a request for less companion.
    await pumpStage(
      tester,
      preferences: const AccessibilityPreferences(reducedMotion: true),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(CompanionSlot), findsOneWidget);
  });
}
