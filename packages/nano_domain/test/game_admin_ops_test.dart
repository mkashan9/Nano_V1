import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('admin game parses catalog row', () {
    final game = AdminGame.fromJson({
      'game_id': 'g1',
      'slug': 'number_rush',
      'category': 'practice',
      'sort_order': 10,
      'game_version_id': 'v1',
      'version': 2,
      'title_en': 'Number Rush',
      'status': 'published',
      'enabled': true,
      'entry_kind': 'web',
      'entry_ref': 'fixture://number_rush',
    });
    expect(game.isLive, isTrue);
    expect(GamePublishPolicy.ready(game), isTrue);
  });

  test('publish policy requires entry ref', () {
    const game = AdminGame(
      gameId: 'g1',
      slug: 'x',
      category: 'practice',
      gameVersionId: 'v1',
      titleEn: 'X',
      status: CatalogPublishStatus.draft,
      enabled: true,
      entryRef: '',
    );
    expect(GamePublishPolicy.ready(game), isFalse);
  });
}
