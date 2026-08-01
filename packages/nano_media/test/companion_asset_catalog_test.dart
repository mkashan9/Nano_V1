import 'package:nano_domain/nano_domain.dart';
import 'package:nano_media/nano_media.dart';
import 'package:test/test.dart';

GeneratedAsset _asset({
  required String slot,
  String locale = 'en',
  GeneratedAssetKind kind = GeneratedAssetKind.video,
  GeneratedAssetModeration moderation = GeneratedAssetModeration.approved,
  GeneratedAssetStatus status = GeneratedAssetStatus.ready,
  String? path = 'file.mp4',
}) {
  return GeneratedAsset(
    id: '$slot-$locale',
    kind: kind,
    slot: slot,
    locale: locale,
    aspectRatio: '1:1',
    status: status,
    moderation: moderation,
    storageBucket: 'generated-assets',
    storagePath: path,
    checksum: 'sha256:abc',
  );
}

const _clipReaction = CompanionReaction(
  event: CompanionEvent.levelUp,
  mood: CompanionMood.celebration,
  script: CompanionScript(id: 'celebration-1', text: 'Nicely done!'),
  tier: CompanionAssetTier.shortClip,
  mode: CompanionMode.celebration,
);

const _staticReaction = CompanionReaction(
  event: CompanionEvent.home,
  mood: CompanionMood.point,
  script: CompanionScript(id: 'point-1', text: 'Start here.'),
  tier: CompanionAssetTier.staticArt,
);

void main() {
  group('CompanionAssetCatalog', () {
    test('only published files enter the catalog', () {
      final catalog = CompanionAssetCatalog.fromAssets([
        _asset(slot: 'a'),
        _asset(slot: 'b', moderation: GeneratedAssetModeration.unreviewed),
        _asset(slot: 'c', status: GeneratedAssetStatus.failed),
        _asset(slot: 'd', path: null),
      ]);

      expect(catalog.length, 1);
      expect(catalog.lookup(slot: 'a'), isNotNull);
      expect(catalog.lookup(slot: 'b'), isNull);
      expect(catalog.lookup(slot: 'c'), isNull);
      expect(catalog.lookup(slot: 'd'), isNull);
    });

    test('a missing language falls back to English rather than to nothing', () {
      final catalog = CompanionAssetCatalog.fromAssets([
        _asset(slot: 'a', locale: 'en'),
        _asset(slot: 'b', locale: 'ur'),
      ]);

      expect(catalog.lookup(slot: 'a', locale: NanoAppLocale.ur)?.locale, 'en');
      expect(catalog.lookup(slot: 'b', locale: NanoAppLocale.ur)?.locale, 'ur');
      expect(catalog.lookup(slot: 'b', locale: NanoAppLocale.en), isNull);
    });

    test('hasClips is what tells the runtime it may promise a clip', () {
      expect(CompanionAssetCatalog.empty.hasClips, isFalse);
      expect(
        CompanionAssetCatalog.fromAssets([
          _asset(slot: 'a', kind: GeneratedAssetKind.image),
        ]).hasClips,
        isFalse,
      );
      expect(
        CompanionAssetCatalog.fromAssets([_asset(slot: 'a')]).hasClips,
        isTrue,
      );
    });
  });

  group('choosing art', () {
    test('a clip is used when a published clip exists for the slot', () {
      final catalog = CompanionAssetCatalog.fromAssets([
        _asset(slot: _clipReaction.assetKey),
      ]);

      final choice = catalog.choose(_clipReaction);

      expect(choice.tier, CompanionAssetTier.shortClip);
      expect(choice.usesGeneratedClip, isTrue);
      expect(choice.generated?.slot, _clipReaction.assetKey);
    });

    test('a missing clip drops one rung instead of leaving an empty stage', () {
      final choice = CompanionAssetCatalog.empty.choose(_clipReaction);

      expect(choice.tier, CompanionAssetTier.localAnimation);
      expect(choice.usesGeneratedClip, isFalse);
    });

    test('a clip published for another slot is not borrowed', () {
      final catalog = CompanionAssetCatalog.fromAssets([
        _asset(slot: 'guide_celebration_shortClip'),
      ]);

      expect(
        catalog.choose(_clipReaction).usesGeneratedClip,
        isFalse,
      );
    });

    test('an image published against a clip slot is not played as a clip', () {
      final catalog = CompanionAssetCatalog.fromAssets([
        _asset(slot: _clipReaction.assetKey, kind: GeneratedAssetKind.image),
      ]);

      final choice = catalog.choose(_clipReaction);

      expect(choice.tier, CompanionAssetTier.localAnimation);
      expect(choice.usesGeneratedClip, isFalse);
    });

    test('reduced motion never gets a clip, even when one exists', () {
      final catalog = CompanionAssetCatalog.fromAssets([
        _asset(slot: _clipReaction.assetKey),
      ]);

      final choice = catalog.choose(_clipReaction, reducedMotion: true);

      expect(choice.tier, CompanionAssetTier.staticArt);
      expect(choice.usesGeneratedClip, isFalse);
    });

    test('a local tier is left alone, published clips or not', () {
      final catalog = CompanionAssetCatalog.fromAssets([
        _asset(slot: _staticReaction.assetKey),
      ]);

      final choice = catalog.choose(_staticReaction);

      expect(choice.tier, CompanionAssetTier.staticArt);
      expect(choice.usesGeneratedClip, isFalse);
    });
  });
}
