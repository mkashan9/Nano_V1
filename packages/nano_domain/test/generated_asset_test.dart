import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('GeneratedAsset', () {
    test('the published projection reads as ready and approved', () {
      // The client read side carries no status or moderation column, because
      // everything it returns has already passed both.
      final asset = GeneratedAsset.fromRow({
        'id': '90000000-0000-0000-0000-000000000001',
        'kind': 'video',
        'slot': 'celebration_celebration_shortClip',
        'locale': 'ur',
        'aspect_ratio': '16:9',
        'storage_bucket': 'generated-assets',
        'storage_path': 'video/celebration/ur/hash.mp4',
        'content_type': 'video/mp4',
        'byte_size': 512000,
        'checksum': 'sha256:abc',
        'completed_at': '2026-08-01T00:00:00Z',
      });

      expect(asset.kind, GeneratedAssetKind.video);
      expect(asset.status, GeneratedAssetStatus.ready);
      expect(asset.moderation, GeneratedAssetModeration.approved);
      expect(asset.isPlayable, isTrue);
      expect(asset.completedAt, DateTime.utc(2026, 8, 1));
    });

    test('provenance is absent on the client projection', () {
      final asset = GeneratedAsset.fromRow({
        'id': 'a',
        'kind': 'image',
        'slot': 'guide_greeting_staticArt',
        'locale': 'en',
        'aspect_ratio': '1:1',
        'storage_path': 'image/x.png',
        'storage_bucket': 'generated-assets',
        'checksum': 'sha256:abc',
      });

      expect(asset.prompt, isNull);
      expect(asset.providerId, isNull);
      expect(asset.costMicros, isNull);
    });

    test('an admin row keeps its provenance and stays unplayable until approved',
        () {
      final asset = GeneratedAsset.fromRow({
        'id': 'a',
        'kind': 'image',
        'slot': 'guide_greeting_staticArt',
        'locale': 'en',
        'aspect_ratio': '1:1',
        'status': 'ready',
        'moderation': 'unreviewed',
        'storage_bucket': 'generated-assets',
        'storage_path': 'image/x.png',
        'prompt': 'a friendly companion',
        'prompt_version': 'v1',
        'prompt_hash': 'abc',
        'provider_id': 'pollinations_image',
        'cost_micros': 1500,
        'attempts_count': 1,
      });

      expect(asset.prompt, 'a friendly companion');
      expect(asset.costMicros, 1500);
      expect(asset.isPlayable, isFalse);
    });

    test('a failed row carries a reason and no file', () {
      final asset = GeneratedAsset.fromRow({
        'id': 'a',
        'kind': 'voice',
        'slot': 'aoede_intro',
        'locale': 'en',
        'aspect_ratio': '1:1',
        'status': 'failed',
        'moderation': 'unreviewed',
        'error_code': 'PROVIDER_UNCONFIGURED',
      });

      expect(asset.status, GeneratedAssetStatus.failed);
      expect(asset.errorCode, 'PROVIDER_UNCONFIGURED');
      expect(asset.isPlayable, isFalse);
    });

    test('an unknown enum value falls back instead of throwing', () {
      final asset = GeneratedAsset.fromRow({
        'id': 'a',
        'kind': 'hologram',
        'slot': 's',
        'locale': 'en',
        'aspect_ratio': '1:1',
        'status': 'teleporting',
        'moderation': 'maybe',
      });

      expect(asset.kind, GeneratedAssetKind.image);
      expect(asset.status, GeneratedAssetStatus.requested);
      expect(asset.moderation, GeneratedAssetModeration.unreviewed);
    });
  });

  group('GeneratedAssetRequest', () {
    test('a companion request uses the reaction key the runtime looks up', () {
      const reaction = CompanionReaction(
        event: CompanionEvent.levelUp,
        mood: CompanionMood.celebration,
        script: CompanionScript(id: 'celebration-1', text: 'Nicely done!'),
        tier: CompanionAssetTier.shortClip,
        mode: CompanionMode.celebration,
      );

      final request = GeneratedAssetRequest.forReaction(
        reaction,
        prompt: 'a short celebration',
        promptVersion: 'v1',
        kind: GeneratedAssetKind.video,
      );

      expect(request.slot, reaction.assetKey);
      expect(request.kind, GeneratedAssetKind.video);
      expect(request.toParams()['p_slot'], reaction.assetKey);
      expect(request.toParams()['p_provider_id'], isNull);
    });

    test('parameters use the server names, so a client cannot invent one', () {
      const request = GeneratedAssetRequest(
        kind: GeneratedAssetKind.image,
        slot: 'guide_greeting_staticArt',
        prompt: 'a friendly companion',
        promptVersion: 'v2',
        locale: NanoAppLocale.ur,
        aspectRatio: '9:16',
        providerId: 'pollinations_image',
      );

      expect(request.toParams(), {
        'p_kind': 'image',
        'p_slot': 'guide_greeting_staticArt',
        'p_prompt': 'a friendly companion',
        'p_prompt_version': 'v2',
        'p_locale': 'ur',
        'p_aspect_ratio': '9:16',
        'p_provider_id': 'pollinations_image',
        // MED-02 budget dimensions travel with every ask; the companion is the
        // default because it is the only feature that generates anything yet.
        'p_feature': 'companion',
        'p_school_id': null,
      });
    });
  });

  group('GeneratedAssetOutcome', () {
    test('reuse is reported, so a caller can tell nothing was paid for', () {
      final outcome = GeneratedAssetOutcome.fromJson({
        'reused': true,
        'asset': {
          'id': 'a',
          'kind': 'image',
          'slot': 's',
          'locale': 'en',
          'aspect_ratio': '1:1',
          'status': 'ready',
          'moderation': 'unreviewed',
        },
      });

      expect(outcome.reused, isTrue);
      expect(outcome.asset.id, 'a');
    });
  });
}
