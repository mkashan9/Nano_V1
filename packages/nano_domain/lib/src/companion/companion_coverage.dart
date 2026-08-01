import 'companion_mode.dart';
import 'companion_placement.dart';
import 'companion_reaction.dart';
import 'companion_runtime.dart';

/// MED-12: the reachable companion matrix, derived rather than listed.
///
/// Coverage is the kind of property that is true the day it ships and quietly
/// false six modules later, when a surface or an event is added and nobody
/// notices the companion has nowhere to stand, or nothing to wear. Every
/// consumer of this type rebuilds the set from the enums, so adding a value is
/// enough to make a coverage test fail.
abstract final class CompanionCoverage {
  /// Surfaces the placement policy says should show Nori for at least one
  /// experience. Social and settings are excluded because they are hidden on
  /// purpose; game is included in the policy but deferred to GME-01 for the
  /// actual mount, so callers that care about *product* mounts filter it out.
  static Set<CompanionSurface> get visibleSurfaces => {
        for (final surface in CompanionSurface.values)
          if (CompanionPlacementPolicy.resolve(
                    surface: surface,
                    junior: true,
                  )
                  .isVisible ||
              CompanionPlacementPolicy.resolve(
                    surface: surface,
                    junior: false,
                  )
                  .isVisible)
            surface,
      };

  /// Surfaces MED-12 expects to be mounted in the student app today.
  ///
  /// Game is deliberately absent: the owner lock on MED-12 defers it to
  /// GME-01. Adding game here without a mount would make the surface coverage
  /// test fail for a reason nobody can fix in this module.
  static const productSurfaces = <CompanionSurface>{
    CompanionSurface.onboarding,
    CompanionSurface.home,
    CompanionSurface.learning,
    CompanionSurface.quiz,
    CompanionSurface.progress,
  };

  /// Every (mode, mood) a learner can actually cause by firing an event on a
  /// visible surface. Quiet Senior events still count: the reaction may be
  /// suppressed, but the pair remains reachable the moment the quiet list
  /// changes.
  static Set<({CompanionMode mode, CompanionMood mood})> reachablePairs() {
    final pairs = <({CompanionMode mode, CompanionMood mood})>{};
    for (final surface in visibleSurfaces) {
      for (final event in CompanionEvent.values) {
        final mode = CompanionMode.resolve(surface: surface, event: event);
        final mood = CompanionMood.forEvent(event);
        pairs.add((mode: mode, mood: mood));
      }
    }
    return pairs;
  }

  /// Slot keys a reaction must be able to resolve art for, at its floor tier
  /// and one rung below when the floor is a clip.
  ///
  /// A shortClip without a published video must still fall to localAnimation
  /// (and from there to staticArt under reduced motion). Listing both keeps
  /// the coverage gate from declaring a celebration "covered" when only the
  /// clip slot exists and the offline floor is empty.
  static Set<String> expectedSlotsFor(
    CompanionMode mode,
    CompanionMood mood, {
    CompanionAssetManifest manifest = CompanionAssetManifest.defaults,
  }) {
    final floor = manifest.resolve(mood);
    final slots = <String>{
      CompanionReaction.slotKey(mode: mode, mood: mood, tier: floor),
    };
    if (floor == CompanionAssetTier.shortClip) {
      slots.add(
        CompanionReaction.slotKey(
          mode: mode,
          mood: mood,
          tier: CompanionAssetTier.localAnimation,
        ),
      );
      slots.add(
        CompanionReaction.slotKey(
          mode: mode,
          mood: mood,
          tier: CompanionAssetTier.staticArt,
        ),
      );
    } else if (floor == CompanionAssetTier.localAnimation) {
      slots.add(
        CompanionReaction.slotKey(
          mode: mode,
          mood: mood,
          tier: CompanionAssetTier.staticArt,
        ),
      );
    }
    return slots;
  }

  /// Every slot the offline floor and the clip ladder must be able to serve.
  static Set<String> get expectedSlots {
    final slots = <String>{};
    for (final pair in reachablePairs()) {
      slots.addAll(expectedSlotsFor(pair.mode, pair.mood));
    }
    return slots;
  }

  /// Slots the Moderation coverage report cares about: curated published art
  /// and celebration clips. Bundled poses cover the offline floor; this is
  /// the gap a curator can close by approving something.
  static Set<String> get curatedSlots {
    final slots = <String>{};
    for (final pair in reachablePairs()) {
      // Published still art is optional per mode — the bundled pose is the
      // floor — but celebration clips are the one tier the manifest promotes
      // and that learners actually notice missing.
      if (pair.mood == CompanionMood.celebration) {
        slots.add(
          CompanionReaction.slotKey(
            mode: pair.mode,
            mood: pair.mood,
            tier: CompanionAssetTier.shortClip,
          ),
        );
      }
    }
    return slots;
  }

  /// Which curated slots have no approved asset yet.
  static List<String> missingCuratedSlots(Set<String> approvedSlots) {
    final missing = curatedSlots
        .where((slot) => !approvedSlots.contains(slot))
        .toList()
      ..sort();
    return missing;
  }

  /// Prove a reaction can resolve without throwing, with and without a clip,
  /// and under reduced motion. Returns the resolved asset keys so a caller can
  /// assert an offline pose exists for each mood.
  static Set<String> resolveKeys({
    required CompanionMode mode,
    required CompanionMood mood,
    CompanionAssetManifest manifest = CompanionAssetManifest.defaults,
  }) {
    final keys = <String>{};
    for (final reduced in const [false, true]) {
      for (final clip in const [false, true]) {
        final tier = manifest.resolve(
          mood,
          reducedMotion: reduced,
          clipAvailable: clip,
        );
        keys.add(
          CompanionReaction.slotKey(mode: mode, mood: mood, tier: tier),
        );
      }
    }
    return keys;
  }
}
