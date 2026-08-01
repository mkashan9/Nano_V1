import '../learning/home_plan_item.dart';

/// XP-04 mission cadence.
enum MissionCadence {
  daily,
  weekly;

  static MissionCadence fromName(String value) => switch (value) {
        'weekly' => MissionCadence.weekly,
        _ => MissionCadence.daily,
      };

  String get wireName => switch (this) {
        MissionCadence.weekly => 'weekly',
        MissionCadence.daily => 'daily',
      };
}

/// One mission row for the current period (from `my_missions`).
class MissionProgressView {
  const MissionProgressView({
    required this.missionId,
    required this.slug,
    required this.cadence,
    required this.titleEn,
    required this.titleUr,
    required this.subtitleEn,
    required this.subtitleUr,
    required this.xpBonus,
    required this.targetCount,
    required this.progressCount,
    required this.periodKey,
    required this.completed,
    this.completedAt,
  });

  final String missionId;
  final String slug;
  final MissionCadence cadence;
  final String titleEn;
  final String titleUr;
  final String subtitleEn;
  final String subtitleUr;
  final int xpBonus;
  final int targetCount;
  final int progressCount;
  final String periodKey;
  final bool completed;
  final DateTime? completedAt;

  String titleFor({required bool urdu}) => urdu ? titleUr : titleEn;

  String subtitleFor({required bool urdu}) => urdu ? subtitleUr : subtitleEn;

  HomePlanItem toHomePlanItem({required bool urdu}) {
    return HomePlanItem(
      id: missionId,
      title: titleFor(urdu: urdu),
      subtitle: subtitleFor(urdu: urdu),
      xpReward: xpBonus,
      completed: completed,
      progress: progressCount,
      target: targetCount,
      cadence: cadence.wireName,
    );
  }

  factory MissionProgressView.fromRow(Map<String, dynamic> row) {
    return MissionProgressView(
      missionId: row['mission_id'] as String? ?? '',
      slug: row['slug'] as String? ?? '',
      cadence: MissionCadence.fromName(row['cadence'] as String? ?? 'daily'),
      titleEn: row['title_en'] as String? ?? '',
      titleUr: row['title_ur'] as String? ?? '',
      subtitleEn: row['subtitle_en'] as String? ?? '',
      subtitleUr: row['subtitle_ur'] as String? ?? '',
      xpBonus: (row['xp_bonus'] as num?)?.toInt() ?? 0,
      targetCount: (row['target_count'] as num?)?.toInt() ?? 1,
      progressCount: (row['progress_count'] as num?)?.toInt() ?? 0,
      periodKey: row['period_key'] as String? ?? '',
      completed: row['completed'] as bool? ?? false,
      completedAt: row['completed_at'] == null
          ? null
          : DateTime.parse(row['completed_at'] as String).toUtc(),
    );
  }
}
