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

  test('FakeCommunityDiscoveryRepository joins public and private', () async {
    final repo = FakeCommunityDiscoveryRepository();
    final joined = await repo.joinCommunity(
      'a1000000-0000-4000-8000-000000000002',
    );
    expect(joined.isMember, isTrue);
    expect((await repo.myCommunities()).any((c) => c.id == joined.id), isTrue);

    final private = await repo.createCommunity(
      name: 'Private Club',
      visibility: CommunityVisibility.private,
    );
    // Leave as owner is allowed in fake; re-join as pending via second identity
    // is not modeled — seed a pending request for owner review instead.
    repo.seedJoinRequest(
      private.id,
      const CommunityMember(
        userId: 'u-pending',
        displayName: 'Pending Pat',
        role: 'member',
        status: CommunityMembershipStatus.pending,
      ),
    );
    final requests = await repo.listJoinRequests(private.id);
    expect(requests.single.displayName, 'Pending Pat');

    final remaining = await repo.respondJoinRequest(
      communityId: private.id,
      userId: 'u-pending',
      accept: true,
    );
    expect(remaining, isEmpty);
    expect(
      (await repo.listMembers(private.id)).any((m) => m.userId == 'u-pending'),
      isTrue,
    );
  });

  test('FakeCommunityDiscoveryRepository creates and redeems invite', () async {
    final repo = FakeCommunityDiscoveryRepository();
    final invite = await repo.createInvite(
      'a1000000-0000-4000-8000-000000000001',
    );
    expect(invite.code, isNotEmpty);

    final joined = await repo.redeemInvite(invite.code);
    expect(joined.isMember, isTrue);
  });
}
