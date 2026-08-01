import 'learning_content_ops.dart';

/// ADM-06 curator models for platform game catalog administration.
/// Reuses [CatalogPublishStatus] from learning content authoring.
class AdminGame {
  const AdminGame({
    required this.gameId,
    required this.slug,
    required this.category,
    required this.gameVersionId,
    required this.titleEn,
    required this.status,
    required this.enabled,
    this.titleUr = '',
    this.summaryEn = '',
    this.summaryUr = '',
    this.version = 1,
    this.sortOrder = 0,
    this.minGrade,
    this.maxGrade,
    this.entryKind = 'web',
    this.entryRef = '',
    this.publishedAt,
  });

  final String gameId;
  final String slug;
  final String category;
  final int sortOrder;
  final String gameVersionId;
  final int version;
  final String titleEn;
  final String titleUr;
  final String summaryEn;
  final String summaryUr;
  final int? minGrade;
  final int? maxGrade;
  final CatalogPublishStatus status;
  final bool enabled;
  final String entryKind;
  final String entryRef;
  final DateTime? publishedAt;

  bool get isDraft => status == CatalogPublishStatus.draft;
  bool get isPublished => status == CatalogPublishStatus.published;
  bool get isLive => isPublished && enabled;

  factory AdminGame.fromJson(Map<String, dynamic> json) {
    return AdminGame(
      gameId: json['game_id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      category: json['category'] as String? ?? 'practice',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      gameVersionId: json['game_version_id'] as String? ?? '',
      version: (json['version'] as num?)?.toInt() ?? 1,
      titleEn: json['title_en'] as String? ?? '',
      titleUr: json['title_ur'] as String? ?? '',
      summaryEn: json['summary_en'] as String? ?? '',
      summaryUr: json['summary_ur'] as String? ?? '',
      minGrade: (json['min_grade'] as num?)?.toInt(),
      maxGrade: (json['max_grade'] as num?)?.toInt(),
      status: CatalogPublishStatus.fromWire(json['status'] as String?),
      enabled: json['enabled'] as bool? ?? true,
      entryKind: json['entry_kind'] as String? ?? 'web',
      entryRef: json['entry_ref'] as String? ?? '',
      publishedAt: json['published_at'] == null
          ? null
          : DateTime.tryParse('${json['published_at']}'),
    );
  }
}

/// Publish gates mirrored server-side for UI preview checks.
abstract final class GamePublishPolicy {
  static bool ready(AdminGame game) =>
      game.titleEn.trim().isNotEmpty && game.entryRef.trim().isNotEmpty;
}
