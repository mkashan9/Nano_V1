import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  final t0 = DateTime.utc(2026, 8, 1, 9);

  group('reaction selection', () {
    test('is deterministic for the same event and seed', () {
      final junior = CompanionRuntime.forExperience(junior: true);
      final a = junior.notify(CompanionEvent.home, now: t0, seed: 3).reaction!;
      final b = junior.notify(CompanionEvent.home, now: t0, seed: 3).reaction!;
      expect(a.script.id, b.script.id);
      expect(a.assetKey, b.assetKey);
    });

    test('a different seed can pick a different line from the same mood', () {
      final junior = CompanionRuntime.forExperience(junior: true);
      final first = junior.notify(CompanionEvent.home, now: t0).reaction!;
      final second =
          junior.notify(CompanionEvent.home, now: t0, seed: 1).reaction!;
      expect(first.mood, CompanionMood.greeting);
      expect(second.mood, CompanionMood.greeting);
      expect(first.script.id, isNot(second.script.id));
    });

    test('every event resolves to a mood with a caption', () {
      final junior = CompanionRuntime.forExperience(junior: true);
      for (final event in CompanionEvent.values) {
        final reaction = junior.notify(event, now: t0).reaction;
        expect(reaction, isNotNull, reason: '$event produced nothing');
        expect(reaction!.captionFor(NanoAppLocale.en), isNotEmpty);
      }
    });

    test('captions use the chosen companion name and Urdu when asked', () {
      final reaction = CompanionRuntime.forExperience(
        junior: true,
        companionName: 'Bao',
      ).notify(CompanionEvent.appOpen, now: t0).reaction!;
      expect(reaction.captionFor(NanoAppLocale.en), contains('Bao'));
      expect(
        reaction.captionFor(NanoAppLocale.ur, companionName: 'Bao'),
        contains('Bao'),
      );
      expect(
        reaction.captionFor(NanoAppLocale.ur),
        isNot(reaction.captionFor(NanoAppLocale.en)),
      );
    });
  });

  group('outcome events', () {
    test('come from a server-authored pass flag', () {
      expect(
        CompanionEvent.forOutcome(passed: true),
        CompanionEvent.resultPassed,
      );
      expect(
        CompanionEvent.forOutcome(passed: false),
        CompanionEvent.resultNeedsReview,
      );
    });

    test('celebrate a pass and gently offer another try otherwise', () {
      final junior = CompanionRuntime.forExperience(junior: true);
      expect(
        junior.notify(CompanionEvent.resultPassed, now: t0).reaction!.mood,
        CompanionMood.celebration,
      );
      expect(
        junior.notify(CompanionEvent.resultNeedsReview, now: t0).reaction!.mood,
        CompanionMood.gentleRetry,
      );
    });
  });

  group('cooldowns', () {
    test('suppress a repeated ordinary moment until the window passes', () {
      final shown = CompanionRuntime.forExperience(junior: true)
          .notify(CompanionEvent.home, now: t0);
      final tooSoon = shown.notify(
        CompanionEvent.home,
        now: t0.add(const Duration(seconds: 2)),
        seed: 1,
      );
      expect(tooSoon.reaction!.script.id, shown.reaction!.script.id);

      final later = shown.notify(
        CompanionEvent.home,
        now: t0.add(const Duration(seconds: 30)),
        seed: 1,
      );
      expect(later.reaction!.script.id, isNot(shown.reaction!.script.id));
    });

    test('never block essential outcomes', () {
      final first = CompanionRuntime.forExperience(junior: true)
          .notify(CompanionEvent.resultPassed, now: t0);
      expect(
        first.isSuppressed(
          CompanionEvent.resultPassed,
          t0.add(const Duration(milliseconds: 1)),
        ),
        isFalse,
      );
    });

    test('survive a dismiss', () {
      final dismissed = CompanionRuntime.forExperience(junior: true)
          .notify(CompanionEvent.home, now: t0)
          .dismiss();
      expect(dismissed.isVisible, isFalse);
      expect(
        dismissed.isSuppressed(
          CompanionEvent.home,
          t0.add(const Duration(seconds: 1)),
        ),
        isTrue,
      );
    });
  });

  group('experience density', () {
    test('junior guidance is prominent and frequent', () {
      final junior = CompanionRuntime.forExperience(junior: true);
      expect(junior.policy.cooldown, const Duration(seconds: 8));
      expect(
        junior.notify(CompanionEvent.quizQuestion, now: t0).reaction!.prominent,
        isTrue,
      );
    });

    test('senior stays quiet about ordinary navigation', () {
      final senior = CompanionRuntime.forExperience(junior: false);
      expect(senior.notify(CompanionEvent.home, now: t0).reaction, isNull);
      expect(
        senior.notify(CompanionEvent.quizQuestion, now: t0).reaction,
        isNull,
      );
      final result = senior.notify(CompanionEvent.resultPassed, now: t0);
      expect(result.reaction, isNotNull);
      expect(result.reaction!.prominent, isFalse);
    });
  });

  group('accessibility and availability', () {
    test('muted sound keeps the caption and drops the voice', () {
      final reaction = CompanionRuntime.forExperience(
        junior: true,
        preferences:
            const AccessibilityPreferences(soundEnabled: false),
      ).notify(CompanionEvent.appOpen, now: t0).reaction!;
      expect(reaction.speaks, isFalse);
      expect(reaction.showsCaption, isTrue);
    });

    test('classroom mode silences the voice even with sound on', () {
      final runtime = CompanionRuntime.forExperience(
        junior: true,
        preferences: const AccessibilityPreferences(classroomMode: true),
      ).notify(CompanionEvent.appOpen, now: t0);
      expect(runtime.speaks, isFalse);
      expect(runtime.reaction!.tier, CompanionAssetTier.staticArt);
    });

    test('captions can be turned off without hiding the companion', () {
      final reaction = CompanionRuntime.forExperience(
        junior: true,
        preferences: const AccessibilityPreferences(captionsEnabled: false),
      ).notify(CompanionEvent.appOpen, now: t0).reaction!;
      expect(reaction.showsCaption, isFalse);
      expect(reaction.mood, CompanionMood.greeting);
    });

    test('reduced motion forces static art', () {
      final reaction = CompanionRuntime.forExperience(
        junior: true,
        preferences: const AccessibilityPreferences(reducedMotion: true),
      ).notify(CompanionEvent.resultPassed, now: t0).reaction!;
      expect(reaction.tier, CompanionAssetTier.staticArt);
    });

    test('a clip mood falls back to a local tier when clips are unavailable',
        () {
      final offline = CompanionRuntime.forExperience(junior: true)
          .notify(CompanionEvent.resultPassed, now: t0)
          .reaction!;
      expect(offline.tier.isLocal, isTrue);

      final enriched = CompanionRuntime.forExperience(
        junior: true,
        clipsAvailable: true,
      ).notify(CompanionEvent.resultPassed, now: t0).reaction!;
      expect(enriched.tier, CompanionAssetTier.shortClip);
    });

    test('an empty manifest still resolves to something showable', () {
      final reaction = CompanionRuntime.forExperience(
        junior: true,
        manifest: const CompanionAssetManifest(tiers: {}),
      ).notify(CompanionEvent.home, now: t0).reaction!;
      expect(reaction.tier, CompanionAssetTier.staticArt);
    });
  });

  test('preferences can change without losing cooldown history', () {
    final runtime = CompanionRuntime.forExperience(junior: true)
        .notify(CompanionEvent.home, now: t0)
        .withPreferences(
          const AccessibilityPreferences(soundEnabled: false),
        );
    expect(runtime.preferences.soundEnabled, isFalse);
    expect(
      runtime.isSuppressed(CompanionEvent.home, t0.add(const Duration(seconds: 1))),
      isTrue,
    );
  });
}
