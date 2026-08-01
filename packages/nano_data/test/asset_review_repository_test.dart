import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('FakeAssetReviewRepository', () {
    test('the queue leads with what can actually be decided', () async {
      final repo = FakeAssetReviewRepository();

      final queue = await repo.queue();

      expect(queue, isNotEmpty);
      expect(queue.first.isDecidable, isTrue);
      // The failed voice job is still listed, so a stuck slot is visible rather
      // than quietly missing.
      expect(queue.any((item) => !item.isDecidable), isTrue);
    });

    test('nothing starts published', () async {
      final repo = FakeAssetReviewRepository();

      final published = await repo.queue(
        moderation: GeneratedAssetModeration.approved,
      );

      expect(published, isEmpty);
    });

    test('approving publishes and records who decided', () async {
      final repo = FakeAssetReviewRepository();
      final target = (await repo.queue()).first;

      final outcome = await repo.decide(
        [target.id],
        GeneratedAssetModeration.approved,
        note: 'Looks right.',
      );

      expect(outcome.reviewed, 1);
      expect(outcome.unchanged, 0);
      expect(outcome.assets.single.isPublished, isTrue);
      expect(outcome.assets.single.reviewerName, isNotNull);
      expect(outcome.assets.single.reviewedAt, isNotNull);

      final history = await repo.history(target.id);
      expect(history.single.decision, GeneratedAssetModeration.approved);
      expect(
        history.single.previousModeration,
        GeneratedAssetModeration.unreviewed,
      );
    });

    test('deciding the same way twice changes nothing and records nothing',
        () async {
      final repo = FakeAssetReviewRepository();
      final target = (await repo.queue()).first;
      await repo.decide([target.id], GeneratedAssetModeration.approved);

      final again = await repo.decide(
        [target.id],
        GeneratedAssetModeration.approved,
      );

      expect(again.reviewed, 0);
      expect(again.unchanged, 1);
      expect((await repo.history(target.id)).length, 1);
    });

    test('a rejection without a reason is refused', () async {
      final repo = FakeAssetReviewRepository();
      final target = (await repo.queue()).first;

      expect(
        () => repo.decide([target.id], GeneratedAssetModeration.rejected),
        throwsA(isA<AssetReviewRefused>()),
      );
      // Refused means unchanged, not partially applied.
      final after = await repo.queue();
      expect(
        after.firstWhere((item) => item.id == target.id).moderation,
        GeneratedAssetModeration.unreviewed,
      );
    });

    test('an asset with no file cannot be approved', () async {
      final repo = FakeAssetReviewRepository();
      final stuck = (await repo.queue()).firstWhere((item) => !item.isDecidable);

      expect(
        () => repo.decide([stuck.id], GeneratedAssetModeration.approved),
        throwsA(isA<AssetReviewRefused>()),
      );
    });

    test('a batch containing one bad id publishes none of them', () async {
      final repo = FakeAssetReviewRepository();
      final decidable = (await repo.queue())
          .where((item) => item.isDecidable)
          .toList(growable: false);
      expect(decidable.length, greaterThanOrEqualTo(2));

      expect(
        () => repo.decide(
          [decidable[0].id, decidable[1].id, 'not-an-asset'],
          GeneratedAssetModeration.approved,
        ),
        throwsA(isA<AssetReviewRefused>()),
      );

      final after = await repo.queue(
        moderation: GeneratedAssetModeration.approved,
      );
      expect(after, isEmpty);
    });

    test('a good batch publishes every one of them in one call', () async {
      final repo = FakeAssetReviewRepository();
      final decidable = (await repo.queue())
          .where((item) => item.isDecidable)
          .toList(growable: false);

      final outcome = await repo.decide(
        decidable.map((item) => item.id).toList(),
        GeneratedAssetModeration.approved,
      );

      expect(outcome.reviewed, decidable.length);
      expect(
        (await repo.queue(moderation: GeneratedAssetModeration.approved)).length,
        decidable.length,
      );
    });

    test('rejecting an approved asset takes it back out of publication',
        () async {
      final repo = FakeAssetReviewRepository();
      final target = (await repo.queue()).first;
      await repo.decide([target.id], GeneratedAssetModeration.approved);

      await repo.decide(
        [target.id],
        GeneratedAssetModeration.rejected,
        note: 'Wrong expression.',
      );

      final published = await repo.queue(
        moderation: GeneratedAssetModeration.approved,
      );
      expect(published.any((item) => item.id == target.id), isFalse);

      final history = await repo.history(target.id);
      expect(history.first.decision, GeneratedAssetModeration.rejected);
      expect(history.first.note, 'Wrong expression.');
      expect(history.length, 2);
    });

    test('a reviewer can preview a file before it is approved', () async {
      final repo = FakeAssetReviewRepository();
      final target = (await repo.queue()).first;

      expect(target.isPublished, isFalse);
      expect(await repo.previewUrl(target), contains(target.storagePath!));
    });

    test('an asset with no file has nothing to preview', () async {
      final repo = FakeAssetReviewRepository();
      final stuck = (await repo.queue()).firstWhere((item) => !item.hasFile);

      expect(
        () => repo.previewUrl(stuck),
        throwsA(isA<AssetReviewRefused>()),
      );
    });

    test('filters narrow by kind', () async {
      final repo = FakeAssetReviewRepository();

      final videos = await repo.queue(kind: GeneratedAssetKind.video);

      expect(videos, isNotEmpty);
      expect(videos.every((item) => item.kind == GeneratedAssetKind.video), isTrue);
    });
  });
}
