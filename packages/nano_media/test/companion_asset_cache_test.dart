import 'package:nano_domain/nano_domain.dart';
import 'package:nano_media/nano_media.dart';
import 'package:test/test.dart';

GeneratedAsset _asset({
  required String slot,
  GeneratedAssetKind kind = GeneratedAssetKind.video,
  String id = 'a1',
  String checksum = 'sha256:one',
  String locale = 'en',
}) {
  return GeneratedAsset(
    id: id,
    kind: kind,
    slot: slot,
    locale: locale,
    aspectRatio: '1:1',
    moderation: GeneratedAssetModeration.approved,
    storageBucket: 'generated-assets',
    storagePath: '${kind.name}/$slot/$locale/$checksum',
    contentType: kind == GeneratedAssetKind.video ? 'video/mp4' : 'image/png',
    byteSize: 4096,
    checksum: checksum,
  );
}

void main() {
  group('CompanionAssetCache', () {
    test('asks once, then serves the cached catalog until it goes stale', () async {
      var now = DateTime.utc(2026, 8, 1, 9);
      final cache = CompanionAssetCache(
        fetch: () async => [_asset(slot: 'celebration_celebration_shortClip')],
        clock: () => now,
        ttl: const Duration(hours: 6),
      );

      expect((await cache.load()).length, 1);
      expect(cache.fetchCount, 1);

      now = now.add(const Duration(hours: 5, minutes: 59));
      await cache.load();
      expect(cache.fetchCount, 1, reason: 'a fresh catalog must not be refetched');

      now = now.add(const Duration(minutes: 2));
      await cache.load();
      expect(cache.fetchCount, 2);
    });

    test('several screens waking together cost one fetch', () async {
      final cache = CompanionAssetCache(
        fetch: () async {
          await Future<void>.delayed(const Duration(milliseconds: 5));
          return [_asset(slot: 'celebration_celebration_shortClip')];
        },
      );

      await Future.wait([cache.load(), cache.load(), cache.load()]);
      expect(cache.fetchCount, 1);
    });

    test('a failed refresh keeps the last known catalog and never throws', () async {
      var now = DateTime.utc(2026, 8, 1, 9);
      var fail = false;
      final cache = CompanionAssetCache(
        fetch: () async {
          if (fail) throw StateError('offline');
          return [_asset(slot: 'celebration_celebration_shortClip')];
        },
        clock: () => now,
        ttl: const Duration(minutes: 10),
      );

      await cache.load();
      fail = true;
      now = now.add(const Duration(hours: 1));

      final catalog = await cache.load();
      expect(catalog.length, 1, reason: 'the last good answer is still the answer');
      expect(cache.clipsAvailable, isTrue);
      expect(cache.lastError, isA<StateError>());
    });

    test('a first run with no network is an empty catalog, not an error', () async {
      final cache = CompanionAssetCache(fetch: () async => throw StateError('offline'));

      final catalog = await cache.load();
      expect(catalog.length, 0);
      expect(cache.clipsAvailable, isFalse);
      expect(cache.isLoaded, isTrue, reason: 'a failure still counts as answered');
    });

    test('signs a URL once and reuses it until it is nearly expired', () async {
      var now = DateTime.utc(2026, 8, 1, 9);
      var signCount = 0;
      final asset = _asset(slot: 'celebration_celebration_shortClip');
      final cache = CompanionAssetCache(
        fetch: () async => [asset],
        sign: (asset, expiresIn) async {
          signCount++;
          return 'https://cdn.local/${asset.storagePath}?n=$signCount';
        },
        clock: () => now,
        signedUrlLifetime: const Duration(minutes: 30),
        signedUrlSafetyMargin: const Duration(minutes: 2),
      );

      await cache.load();
      final first = await cache.urlFor(asset);
      expect(first, contains('n=1'));

      now = now.add(const Duration(minutes: 20));
      expect(await cache.urlFor(asset), first);
      expect(signCount, 1);

      // Past the margin: a player given this URL would otherwise be handed one
      // that expires while it is buffering.
      now = now.add(const Duration(minutes: 9));
      expect(await cache.urlFor(asset), contains('n=2'));
    });

    test('a regenerated file is signed again rather than served from cache', () async {
      var assets = [_asset(slot: 'clip_slot', checksum: 'sha256:one')];
      var now = DateTime.utc(2026, 8, 1, 9);
      final cache = CompanionAssetCache(
        fetch: () async => assets,
        sign: (asset, _) async => 'https://cdn.local/${asset.checksum}',
        clock: () => now,
        ttl: const Duration(minutes: 1),
      );

      await cache.load();
      expect(await cache.urlFor(assets.first), endsWith('sha256:one'));
      expect(cache.signedUrlCount, 1);

      assets = [_asset(slot: 'clip_slot', checksum: 'sha256:two')];
      now = now.add(const Duration(minutes: 2));
      await cache.load();

      expect(cache.signedUrlCount, 0, reason: 'the old file is no longer published');
      expect(await cache.urlFor(assets.first), endsWith('sha256:two'));
    });

    test('an unsignable asset gives null, which is a fallback and not a failure',
        () async {
      final cache = CompanionAssetCache(
        fetch: () async => [_asset(slot: 'clip_slot')],
        sign: (asset, expiresIn) async => throw StateError('signing unavailable'),
      );
      await cache.load();

      expect(await cache.urlFor(_asset(slot: 'clip_slot')), isNull);
    });

    test('clearing forgets the catalog and the signed URLs', () async {
      final asset = _asset(slot: 'clip_slot');
      final cache = CompanionAssetCache(
        fetch: () async => [asset],
        sign: (asset, _) async => 'https://cdn.local/${asset.id}',
      );
      await cache.load();
      await cache.urlFor(asset);

      cache.clear();

      expect(cache.current.length, 0);
      expect(cache.signedUrlCount, 0);
      expect(cache.isLoaded, isFalse);
    });
  });

  group('fallback reporting', () {
    test('names why a clip was not used', () {
      final catalog = CompanionAssetCatalog.fromAssets([
        _asset(
          slot: 'celebration_celebration_shortClip',
          kind: GeneratedAssetKind.image,
        ),
      ]);
      const reaction = CompanionReaction(
        event: CompanionEvent.levelUp,
        mood: CompanionMood.celebration,
        script: CompanionScript(id: 'celebration-1', text: 'Nicely done!'),
        tier: CompanionAssetTier.shortClip,
        mode: CompanionMode.celebration,
      );

      expect(
        catalog.choose(reaction).fallback,
        CompanionArtFallback.wrongKind,
        reason: 'something is published for the slot, but it is not a clip',
      );
      expect(
        CompanionAssetCatalog.empty.choose(reaction).fallback,
        CompanionArtFallback.notGenerated,
      );
      expect(
        catalog.choose(reaction, reducedMotion: true).fallback,
        CompanionArtFallback.reducedMotion,
      );
    });
  });
}
