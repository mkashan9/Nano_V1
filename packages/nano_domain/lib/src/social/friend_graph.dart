/// SOC-02 friend graph models. Peer user ids never appear in client JSON.
enum FriendRequestDirection { incoming, outgoing }

enum FriendRequestStatus { pending, accepted, declined, cancelled }

class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.status,
    required this.direction,
    required this.peerLabel,
    this.username,
    this.createdAt,
  });

  final String id;
  final FriendRequestStatus status;
  final FriendRequestDirection direction;
  final String peerLabel;
  final String? username;
  final DateTime? createdAt;

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    final statusRaw = json['status'] as String? ?? 'pending';
    final directionRaw = json['direction'] as String? ?? 'incoming';
    final created = json['created_at'];
    return FriendRequest(
      id: json['id'] as String? ?? '',
      status: FriendRequestStatus.values.firstWhere(
        (value) => value.name == statusRaw,
        orElse: () => FriendRequestStatus.pending,
      ),
      direction: directionRaw == 'outgoing'
          ? FriendRequestDirection.outgoing
          : FriendRequestDirection.incoming,
      peerLabel: json['peer_label'] as String? ?? 'Learner',
      username: json['username'] as String?,
      createdAt: created is String ? DateTime.tryParse(created) : null,
    );
  }
}

class FriendPeer {
  const FriendPeer({
    required this.peerToken,
    required this.peerLabel,
    this.username,
    this.since,
  });

  final String peerToken;
  final String peerLabel;
  final String? username;
  final DateTime? since;

  factory FriendPeer.fromJson(Map<String, dynamic> json) {
    final sinceRaw = json['since'];
    return FriendPeer(
      peerToken: json['peer_token'] as String? ?? '',
      peerLabel: json['peer_label'] as String? ?? 'Learner',
      username: json['username'] as String?,
      since: sinceRaw is String ? DateTime.tryParse(sinceRaw) : null,
    );
  }
}

class BlockedPeer {
  const BlockedPeer({
    required this.peerToken,
    required this.peerLabel,
    this.username,
    this.since,
  });

  final String peerToken;
  final String peerLabel;
  final String? username;
  final DateTime? since;

  factory BlockedPeer.fromJson(Map<String, dynamic> json) {
    final sinceRaw = json['since'];
    return BlockedPeer(
      peerToken: json['peer_token'] as String? ?? '',
      peerLabel: json['peer_label'] as String? ?? 'Learner',
      username: json['username'] as String?,
      since: sinceRaw is String ? DateTime.tryParse(sinceRaw) : null,
    );
  }
}
