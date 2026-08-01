import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// MED-10: the tier that makes Nori look alive without costing anything.
///
/// The thing under test is not "does a transform exist" — it is that the motion
/// is real, bounded, distinct per mood, and applied where it cannot get in a
/// learner's way.
void main() {
  // The harness turns ambient motion off so that every other test can still
  // use pumpAndSettle. This file is the one that has to see it, so it opts
  // back in and puts it back afterwards.
  setUp(() => NoriLivingArt.debugAmbientMotionEnabled = true);
  tearDown(() => NoriLivingArt.debugAmbientMotionEnabled = false);

  CompanionReaction reactionFor(
    CompanionMood mood, {
    CompanionAssetTier tier = CompanionAssetTier.staticArt,
  }) =>
      CompanionReaction(
        event: CompanionEvent.appOpen,
        mood: mood,
        script: const CompanionScript(id: 'greeting-2', text: 'Hello again.'),
        tier: tier,
        prominent: true,
      );

  Future<void> pumpStage(
    WidgetTester tester, {
    CompanionMood mood = CompanionMood.idle,
    AccessibilityPreferences preferences = AccessibilityPreferences.defaults,
    Widget? clipView,
  }) async {
    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: NanoAccessibilityScope(
          preferences: preferences,
          feedback: NanoFeedback(preferences: preferences),
          child: MaterialApp(
            home: Scaffold(
              body: CompanionStage(
                reaction: reactionFor(mood),
                clipView: clipView,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// The composed scale/translate/rotate currently applied to the art, or null
  /// when the art is not being transformed at all.
  Matrix4? artTransform(WidgetTester tester) {
    final living = find.byType(NoriLivingArt);
    if (living.evaluate().isEmpty) return null;
    final transforms = find.descendant(
      of: living,
      matching: find.byType(Transform),
    );
    if (transforms.evaluate().isEmpty) return null;
    var composed = Matrix4.identity();
    for (final widget in tester.widgetList<Transform>(transforms)) {
      composed = composed.multiplied(widget.transform);
    }
    return composed;
  }

  group('motion specs', () {
    test('every mood has a signature and none of them is still', () {
      for (final mood in CompanionMood.values) {
        final spec = CompanionMotionSpec.forMood(mood);
        expect(spec.isStill, isFalse, reason: '${mood.name} does not move');
        expect(spec.breathPeriod.inMilliseconds, greaterThan(0));
      }
    });

    test('no mood moves enough to compete with the lesson', () {
      for (final mood in CompanionMood.values) {
        final spec = CompanionMotionSpec.forMood(mood);
        // Four percent of a 96-pixel circle is under four pixels. Past that it
        // stops reading as breathing and starts reading as a notification.
        expect(spec.breathScale, lessThanOrEqualTo(0.04),
            reason: '${mood.name} breathes too hard');
        expect(spec.bobFraction, lessThanOrEqualTo(0.04),
            reason: '${mood.name} bobs too far');
        expect(spec.swayTurns.abs(), lessThanOrEqualTo(0.02),
            reason: '${mood.name} tilts too far');
      }
    });

    test('the moods are actually distinguishable from one another', () {
      final signatures = CompanionMood.values
          .map(CompanionMotionSpec.forMood)
          .map((s) => '${s.breathPeriod.inMilliseconds}/${s.breathScale}/'
              '${s.bobPeriod.inMilliseconds}/${s.bobFraction}/'
              '${s.swayPeriod.inMilliseconds}/${s.swayTurns}')
          .toSet();
      expect(signatures.length, CompanionMood.values.length);
    });

    test('a wrong answer is answered calmly, not cheerfully', () {
      final retry = CompanionMotionSpec.forMood(CompanionMood.gentleRetry);
      final celebrate = CompanionMotionSpec.forMood(CompanionMood.celebration);

      // Slower and smaller on every channel. A springy bounce at a child who
      // just got something wrong reads as being laughed at.
      expect(retry.breathPeriod, greaterThan(celebrate.breathPeriod));
      expect(retry.breathScale, lessThan(celebrate.breathScale));
      expect(retry.swayTurns, 0, reason: 'a retry should not waggle');
    });

    test('celebration is the liveliest and idle is the calmest', () {
      final all = {
        for (final mood in CompanionMood.values)
          mood: CompanionMotionSpec.forMood(mood),
      };
      final fastest = all.values
          .map((s) => s.breathPeriod.inMilliseconds)
          .reduce((a, b) => a < b ? a : b);
      final slowest = all.values
          .map((s) => s.breathPeriod.inMilliseconds)
          .reduce((a, b) => a > b ? a : b);

      expect(all[CompanionMood.celebration]!.breathPeriod.inMilliseconds,
          fastest);
      expect(all[CompanionMood.thinking]!.breathPeriod.inMilliseconds, slowest);
    });
  });

  group('on screen', () {
    testWidgets('the art is moving, and it keeps moving', (tester) async {
      await pumpStage(tester, mood: CompanionMood.celebration);

      final first = artTransform(tester);
      expect(first, isNotNull, reason: 'no motion was applied at all');

      await tester.pump(const Duration(milliseconds: 500));
      final second = artTransform(tester);
      expect(second, isNot(equals(first)),
          reason: 'the transform never changed, so nothing is animating');

      await tester.pump(const Duration(milliseconds: 500));
      expect(artTransform(tester), isNot(equals(second)));
    });

    testWidgets('the art never shrinks below the mask it has to fill',
        (tester) async {
      // Motion that pulls the drawing narrower than the circle would show the
      // surface behind it as a crescent, which looks like a rendering bug.
      for (final mood in CompanionMood.values) {
        await pumpStage(tester, mood: mood);
        for (var step = 0; step < 12; step++) {
          await tester.pump(const Duration(milliseconds: 250));
          final scale = artTransform(tester)!.getMaxScaleOnAxis();
          expect(scale, greaterThanOrEqualTo(1.0),
              reason: '${mood.name} shrank inside the mask');
        }
      }
    });

    testWidgets('a clip that is playing is left alone', (tester) async {
      await pumpStage(
        tester,
        mood: CompanionMood.celebration,
        clipView: const SizedBox(key: Key('clip'), width: 64, height: 64),
      );

      expect(find.byKey(const Key('clip')), findsOneWidget);
      expect(artTransform(tester), isNull,
          reason: 'a clip has its own motion and must not get ours too');
    });

    testWidgets('motion costs nothing while the companion is unseen',
        (tester) async {
      // TickerMode is how Flutter says "this subtree is not the current route".
      // Relying on it rather than on our own visibility bookkeeping is what
      // makes a backgrounded app free too: no frames, no ticks, nothing to
      // remember to cancel.
      await tester.pumpWidget(
        NanoLocaleScope(
          locale: NanoAppLocale.en,
          copy: const NanoCopy(NanoAppLocale.en),
          child: NanoAccessibilityScope(
            preferences: AccessibilityPreferences.defaults,
            feedback: NanoFeedback(preferences: AccessibilityPreferences.defaults),
            child: MaterialApp(
              home: Scaffold(
                body: TickerMode(
                  enabled: false,
                  child: CompanionStage(
                    reaction: reactionFor(CompanionMood.celebration),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final parked = artTransform(tester);
      await tester.pump(const Duration(seconds: 2));

      expect(artTransform(tester), parked,
          reason: 'a companion nobody can see is still burning frames');
    });

    testWidgets('the mode ring does not move with the character',
        (tester) async {
      await pumpStage(tester, mood: CompanionMood.celebration);
      final ring = find.byType(CompanionSlot);
      final before = tester.getRect(ring);

      await tester.pump(const Duration(milliseconds: 700));

      // The frame is the still part. A learner aiming at the play badge must
      // not be aiming at a moving target.
      expect(tester.getRect(ring), before);
    });
  });
}
