import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// SOC-02 friend requests, friendships, and blocks.
abstract class FriendGraphRepository {
  Future<FriendRequest> sendRequest(String query);

  Future<FriendRequest> respond(String requestId, {required bool accept});

  Future<FriendRequest> cancel(String requestId);

  Future<List<FriendRequest>> listRequests();

  Future<List<FriendPeer>> listFriends();

  Future<void> removeFriend(String peerToken);

  Future<void> blockUser(String query);

  Future<List<BlockedPeer>> listBlocks();

  Future<void> unblock(String peerToken);

  /// SOC-03 weekly XP ranks among caller + friends.
  Future<FriendsLeaderboard> friendsLeaderboard({int limit = 25});
}

class FakeFriendGraphRepository implements FriendGraphRepository {
  FakeFriendGraphRepository({
    List<FriendRequest>? requests,
    List<FriendPeer>? friends,
    List<BlockedPeer>? blocks,
    FriendsLeaderboard? leaderboard,
  })  : _requests = [...?requests],
        _friends = [...?friends],
        _blocks = [...?blocks],
        _leaderboard = leaderboard ??
            const FriendsLeaderboard(
              weekKey: '2026-W31',
              friendCount: 1,
              myRank: 1,
              myWeekXp: 120,
              entries: [
                FriendsBoardEntry(
                  rank: 1,
                  weekXp: 120,
                  displayLabel: 'You',
                  isMe: true,
                ),
                FriendsBoardEntry(
                  rank: 2,
                  weekXp: 80,
                  displayLabel: 'sara',
                ),
              ],
            );

  final List<FriendRequest> _requests;
  final List<FriendPeer> _friends;
  final List<BlockedPeer> _blocks;
  final FriendsLeaderboard _leaderboard;
  final sentQueries = <String>[];
  final blockedQueries = <String>[];

  @override
  Future<FriendRequest> sendRequest(String query) async {
    sentQueries.add(query.trim().toLowerCase());
    final req = FriendRequest(
      id: 'req-${_requests.length + 1}',
      status: FriendRequestStatus.pending,
      direction: FriendRequestDirection.outgoing,
      peerLabel: query.trim().toLowerCase(),
      username: query.trim().toLowerCase(),
      createdAt: DateTime.utc(2026, 8, 2),
    );
    _requests.insert(0, req);
    return req;
  }

  @override
  Future<FriendRequest> respond(String requestId, {required bool accept}) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index < 0) throw StateError('Friend request not found.');
    final current = _requests[index];
    final next = FriendRequest(
      id: current.id,
      status: accept
          ? FriendRequestStatus.accepted
          : FriendRequestStatus.declined,
      direction: current.direction,
      peerLabel: current.peerLabel,
      username: current.username,
      createdAt: current.createdAt,
    );
    _requests[index] = next;
    if (accept) {
      _friends.insert(
        0,
        FriendPeer(
          peerToken: 'tok-${current.peerLabel}',
          peerLabel: current.peerLabel,
          username: current.username,
        ),
      );
    }
    return next;
  }

  @override
  Future<FriendRequest> cancel(String requestId) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index < 0) throw StateError('Friend request not found.');
    final current = _requests[index];
    final next = FriendRequest(
      id: current.id,
      status: FriendRequestStatus.cancelled,
      direction: current.direction,
      peerLabel: current.peerLabel,
      username: current.username,
      createdAt: current.createdAt,
    );
    _requests[index] = next;
    return next;
  }

  @override
  Future<List<FriendRequest>> listRequests() async =>
      _requests.where((r) => r.status == FriendRequestStatus.pending).toList();

  @override
  Future<List<FriendPeer>> listFriends() async => List.unmodifiable(_friends);

  @override
  Future<void> removeFriend(String peerToken) async {
    _friends.removeWhere((f) => f.peerToken == peerToken);
  }

  @override
  Future<void> blockUser(String query) async {
    blockedQueries.add(query.trim().toLowerCase());
    _friends.removeWhere(
      (f) =>
          f.peerLabel == query.trim().toLowerCase() ||
          f.username == query.trim().toLowerCase(),
    );
    _requests.removeWhere(
      (r) =>
          r.peerLabel == query.trim().toLowerCase() ||
          r.username == query.trim().toLowerCase(),
    );
    _blocks.insert(
      0,
      BlockedPeer(
        peerToken: 'blk-${query.trim().toLowerCase()}',
        peerLabel: query.trim().toLowerCase(),
        username: query.trim().toLowerCase(),
      ),
    );
  }

  @override
  Future<List<BlockedPeer>> listBlocks() async => List.unmodifiable(_blocks);

  @override
  Future<void> unblock(String peerToken) async {
    _blocks.removeWhere((b) => b.peerToken == peerToken);
  }

  @override
  Future<FriendsLeaderboard> friendsLeaderboard({int limit = 25}) async {
    final capped = _leaderboard.entries.take(limit).toList();
    return FriendsLeaderboard(
      weekKey: _leaderboard.weekKey,
      entries: capped,
      myRank: _leaderboard.myRank,
      myWeekXp: _leaderboard.myWeekXp,
      friendCount: _friends.isEmpty
          ? _leaderboard.friendCount
          : _friends.length,
    );
  }
}

class SupabaseFriendGraphRepository implements FriendGraphRepository {
  SupabaseFriendGraphRepository(this._client);

  final SupabaseClient _client;

  FriendRequest _parseRequest(dynamic raw) {
    if (raw is! Map) throw StateError('Friend request missing.');
    return FriendRequest.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<FriendRequest> sendRequest(String query) async {
    final raw = await _client.rpc(
      'send_friend_request',
      params: {'p_query': query},
    );
    return _parseRequest(raw);
  }

  @override
  Future<FriendRequest> respond(String requestId, {required bool accept}) async {
    final raw = await _client.rpc(
      'respond_friend_request',
      params: {'p_request_id': requestId, 'p_accept': accept},
    );
    return _parseRequest(raw);
  }

  @override
  Future<FriendRequest> cancel(String requestId) async {
    final raw = await _client.rpc(
      'cancel_friend_request',
      params: {'p_request_id': requestId},
    );
    return _parseRequest(raw);
  }

  @override
  Future<List<FriendRequest>> listRequests() async {
    final raw = await _client.rpc('my_friend_requests');
    if (raw is! Map) return const [];
    final items = raw['requests'];
    if (items is! List) return const [];
    return [
      for (final item in items)
        if (item is Map)
          FriendRequest.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  @override
  Future<List<FriendPeer>> listFriends() async {
    final raw = await _client.rpc('my_friends');
    if (raw is! Map) return const [];
    final items = raw['friends'];
    if (items is! List) return const [];
    return [
      for (final item in items)
        if (item is Map) FriendPeer.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  @override
  Future<void> removeFriend(String peerToken) async {
    await _client.rpc('remove_friend', params: {'p_peer_token': peerToken});
  }

  @override
  Future<void> blockUser(String query) async {
    await _client.rpc('block_user', params: {'p_query': query});
  }

  @override
  Future<List<BlockedPeer>> listBlocks() async {
    final raw = await _client.rpc('my_blocks');
    if (raw is! Map) return const [];
    final items = raw['blocks'];
    if (items is! List) return const [];
    return [
      for (final item in items)
        if (item is Map) BlockedPeer.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  @override
  Future<void> unblock(String peerToken) async {
    await _client.rpc('unblock_user', params: {'p_peer_token': peerToken});
  }

  @override
  Future<FriendsLeaderboard> friendsLeaderboard({int limit = 25}) async {
    final raw = await _client.rpc(
      'my_friends_leaderboard',
      params: {'p_limit': limit},
    );
    if (raw is! Map) throw StateError('Friends leaderboard unavailable.');
    return FriendsLeaderboard.fromJson(Map<String, dynamic>.from(raw));
  }
}
