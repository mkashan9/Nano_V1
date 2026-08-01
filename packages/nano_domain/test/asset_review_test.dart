import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('AssetReviewItem', () {
    test('only a ready asset can be decided', () {
      const stuck = AssetReviewItem(
        id: '1',
        kind: GeneratedAssetKind.image,
        slot: 'guide_greeting_staticArt',
        locale: 'en',
        aspectRatio: '1:1',
        status: GeneratedAssetStatus.requested,
        moderation: GeneratedAssetModeration.unreviewed,
      );
      const ready = AssetReviewItem(
        id: '2',
        kind: GeneratedAssetKind.image,
        slot: 'guide_greeting_staticArt',
        locale: 'en',
        aspectRatio: '1:1',
        status: GeneratedAssetStatus.ready,
        moderation: GeneratedAssetModeration.unreviewed,
      );

      expect(stuck.isDecidable, isFalse);
      expect(ready.isDecidable, isTrue);
    });

    test('a failed job is in the queue but is not publishable', () {
      const failed = AssetReviewItem(
        id: '3',
        kind: GeneratedAssetKind.voice,
        slot: 'guide_greeting_voice',
        locale: 'ur',
        aspectRatio: '1:1',
        status: GeneratedAssetStatus.failed,
        moderation: GeneratedAssetModeration.unreviewed,
        errorCode: 'PROVIDER_UNCONFIGURED',
      );

      expect(failed.isDecidable, isFalse);
      expect(failed.hasFile, isFalse);
      expect(failed.errorCode, 'PROVIDER_UNCONFIGURED');
    });

    test('a row carries the provenance a learner must never receive', () {
      final item = AssetReviewItem.fromRow(const {
        'id': '4',
        'kind': 'video',
        'slot': 'celebration_celebration_shortClip',
        'locale': 'en',
        'aspect_ratio': '9:16',
        'status': 'ready',
        'moderation': 'unreviewed',
        'prompt': 'The companion hops once.',
        'prompt_version': 'v2',
        'provider_id': 'gemini_veo_video',
        'feature': 'companion',
        'storage_bucket': 'generated-assets',
        'storage_path': 'video/celebration/en/hash.mp4',
        'content_type': 'video/mp4',
        'byte_size': 512000,
        'checksum': 'sha256:clip',
        'cost_micros': 120000,
      });

      expect(item.prompt, 'The companion hops once.');
      expect(item.providerId, 'gemini_veo_video');
      expect(item.costMicros, 120000);
      expect(item.hasFile, isTrue);
      expect(item.isDecidable, isTrue);
      expect(item.isPublished, isFalse);
    });

    test('a row with no file is not previewable', () {
      final item = AssetReviewItem.fromRow(const {
        'id': '5',
        'kind': 'image',
        'slot': 'guide_greeting_staticArt',
        'locale': 'en',
        'aspect_ratio': '1:1',
        'status': 'requested',
        'moderation': 'unreviewed',
      });

      expect(item.hasFile, isFalse);
    });

    test('an unknown moderation state is read as unreviewed, never approved',
        () {
      // A parser that guesses "approved" on unfamiliar input would publish
      // something nobody decided on.
      final item = AssetReviewItem.fromRow(const {
        'id': '6',
        'kind': 'image',
        'slot': 'x',
        'locale': 'en',
        'aspect_ratio': '1:1',
        'status': 'ready',
        'moderation': 'quarantined',
      });

      expect(item.moderation, GeneratedAssetModeration.unreviewed);
      expect(item.isPublished, isFalse);
    });
  });

  group('AssetReviewOutcome', () {
    test('separates real decisions from ones already in force', () {
      final outcome = AssetReviewOutcome.fromJson(const {
        'decision': 'approved',
        'reviewed': 2,
        'unchanged': 1,
        'assets': [
          {
            'id': '1',
            'kind': 'image',
            'slot': 'a',
            'locale': 'en',
            'aspect_ratio': '1:1',
            'status': 'ready',
            'moderation': 'approved',
          },
        ],
      });

      expect(outcome.decision, GeneratedAssetModeration.approved);
      expect(outcome.reviewed, 2);
      expect(outcome.unchanged, 1);
      expect(outcome.assets.single.isPublished, isTrue);
    });
  });

  group('AssetReviewEvent', () {
    test('records what changed and who changed it', () {
      final event = AssetReviewEvent.fromRow(const {
        'id': 'e1',
        'previous_moderation': 'approved',
        'decision': 'rejected',
        'note': 'Six fingers.',
        'reviewer_name': 'Platform Admin',
        'created_at': '2026-08-01T12:00:00Z',
      });

      expect(event.previousModeration, GeneratedAssetModeration.approved);
      expect(event.decision, GeneratedAssetModeration.rejected);
      expect(event.note, 'Six fingers.');
      expect(event.reviewerName, 'Platform Admin');
      expect(event.createdAt, isNotNull);
    });
  });

  group('review copy', () {
    test('says nothing changed rather than reporting a hollow success', () {
      final copy = NanoCopy(NanoAppLocale.en);

      expect(copy.assetReviewCount(0, 1), contains('already'));
      expect(copy.assetReviewCount(2, 0), contains('2'));
      expect(copy.assetReviewCount(2, 1), contains('1'));
    });

    test('publication reads as published, not as approved paperwork', () {
      final copy = NanoCopy(NanoAppLocale.en);

      expect(
        copy.assetModerationLabel(GeneratedAssetModeration.approved),
        'Published',
      );
      expect(
        copy.assetModerationLabel(GeneratedAssetModeration.unreviewed),
        'Unreviewed',
      );
    });

    test('the review surface is translated', () {
      final urdu = NanoCopy(NanoAppLocale.ur);

      expect(urdu.assetApproveLabel, isNot('Approve'));
      expect(urdu.assetReviewTitle, isNot('Media review'));
    });
  });
}
