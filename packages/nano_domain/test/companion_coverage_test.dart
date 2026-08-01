import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

/// MED-12: every reachable reaction can resolve art at its tier or below.
void main() {
  test('every product surface is visible in the placement policy', () {
    for (final surface in CompanionCoverage.productSurfaces) {
      expect(
        CompanionPlacementPolicy.resolve(surface: surface, junior: true)
            .isVisible,
        isTrue,
        reason: '${surface.name} is a product mount but hidden for Junior',
      );
    }
  });

  test('game stays visible in policy even though the mount waits on GME-01',
      () {
    expect(
      CompanionPlacementPolicy.resolve(
        surface: CompanionSurface.game,
        junior: true,
      ).isVisible,
      isTrue,
    );
    expect(
      CompanionCoverage.productSurfaces.contains(CompanionSurface.game),
      isFalse,
      reason: 'productSurfaces must not demand a mount nobody can build yet',
    );
  });

  test('social and settings stay hidden', () {
    for (final surface in const [
      CompanionSurface.social,
      CompanionSurface.settings,
    ]) {
      expect(
        CompanionPlacementPolicy.resolve(surface: surface, junior: true),
        CompanionPlacement.hidden,
      );
      expect(
        CompanionCoverage.visibleSurfaces.contains(surface),
        isFalse,
      );
    }
  });

  test('every reachable pair resolves a tier with and without a clip', () {
    for (final pair in CompanionCoverage.reachablePairs()) {
      final keys = CompanionCoverage.resolveKeys(
        mode: pair.mode,
        mood: pair.mood,
      );
      expect(keys, isNotEmpty);
      // Reduced motion must never leave the reaction on a motion tier.
      final reduced = CompanionAssetManifest.defaults.resolve(
        pair.mood,
        reducedMotion: true,
        clipAvailable: true,
      );
      expect(reduced, CompanionAssetTier.staticArt);
    }
  });

  test('every reachable mood has a script that can be shown as a caption', () {
    final moods =
        CompanionCoverage.reachablePairs().map((pair) => pair.mood).toSet();
    for (final mood in moods) {
      final lines = CompanionScriptBook.core[mood] ?? const <CompanionScript>[];
      expect(lines, isNotEmpty, reason: '${mood.name} has nothing to say');
    }
  });

  test('a celebration without a clip falls to local animation, not silence',
      () {
    final tier = CompanionAssetManifest.defaults.resolve(
      CompanionMood.celebration,
      clipAvailable: false,
    );
    expect(tier, CompanionAssetTier.localAnimation);
  });

  test('curated slots are exactly the celebration clip set', () {
    // Derived from the reachable matrix, not listed. Adding a mode that can
    // celebrate is enough to grow this set and fail the Moderation report
    // until a clip is approved.
    expect(
      CompanionCoverage.curatedSlots,
      {
        'guide_celebration_shortClip',
        'explorer_celebration_shortClip',
        'quizCoach_celebration_shortClip',
        'builder_celebration_shortClip',
        'celebration_celebration_shortClip',
      },
    );
  });

  test('missing curated slots are the ones with no approved asset', () {
    expect(
      CompanionCoverage.missingCuratedSlots({
        'guide_celebration_shortClip',
        'celebration_celebration_shortClip',
      }),
      [
        'builder_celebration_shortClip',
        'explorer_celebration_shortClip',
        'quizCoach_celebration_shortClip',
      ],
    );
    expect(
      CompanionCoverage.missingCuratedSlots(CompanionCoverage.curatedSlots),
      isEmpty,
    );
  });

  test('runtime notify never throws for a reachable event on a visible surface',
      () {
    final now = DateTime.utc(2026, 8, 2);
    for (final surface in CompanionCoverage.visibleSurfaces) {
      for (final event in CompanionEvent.values) {
        final runtime = CompanionRuntime.forExperience(
          junior: true,
          surface: surface,
        );
        // A fresh runtime has no cooldown debt. notify may still suppress for
        // quiet Senior lists, but it must not throw.
        expect(
          () => runtime.notify(event, now: now),
          returnsNormally,
          reason: '${surface.name} × ${event.name}',
        );
      }
    }
  });
}
