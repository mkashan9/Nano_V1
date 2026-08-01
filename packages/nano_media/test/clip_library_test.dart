import 'package:nano_domain/nano_domain.dart';
import 'package:nano_media/nano_media.dart';
import 'package:test/test.dart';

GeneratedAsset _video(String slot) => GeneratedAsset(
      id: slot,
      kind: GeneratedAssetKind.video,
      slot: slot,
      locale: 'en',
      aspectRatio: '1:1',
      moderation: GeneratedAssetModeration.approved,
      storageBucket: 'generated-assets',
      storagePath: '$slot.mp4',
      contentType: 'video/mp4',
      checksum: 'sha256:$slot',
    );

GeneratedAsset _image(String slot) => GeneratedAsset(
      id: slot,
      kind: GeneratedAssetKind.image,
      slot: slot,
      locale: 'en',
      aspectRatio: '1:1',
      moderation: GeneratedAssetModeration.approved,
      storageBucket: 'generated-assets',
      storagePath: '$slot.png',
      contentType: 'image/png',
      checksum: 'sha256:$slot',
    );

const _celebration = CompanionReaction(
  event: CompanionEvent.levelUp,
  mood: CompanionMood.celebration,
  script: CompanionScript(id: 'celebration-1', text: 'Nicely done!'),
  tier: CompanionAssetTier.shortClip,
  mode: CompanionMode.celebration,
);

const _greeting = CompanionReaction(
  event: CompanionEvent.appOpen,
  mood: CompanionMood.greeting,
  script: CompanionScript(id: 'greeting-2', text: 'Good to see you again.'),
  tier: CompanionAssetTier.shortClip,
  mode: CompanionMode.guide,
);

void main() {
  group('clipSlots', () {
    test('lists only video slots', () {
      final catalog = CompanionAssetCatalog.fromAssets([
        _video('celebration_celebration_shortClip'),
        _image('guide_greeting_staticArt'),
        _video('quizCoach_celebration_shortClip'),
      ]);

      expect(
        catalog.clipSlots,
        {
          'celebration_celebration_shortClip',
          'quizCoach_celebration_shortClip',
        },
      );
      expect(catalog.hasClips, isTrue);
    });

    test('is empty when nothing published is a clip', () {
      final catalog = CompanionAssetCatalog.fromAssets([
        _image('guide_greeting_staticArt'),
      ]);

      expect(catalog.clipSlots, isEmpty);
      expect(catalog.hasClips, isFalse);
    });
  });

  group('per-slot choose', () {
    test('a matching slot uses the clip', () {
      final catalog = CompanionAssetCatalog.fromAssets([
        _video(_celebration.assetKey),
      ]);

      final choice = catalog.choose(_celebration);

      expect(choice.tier, CompanionAssetTier.shortClip);
      expect(choice.usesGeneratedClip, isTrue);
      expect(choice.generated?.slot, _celebration.assetKey);
    });

    test('a missing slot falls back to local art', () {
      final catalog = CompanionAssetCatalog.fromAssets([
        _video(_celebration.assetKey),
      ]);

      final choice = catalog.choose(_greeting);

      expect(choice.tier, CompanionAssetTier.localAnimation);
      expect(choice.usesGeneratedClip, isFalse);
      expect(choice.fallback, CompanionArtFallback.notGenerated);
    });
  });
}
