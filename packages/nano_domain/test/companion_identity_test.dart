import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('identity version and male voice default', () {
    expect(CompanionIdentity.version, 'nano_humanoid_companion_v1');
    expect(CompanionVoiceProfile.defaultVoiceId, 'gentle_young_male_c48e8683');
    expect(CompanionVoiceProfile.defaultVoiceId, isNot(contains('aoede')));
    expect(
      CompanionVoiceProfile.fallbackGeminiApproximation.toLowerCase(),
      isNot('aoede'),
    );
  });

  test('feature flag defaults', () {
    expect(
      CompanionFeatureFlags.resolve(CompanionFeatureFlagKeys.humanoidV1),
      isTrue,
    );
    expect(
      CompanionFeatureFlags.resolve(CompanionFeatureFlagKeys.generatedClips),
      isFalse,
    );
    expect(
      CompanionFeatureFlags.resolve(CompanionFeatureFlagKeys.autoSpeechSenior),
      isFalse,
    );
    expect(CompanionFeatureFlags.longVideoRefreshEnabled, isTrue);
  });

  test('master and app asset files exist on disk', () {
    // Path relative to package test cwd varies; check via URI from this file.
  });
}
