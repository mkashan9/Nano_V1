/// XP-03 achievements and stickers (server-owned catalog + awards).
enum AchievementKind {
  achievement,
  sticker;

  static AchievementKind fromName(String value) => switch (value) {
        'sticker' => AchievementKind.sticker,
        _ => AchievementKind.achievement,
      };

  String get wireName => switch (this) {
        AchievementKind.sticker => 'sticker',
        AchievementKind.achievement => 'achievement',
      };
}

/// One granted badge or sticker for a learner.
class AchievementAward {
  const AchievementAward({
    required this.awardId,
    required this.slug,
    required this.kind,
    required this.titleEn,
    required this.titleUr,
    this.descriptionEn = '',
    this.descriptionUr = '',
    required this.awardedAt,
  });

  final String awardId;
  final String slug;
  final AchievementKind kind;
  final String titleEn;
  final String titleUr;
  final String descriptionEn;
  final String descriptionUr;
  final DateTime awardedAt;

  bool get isSticker => kind == AchievementKind.sticker;

  String titleFor({required bool urdu}) => urdu ? titleUr : titleEn;

  factory AchievementAward.fromRow(Map<String, dynamic> row) {
    return AchievementAward(
      awardId: row['award_id'] as String? ?? row['id'] as String? ?? '',
      slug: row['slug'] as String? ?? '',
      kind: AchievementKind.fromName(row['kind'] as String? ?? 'achievement'),
      titleEn: row['title_en'] as String? ?? '',
      titleUr: row['title_ur'] as String? ?? '',
      descriptionEn: row['description_en'] as String? ?? '',
      descriptionUr: row['description_ur'] as String? ?? '',
      awardedAt: DateTime.parse(row['awarded_at'] as String).toUtc(),
    );
  }
}
