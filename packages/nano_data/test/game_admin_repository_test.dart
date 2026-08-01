import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('publish draft and disable require reason', () async {
    final repo = FakeGameAdminRepository();
    final draft = (await repo.listGames())
        .firstWhere((g) => g.status == CatalogPublishStatus.draft);
    final published = await repo.publish(draft.gameVersionId);
    expect(published.isLive, isTrue);

    expect(
      () => repo.disable(gameVersionId: published.gameVersionId, reason: ' '),
      throwsStateError,
    );
    final disabled = await repo.disable(
      gameVersionId: published.gameVersionId,
      reason: 'Unsafe content',
    );
    expect(disabled.enabled, isFalse);
    expect(disabled.status, CatalogPublishStatus.archived);
  });

  test('create draft adds a new game', () async {
    final repo = FakeGameAdminRepository();
    final created = await repo.createDraft(
      slug: 'word_match',
      titleEn: 'Word Match',
      entryRef: 'fixture://word_match',
    );
    expect(created.isDraft, isTrue);
    expect(await repo.listGames(), hasLength(3));
  });
}
