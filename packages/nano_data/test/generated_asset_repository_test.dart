import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('FakeGeneratedAssetRepository', () {
    test('the published list hides anything unapproved or unfinished', () async {
      final repository = FakeGeneratedAssetRepository();

      final published = await repository.listPublished();
      final all = await repository.listForReview();

      expect(published.every((asset) => asset.isPlayable), isTrue);
      expect(all.length, greaterThanOrEqualTo(published.length));
    });

    test('filters narrow by kind and language', () async {
      final repository = FakeGeneratedAssetRepository();

      final clips = await repository.listPublished(
        kind: GeneratedAssetKind.video,
      );
      final urdu = await repository.listPublished(locale: NanoAppLocale.ur);

      expect(clips.map((asset) => asset.kind), everyElement(GeneratedAssetKind.video));
      expect(urdu, isEmpty);
    });

    test('an identical ask reuses the existing asset', () async {
      final repository = FakeGeneratedAssetRepository();
      const request = GeneratedAssetRequest(
        kind: GeneratedAssetKind.image,
        slot: 'guide_greeting_staticArt',
        prompt: 'a friendly companion',
        promptVersion: 'v1',
      );

      final first = await repository.request(request);

      expect(first.reused, isTrue);
      expect(first.asset.id, '90000000-0000-0000-0000-000000000001');
    });

    test('a new slot creates a ready asset that is not yet published', () async {
      final repository = FakeGeneratedAssetRepository();

      final outcome = await repository.request(
        const GeneratedAssetRequest(
          kind: GeneratedAssetKind.image,
          slot: 'explorer_point_staticArt',
          prompt: 'a companion pointing at a map',
          promptVersion: 'v1',
        ),
      );

      expect(outcome.reused, isFalse);
      expect(outcome.asset.status, GeneratedAssetStatus.ready);
      expect(outcome.asset.moderation, GeneratedAssetModeration.unreviewed);
      expect(outcome.asset.isPlayable, isFalse);
      expect(outcome.asset.providerId, 'pollinations_image');
      expect(repository.requestCount, 1);
    });

    test('an unconfigured provider fails the request without a file', () async {
      final repository = FakeGeneratedAssetRepository(
        providerUnconfigured: true,
      );

      final outcome = await repository.request(
        const GeneratedAssetRequest(
          kind: GeneratedAssetKind.voice,
          slot: 'aoede_intro',
          prompt: 'Read the welcome line warmly',
          promptVersion: 'v1',
        ),
      );

      expect(outcome.asset.status, GeneratedAssetStatus.failed);
      expect(outcome.asset.errorCode, 'PROVIDER_UNCONFIGURED');
      expect(outcome.asset.storagePath, isNull);
      expect(outcome.asset.providerId, 'configured_voice');
    });

    test('failures surface as errors rather than empty lists', () async {
      final repository = FakeGeneratedAssetRepository(alwaysFail: true);

      expect(repository.listPublished(), throwsStateError);
      expect(repository.listForReview(), throwsStateError);
      expect(
        repository.request(
          const GeneratedAssetRequest(
            kind: GeneratedAssetKind.image,
            slot: 's',
            prompt: 'p',
            promptVersion: 'v1',
          ),
        ),
        throwsStateError,
      );
    });

    test('a signed URL is per asset and time limited', () async {
      final repository = FakeGeneratedAssetRepository();
      final asset = (await repository.listPublished()).first;

      final url = await repository.signedUrl(
        asset,
        expiresIn: const Duration(minutes: 5),
      );

      expect(url, contains(asset.storagePath!));
      expect(url, contains('expires=300'));
    });
  });
}
