/// XP-01 trusted ledger types.
///
/// The server owns every credit. These types are the read model a client may
/// show; they never construct an award.
import 'level_progress.dart';

export 'level_progress.dart' show LevelProgress;

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

/// Running total, daily room, and (XP-02) authoritative level fields.
class XpBalance {
  const XpBalance({
    required this.total,
    required this.today,
    required this.dailyCap,
    required this.remainingToday,
    this.level = 1,
    this.xpIntoLevel = 0,
    this.xpToNext = LevelProgress.defaultXpPerLevel,
    this.xpPerLevel = LevelProgress.defaultXpPerLevel,
    this.reconciled = true,
  });

  final int total;
  final int today;
  final int dailyCap;
  final int remainingToday;

  /// Server level from `level_rules` / `xp_progress`.
  final int level;
  final int xpIntoLevel;
  final int xpToNext;
  final int xpPerLevel;
  final bool reconciled;

  LevelProgress get levelProgress => LevelProgress.fromServer(
        level: level,
        xpIntoLevel: xpIntoLevel,
        xpToNext: xpToNext,
        xpPerLevel: xpPerLevel,
      );

  static const empty = XpBalance(
    total: 0,
    today: 0,
    dailyCap: 200,
    remainingToday: 200,
  );

  factory XpBalance.fromJson(Map<String, dynamic> json) {
    final total = (json['total'] as num?)?.toInt() ?? 0;
    final hasLevel = json.containsKey('level');
    final fallback = LevelProgress.fromXp(total);
    return XpBalance(
      total: total,
      today: (json['today'] as num?)?.toInt() ?? 0,
      dailyCap: (json['daily_cap'] as num?)?.toInt() ?? 200,
      remainingToday: (json['remaining_today'] as num?)?.toInt() ?? 0,
      level: hasLevel
          ? (json['level'] as num?)?.toInt() ?? 1
          : fallback.level,
      xpIntoLevel: hasLevel
          ? (json['xp_into_level'] as num?)?.toInt() ?? 0
          : fallback.xpIntoLevel,
      xpToNext: hasLevel
          ? (json['xp_to_next'] as num?)?.toInt() ?? fallback.xpToNextLevel
          : fallback.xpToNextLevel,
      xpPerLevel: hasLevel
          ? (json['xp_per_level'] as num?)?.toInt() ??
              LevelProgress.defaultXpPerLevel
          : fallback.xpPerLevel,
      reconciled: json['reconciled'] as bool? ?? true,
    );
  }
}
