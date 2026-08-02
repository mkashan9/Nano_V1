/// SOC-03 privacy-safe friends weekly ranking entry.
class FriendsBoardEntry {
  const FriendsBoardEntry({
    required this.rank,
    required this.weekXp,
    required this.displayLabel,
    this.isMe = false,
  });

  final int rank;
  final int weekXp;
  final String displayLabel;
  final bool isMe;

  factory FriendsBoardEntry.fromJson(Map<String, dynamic> json) {
    return FriendsBoardEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      weekXp: (json['week_xp'] as num?)?.toInt() ?? 0,
      displayLabel: json['display_label'] as String? ?? 'Learner',
      isMe: json['is_me'] as bool? ?? false,
    );
  }
}

/// Payload from `my_friends_leaderboard`.
class FriendsLeaderboard {
  const FriendsLeaderboard({
    required this.weekKey,
    required this.entries,
    this.myRank,
    this.myWeekXp = 0,
    this.friendCount = 0,
  });

  final String weekKey;
  final List<FriendsBoardEntry> entries;
  final int? myRank;
  final int myWeekXp;
  final int friendCount;

  static const empty = FriendsLeaderboard(weekKey: '', entries: []);

  factory FriendsLeaderboard.fromJson(Map<String, dynamic> json) {
    final raw = json['entries'];
    return FriendsLeaderboard(
      weekKey: json['week_key'] as String? ?? '',
      entries: [
        if (raw is List)
          for (final row in raw)
            if (row is Map)
              FriendsBoardEntry.fromJson(Map<String, dynamic>.from(row)),
      ],
      myRank: (json['my_rank'] as num?)?.toInt(),
      myWeekXp: (json['my_week_xp'] as num?)?.toInt() ?? 0,
      friendCount: (json['friend_count'] as num?)?.toInt() ?? 0,
    );
  }
}
