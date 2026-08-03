import 'package:nano_data/nano_data.dart';
import 'package:test/test.dart';

void main() {
  test('FakeCommunityDiscoveryRepository lists mine and discover', () async {
    final repo = FakeCommunityDiscoveryRepository();
    final mine = await repo.myCommunities();
    expect(mine, isNotEmpty);
    expect(mine.first.isMember, isTrue);

    final discover = await repo.discoverPublic();
    expect(discover, isNotEmpty);
    expect(discover.every((c) => !c.isMember), isTrue);

    final filtered = await repo.discoverPublic(query: 'science');
    expect(filtered.single.name, 'Science Lab');

    final detail = await repo.getDetail(mine.first.id);
    expect(detail.rulesText, isNotEmpty);
  });
}
