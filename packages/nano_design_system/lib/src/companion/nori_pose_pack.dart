import 'package:nano_domain/nano_domain.dart';

/// The art that ships with the app (MED-09).
///
/// One drawing per mood, bundled rather than fetched, because static art is the
/// floor under the whole companion system: reduced motion collapses every tier
/// down to it, and a device with no network has nothing else. Before this
/// existed the floor was a Material icon in a circle, which is a placeholder
/// pretending to be a character.
///
/// Keyed by mood and not by slot on purpose. A slot is `mode_mood_tier`, and
/// there are 25 reachable mode and mood pairs, but CMP-02 defines a mode as the
/// same character wearing a different accent and framing — never a different
/// character. The stage already draws the mode ring and the mode emblem around
/// the art, so one drawing per mood renders all 25 pairs correctly and no two
/// modes can drift apart, because they are literally the same file.
///
/// Published art still wins. A curator who wants Quiz Coach Nori drawn
/// differently from Explorer Nori approves art for that exact slot and the
/// catalog prefers it; this is the floor, not the ceiling.
abstract final class NoriPosePack {
  /// The package these assets live in, needed because they are bundled with the
  /// design system rather than with any one app.
  static const package = 'nano_design_system';

  static const _byMood = <CompanionMood, String>{
    CompanionMood.greeting: 'nori_greeting.jpg',
    CompanionMood.idle: 'nori_idle.jpg',
    CompanionMood.point: 'nori_point.jpg',
    CompanionMood.thinking: 'nori_thinking.jpg',
    CompanionMood.gentleRetry: 'nori_gentle_retry.jpg',
    CompanionMood.celebration: 'nori_celebration.jpg',
  };

  /// The bundled drawing for [mood].
  ///
  /// Never null: every mood in the enum has a pose, and a test enforces it, so
  /// a caller does not need a branch for art that might not be there.
  static String assetFor(CompanionMood mood) =>
      'assets/companion/${_byMood[mood]!}';

  /// Every bundled path, for the coverage test and for precaching.
  static Iterable<String> get all => CompanionMood.values.map(assetFor);
}
