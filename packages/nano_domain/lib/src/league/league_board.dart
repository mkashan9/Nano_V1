/// LGE-02 privacy-safe leaderboard entry.
class LeagueBoardEntry {
  const LeagueBoardEntry({
    required this.rank,
    required this.weekXp,
    required this.displayLabel,
    this.isMe = false,
  });

  final int rank;
  final int weekXp;
  final String displayLabel;
  final bool isMe;

  factory LeagueBoardEntry.fromJson(Map<String, dynamic> json) {
    return LeagueBoardEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      weekXp: (json['week_xp'] as num?)?.toInt() ?? 0,
      displayLabel: json['display_label'] as String? ?? 'Learner',
      isMe: json['is_me'] as bool? ?? false,
    );
  }
}

/// Board payload from `my_league_leaderboard`.
class LeagueBoard {
  const LeagueBoard({
    required this.joined,
    required this.weekKey,
    required this.entries,
    this.myRank,
    this.myWeekXp = 0,
    this.divisionSlug = '',
    this.divisionTitleEn = '',
    this.divisionTitleUr = '',
  });

  final bool joined;
  final String weekKey;
  final List<LeagueBoardEntry> entries;
  final int? myRank;
  final int myWeekXp;
  final String divisionSlug;
  final String divisionTitleEn;
  final String divisionTitleUr;

  String divisionTitleFor({required bool urdu}) =>
      urdu && divisionTitleUr.trim().isNotEmpty
          ? divisionTitleUr
          : divisionTitleEn;

  static const empty = LeagueBoard(
    joined: false,
    weekKey: '',
    entries: [],
  );

  factory LeagueBoard.fromJson(Map<String, dynamic> json) {
    final raw = json['entries'];
    return LeagueBoard(
      joined: json['joined'] as bool? ?? false,
      weekKey: json['week_key'] as String? ?? '',
      entries: [
        if (raw is List)
          for (final row in raw)
            if (row is Map)
              LeagueBoardEntry.fromJson(Map<String, dynamic>.from(row)),
      ],
      myRank: (json['my_rank'] as num?)?.toInt(),
      myWeekXp: (json['my_week_xp'] as num?)?.toInt() ?? 0,
      divisionSlug: json['division_slug'] as String? ?? '',
      divisionTitleEn: json['division_title_en'] as String? ?? '',
      divisionTitleUr: json['division_title_ur'] as String? ?? '',
    );
  }
}
