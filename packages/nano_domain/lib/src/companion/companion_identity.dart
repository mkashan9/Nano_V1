import 'companion_reaction.dart';

/// CMP-04 humanoid companion identity and voice defaults.
abstract final class CompanionIdentity {
  static const version = 'nano_humanoid_companion_v1';
  static const displayName = 'Nano Learning Guide';
}

abstract final class CompanionVoiceProfile {
  /// Fish Audio narration voice (CMP-04 default).
  static const defaultVoiceId = 'gentle_young_male_c48e8683';

  static const fallbackGeminiApproximation = 'Puck';
}

/// Feature flag keys for companion rollout (see [CompanionFeatureFlags]).
abstract final class CompanionFeatureFlagKeys {
  static const humanoidV1 = 'companion_humanoid_v1';
  static const voiceMaleV1 = 'companion_voice_male_v1';
  static const generatedClips = 'companion_generated_clips';
  static const autoSpeechJunior = 'companion_auto_speech_junior';
  static const autoSpeechSenior = 'companion_auto_speech_senior';
  static const longVideoRefresh = 'companion_long_video_refresh';
}

/// Dev-friendly defaults; production merges overrides from [EnvironmentConfig].
abstract final class CompanionFeatureFlags {
  static const defaults = <String, bool>{
    CompanionFeatureFlagKeys.humanoidV1: true,
    CompanionFeatureFlagKeys.voiceMaleV1: true,
    CompanionFeatureFlagKeys.generatedClips: false,
    CompanionFeatureFlagKeys.autoSpeechJunior: true,
    CompanionFeatureFlagKeys.autoSpeechSenior: false,
    CompanionFeatureFlagKeys.longVideoRefresh: true,
  };

  static bool resolve(String key, {Map<String, bool>? overrides}) =>
      overrides?[key] ?? defaults[key] ?? false;

  static bool get longVideoRefreshEnabled =>
      resolve(CompanionFeatureFlagKeys.longVideoRefresh);
}

/// Maps companion moments to script ids for narration coverage checks.
abstract final class CompanionReactionCatalog {
  static Iterable<String> scriptIdsFor(CompanionEvent event) {
    final mood = CompanionMood.forEvent(event);
    return CompanionScriptBook.core[mood]?.map((s) => s.id) ?? const [];
  }

  static bool moodIsReachable(CompanionMood mood) =>
      (CompanionScriptBook.core[mood]?.isNotEmpty ?? false);
}
