/// LGE-01 weekly league personal status.
class LeagueStatus {
  const LeagueStatus({
    required this.joined,
    required this.weekKey,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.weekXp,
    this.rank,
    this.peerCount = 0,
    this.divisionSlug = '',
    this.divisionTitleEn = '',
    this.divisionTitleUr = '',
  });

  final bool joined;
  final String weekKey;
  final DateTime startsAt;
  final DateTime endsAt;
  final String status;
  final int weekXp;
  final int? rank;
  final int peerCount;
  final String divisionSlug;
  final String divisionTitleEn;
  final String divisionTitleUr;

  bool get isOpen => status == 'open';

  String divisionTitleFor({required bool urdu}) =>
      urdu && divisionTitleUr.trim().isNotEmpty
          ? divisionTitleUr
          : divisionTitleEn;

  Duration get timeRemaining {
    final left = endsAt.difference(DateTime.now().toUtc());
    return left.isNegative ? Duration.zero : left;
  }

  static LeagueStatus notJoined({
    required String weekKey,
    required DateTime startsAt,
    required DateTime endsAt,
  }) =>
      LeagueStatus(
        joined: false,
        weekKey: weekKey,
        startsAt: startsAt,
        endsAt: endsAt,
        status: 'open',
        weekXp: 0,
      );

  factory LeagueStatus.fromJson(Map<String, dynamic> json) {
    return LeagueStatus(
      joined: json['joined'] as bool? ?? false,
      weekKey: json['week_key'] as String? ?? '',
      startsAt: DateTime.tryParse('${json['starts_at']}')?.toUtc() ??
          DateTime.now().toUtc(),
      endsAt: DateTime.tryParse('${json['ends_at']}')?.toUtc() ??
          DateTime.now().toUtc().add(const Duration(days: 7)),
      status: json['status'] as String? ?? 'open',
      weekXp: (json['week_xp'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt(),
      peerCount: (json['peer_count'] as num?)?.toInt() ?? 0,
      divisionSlug: json['division_slug'] as String? ?? '',
      divisionTitleEn: json['division_title_en'] as String? ?? '',
      divisionTitleUr: json['division_title_ur'] as String? ?? '',
    );
  }
}
