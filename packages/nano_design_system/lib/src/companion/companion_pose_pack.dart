import 'package:nano_domain/nano_domain.dart';

/// Bundled humanoid companion poses (CMP-04).
///
/// Same contract as the legacy Nori pack: one drawing per [CompanionMood], keyed
/// by mood rather than mode slot so all modes share one identity.
abstract final class CompanionPosePack {
  static const package = 'nano_design_system';

  static const identityVersion = 'nano_humanoid_companion_v1';

  static const portraitAsset = 'assets/companion/companion_portrait.webp';

  static const _moodFile = <CompanionMood, String>{
    CompanionMood.greeting: 'greeting',
    CompanionMood.idle: 'idle',
    CompanionMood.point: 'point',
    CompanionMood.thinking: 'thinking',
    CompanionMood.gentleRetry: 'gentle_retry',
    CompanionMood.celebration: 'celebration',
  };

  static String assetFor(CompanionMood mood) =>
      'assets/companion/companion_${_moodFile[mood]!}.webp';

  static Iterable<String> get all => CompanionMood.values.map(assetFor);
}
