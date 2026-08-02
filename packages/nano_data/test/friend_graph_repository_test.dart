import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('fake send accept remove and block flow', () async {
    final repo = FakeFriendGraphRepository(
      requests: [
        const FriendRequest(
          id: 'req-1',
          status: FriendRequestStatus.pending,
          direction: FriendRequestDirection.incoming,
          peerLabel: 'sara',
          username: 'sara',
        ),
      ],
    );

    await repo.sendRequest('omar');
    expect(repo.sentQueries, ['omar']);

    final accepted = await repo.respond('req-1', accept: true);
    expect(accepted.status, FriendRequestStatus.accepted);
    expect((await repo.listFriends()).single.peerLabel, 'sara');

    await repo.blockUser('sara');
    expect(repo.blockedQueries, ['sara']);
    expect(await repo.listFriends(), isEmpty);
    expect((await repo.listBlocks()).single.peerLabel, 'sara');

    await repo.unblock('blk-sara');
    expect(await repo.listBlocks(), isEmpty);
  });
}
