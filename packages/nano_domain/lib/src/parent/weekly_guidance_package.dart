import 'parent_guidance.dart';

/// PAR-02 superadmin weekly PDF / activity package (upload + publish).

enum WeeklyGuidancePackageStatus { draft, published }

class WeeklyGuidancePackage {
  const WeeklyGuidancePackage({
    required this.id,
    required this.weekKey,
    required this.titleEn,
    required this.bodyEn,
    required this.status,
    required this.updatedAt,
    this.activityTips = const [],
    this.pdfFileName,
    this.publishedAt,
  });

  final String id;
  final String weekKey;
  final String titleEn;
  final String bodyEn;
  final WeeklyGuidancePackageStatus status;
  final DateTime updatedAt;
  final List<String> activityTips;
  final String? pdfFileName;
  final DateTime? publishedAt;

  bool get hasPdf => pdfFileName != null && pdfFileName!.trim().isNotEmpty;
  bool get isPublished => status == WeeklyGuidancePackageStatus.published;

  WeeklyGuidancePackage copyWith({
    String? titleEn,
    String? bodyEn,
    List<String>? activityTips,
    String? pdfFileName,
    WeeklyGuidancePackageStatus? status,
    DateTime? updatedAt,
    DateTime? publishedAt,
    bool clearPublishedAt = false,
  }) {
    return WeeklyGuidancePackage(
      id: id,
      weekKey: weekKey,
      titleEn: titleEn ?? this.titleEn,
      bodyEn: bodyEn ?? this.bodyEn,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      activityTips: activityTips ?? this.activityTips,
      pdfFileName: pdfFileName ?? this.pdfFileName,
      publishedAt:
          clearPublishedAt ? null : (publishedAt ?? this.publishedAt),
    );
  }

  factory WeeklyGuidancePackage.fromJson(Map<String, dynamic> json) {
    final tips = json['activity_tips'];
    final statusRaw = '${json['status'] ?? 'draft'}';
    return WeeklyGuidancePackage(
      id: json['id'] as String? ?? '',
      weekKey: json['week_key'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      bodyEn: json['body_en'] as String? ?? '',
      status: statusRaw == 'published'
          ? WeeklyGuidancePackageStatus.published
          : WeeklyGuidancePackageStatus.draft,
      updatedAt: DateTime.tryParse('${json['updated_at'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      activityTips: tips is List
          ? [for (final tip in tips) '$tip']
          : const [],
      pdfFileName: json['pdf_file_name'] as String?,
      publishedAt: json['published_at'] == null
          ? null
          : DateTime.tryParse('${json['published_at']}'),
    );
  }

  /// Converts a published package into the PAR-01 learner/guardian card shape.
  ParentGuidanceCard toParentGuidanceCard() {
    return ParentGuidanceCard(
      id: id,
      weekKey: weekKey,
      title: titleEn,
      body: bodyEn,
      publishedAt: publishedAt ?? updatedAt,
      activityTips: activityTips,
    );
  }
}

abstract final class WeeklyGuidancePublishPolicy {
  static String? validateForPublish(WeeklyGuidancePackage package) {
    if (package.titleEn.trim().isEmpty) return 'Title is required';
    if (package.bodyEn.trim().isEmpty) return 'Body is required';
    if (!package.hasPdf) return 'PDF filename is required before publish';
    if (package.weekKey.trim().isEmpty) return 'Week key is required';
    return null;
  }

  static bool canPublish(WeeklyGuidancePackage package) =>
      validateForPublish(package) == null;
}
