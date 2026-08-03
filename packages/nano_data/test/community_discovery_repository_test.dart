import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
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

  test('FakeCommunityDiscoveryRepository creates and sets roles', () async {
    final repo = FakeCommunityDiscoveryRepository();
    final created = await repo.createCommunity(
      name: 'Chess Club',
      summary: 'Open boards',
      rulesText: 'Be fair',
    );
    expect(created.myRole, 'owner');
    expect((await repo.myCommunities()).any((c) => c.id == created.id), isTrue);

    final members = await repo.listMembers(created.id);
    expect(members.single.role, 'owner');

    final updated = await repo.setMemberRole(
      communityId: 'a1000000-0000-4000-8000-000000000001',
      userId: 'self',
      role: 'moderator',
    );
    expect(
      updated.firstWhere((m) => m.userId == 'self').role,
      'moderator',
    );
  });
}
