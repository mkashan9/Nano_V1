/// Display-only level derived from server-owned XP.
///
/// Prefer [LevelProgress.fromServer] / fields on [XpBalance] when the ledger
/// is wired. [fromXp] remains the offline/fixture fallback and matches the
/// seeded flat 250 XP curve until a non-linear table lands via ADM-05.
class LevelProgress {
  const LevelProgress({
    required this.level,
    required this.xpIntoLevel,
    required this.xpPerLevel,
    int? xpToNextLevel,
  }) : xpToNextLevel = xpToNextLevel ?? (xpPerLevel - xpIntoLevel);

  static const int defaultXpPerLevel = 250;

  factory LevelProgress.fromXp(int xp, {int xpPerLevel = defaultXpPerLevel}) {
    final safeXp = xp < 0 ? 0 : xp;
    final into = safeXp % xpPerLevel;
    return LevelProgress(
      level: safeXp ~/ xpPerLevel + 1,
      xpIntoLevel: into,
      xpPerLevel: xpPerLevel,
      xpToNextLevel: xpPerLevel - into,
    );
  }

  /// Authoritative fields from `my_xp_balance` / `level_rules`.
  factory LevelProgress.fromServer({
    required int level,
    required int xpIntoLevel,
    required int xpToNext,
    required int xpPerLevel,
  }) {
    return LevelProgress(
      level: level < 1 ? 1 : level,
      xpIntoLevel: xpIntoLevel < 0 ? 0 : xpIntoLevel,
      xpPerLevel: xpPerLevel < 1 ? 1 : xpPerLevel,
      xpToNextLevel: xpToNext < 0 ? 0 : xpToNext,
    );
  }

  final int level;
  final int xpIntoLevel;
  final int xpPerLevel;
  final int xpToNextLevel;

  double get fraction {
    if (xpToNextLevel <= 0) return 1;
    return (xpIntoLevel / xpPerLevel).clamp(0.0, 1.0);
  }
}
