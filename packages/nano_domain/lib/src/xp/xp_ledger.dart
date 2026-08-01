/// XP-01 trusted ledger types.
///
/// The server owns every credit. These types are the read model a client may
/// show; they never construct an award.
enum XpSourceKind {
  videoCompletion,
  quizPass,
  manualAdjust,
  reversal,
  gameResult;

  static XpSourceKind fromName(String value) => switch (value) {
        'video_completion' => XpSourceKind.videoCompletion,
        'quiz_pass' => XpSourceKind.quizPass,
        'manual_adjust' => XpSourceKind.manualAdjust,
        'reversal' => XpSourceKind.reversal,
        'game_result' => XpSourceKind.gameResult,
        _ => XpSourceKind.manualAdjust,
      };

  String get wireName => switch (this) {
        XpSourceKind.videoCompletion => 'video_completion',
        XpSourceKind.quizPass => 'quiz_pass',
        XpSourceKind.manualAdjust => 'manual_adjust',
        XpSourceKind.reversal => 'reversal',
        XpSourceKind.gameResult => 'game_result',
      };
}

/// One append-only ledger row.
class XpLedgerEntry {
  const XpLedgerEntry({
    required this.id,
    required this.userId,
    required this.amount,
    required this.sourceKind,
    required this.sourceId,
    this.reason = '',
    required this.awardedAt,
  });

  final String id;
  final String userId;
  final int amount;
  final XpSourceKind sourceKind;
  final String sourceId;
  final String reason;
  final DateTime awardedAt;

  bool get isCredit => amount > 0;
  bool get isDebit => amount < 0;

  factory XpLedgerEntry.fromRow(Map<String, dynamic> row) {
    return XpLedgerEntry(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      amount: (row['amount'] as num).toInt(),
      sourceKind: XpSourceKind.fromName(row['source_kind'] as String? ?? ''),
      sourceId: row['source_id'] as String? ?? '',
      reason: row['reason'] as String? ?? '',
      awardedAt: DateTime.parse(row['awarded_at'] as String).toUtc(),
    );
  }
}

/// Running total and today's remaining room under the daily cap.
class XpBalance {
  const XpBalance({
    required this.total,
    required this.today,
    required this.dailyCap,
    required this.remainingToday,
  });

  final int total;
  final int today;
  final int dailyCap;
  final int remainingToday;

  static const empty = XpBalance(
    total: 0,
    today: 0,
    dailyCap: 200,
    remainingToday: 200,
  );

  factory XpBalance.fromJson(Map<String, dynamic> json) {
    return XpBalance(
      total: (json['total'] as num?)?.toInt() ?? 0,
      today: (json['today'] as num?)?.toInt() ?? 0,
      dailyCap: (json['daily_cap'] as num?)?.toInt() ?? 200,
      remainingToday: (json['remaining_today'] as num?)?.toInt() ?? 0,
    );
  }
}
