import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('FriendRequest parses incoming pending', () {
    final req = FriendRequest.fromJson({
      'id': 'r1',
      'status': 'pending',
      'direction': 'incoming',
      'peer_label': 'sara',
      'username': 'sara',
    });
    expect(req.direction, FriendRequestDirection.incoming);
    expect(req.status, FriendRequestStatus.pending);
    expect(req.peerLabel, 'sara');
  });

  test('FriendPeer and BlockedPeer omit user ids', () {
    final friend = FriendPeer.fromJson({
      'peer_token': 'tok',
      'peer_label': 'ali',
    });
    final block = BlockedPeer.fromJson({
      'peer_token': 'blk',
      'peer_label': 'bob',
    });
    expect(friend.peerToken, 'tok');
    expect(block.peerLabel, 'bob');
  });
}
