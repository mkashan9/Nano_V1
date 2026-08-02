/// LGE-03 league peer challenge projection (no peer user ids).
enum LeagueChallengeStatus {
  pending,
  accepted,
  declined,
  expired,
  completed,
  cancelled;

  static LeagueChallengeStatus parse(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'accepted':
        return LeagueChallengeStatus.accepted;
      case 'declined':
        return LeagueChallengeStatus.declined;
      case 'expired':
        return LeagueChallengeStatus.expired;
      case 'completed':
        return LeagueChallengeStatus.completed;
      case 'cancelled':
        return LeagueChallengeStatus.cancelled;
      case 'pending':
      default:
        return LeagueChallengeStatus.pending;
    }
  }

  String get wire => name;
}

enum LeagueChallengeOutcome {
  challengerWin,
  opponentWin,
  tie;

  static LeagueChallengeOutcome? parse(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'challenger_win':
        return LeagueChallengeOutcome.challengerWin;
      case 'opponent_win':
        return LeagueChallengeOutcome.opponentWin;
      case 'tie':
        return LeagueChallengeOutcome.tie;
      default:
        return null;
    }
  }
}

class LeagueChallenge {
  const LeagueChallenge({
    required this.id,
    required this.status,
    required this.ruleSlug,
    required this.titleEn,
    required this.peerLabel,
    required this.iAmChallenger,
    required this.expiresAt,
    this.titleUr = '',
    this.gameVersionId = '',
    this.myScore,
    this.peerScore,
    this.outcome,
    this.rematchOf,
  });

  final String id;
  final LeagueChallengeStatus status;
  final String ruleSlug;
  final String titleEn;
  final String titleUr;
  final String peerLabel;
  final bool iAmChallenger;
  final DateTime expiresAt;
  final String gameVersionId;
  final int? myScore;
  final int? peerScore;
  final LeagueChallengeOutcome? outcome;
  final String? rematchOf;

  String titleFor({required bool urdu}) =>
      urdu && titleUr.trim().isNotEmpty ? titleUr : titleEn;

  bool get canRespond =>
      status == LeagueChallengeStatus.pending && !iAmChallenger;

  bool get canRecordScore => status == LeagueChallengeStatus.accepted;

  bool get canRematch => status == LeagueChallengeStatus.completed;

  factory LeagueChallenge.fromJson(Map<String, dynamic> json) {
    return LeagueChallenge(
      id: json['id'] as String? ?? '',
      status: LeagueChallengeStatus.parse(json['status'] as String?),
      ruleSlug: json['rule_slug'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      titleUr: json['title_ur'] as String? ?? '',
      peerLabel: json['peer_label'] as String? ?? 'Learner',
      iAmChallenger: json['i_am_challenger'] as bool? ?? false,
      expiresAt: DateTime.tryParse('${json['expires_at']}')?.toUtc() ??
          DateTime.now().toUtc(),
      gameVersionId: json['game_version_id'] as String? ?? '',
      myScore: (json['my_score'] as num?)?.toInt(),
      peerScore: (json['peer_score'] as num?)?.toInt(),
      outcome: LeagueChallengeOutcome.parse(json['outcome'] as String?),
      rematchOf: json['rematch_of'] as String?,
    );
  }
}
