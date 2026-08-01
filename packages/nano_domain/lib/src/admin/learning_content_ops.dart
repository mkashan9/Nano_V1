/// ADM-04 curator models for Learning Stack subject/topic authoring.
enum CatalogPublishStatus {
  draft,
  published,
  archived;

  static CatalogPublishStatus fromWire(String? value) => switch (value) {
        'published' => CatalogPublishStatus.published,
        'archived' => CatalogPublishStatus.archived,
        _ => CatalogPublishStatus.draft,
      };

  String get wireName => switch (this) {
        CatalogPublishStatus.draft => 'draft',
        CatalogPublishStatus.published => 'published',
        CatalogPublishStatus.archived => 'archived',
      };
}

class AuthoringTopic {
  const AuthoringTopic({
    required this.topicId,
    required this.slug,
    required this.topicVersionId,
    required this.title,
    required this.status,
    required this.order,
    this.titleUr,
    this.version = 1,
    this.estimatedMinutes = 10,
    this.durationSeconds = 300,
    this.videoProvider,
    this.videoRef,
    this.objectives = const [],
  });

  final String topicId;
  final String slug;
  final String topicVersionId;
  final int version;
  final String title;
  final String? titleUr;
  final CatalogPublishStatus status;
  final int order;
  final int estimatedMinutes;
  final int durationSeconds;
  final String? videoProvider;
  final String? videoRef;
  final List<String> objectives;

  bool get isDraft => status == CatalogPublishStatus.draft;
  bool get isPublished => status == CatalogPublishStatus.published;

  factory AuthoringTopic.fromJson(Map<String, dynamic> json) {
    return AuthoringTopic(
      topicId: json['topic_id'] as String? ?? '',
      slug: json['topic_slug'] as String? ?? '',
      topicVersionId: json['topic_version_id'] as String? ?? '',
      version: (json['topic_version'] as num?)?.toInt() ?? 1,
      title: json['title'] as String? ?? '',
      titleUr: json['title_ur'] as String?,
      status: CatalogPublishStatus.fromWire(json['status'] as String?),
      order: (json['topic_order'] as num?)?.toInt() ?? 0,
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 10,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 300,
      videoProvider: json['video_provider'] as String?,
      videoRef: json['video_ref'] as String?,
      objectives: [
        if (json['objectives'] is List)
          for (final item in json['objectives'] as List)
            if (item != null) '$item',
      ],
    );
  }
}

class AuthoringSubject {
  const AuthoringSubject({
    required this.subjectId,
    required this.slug,
    required this.subjectVersionId,
    required this.title,
    required this.status,
    this.titleUr,
    this.summary = '',
    this.worldColorHex = '#2F7BFF',
    this.version = 1,
    this.order = 0,
    this.track = 'both',
    this.minGrade,
    this.maxGrade,
    this.independentAllowed = true,
    this.topics = const [],
  });

  final String subjectId;
  final String slug;
  final String subjectVersionId;
  final int version;
  final String title;
  final String? titleUr;
  final String summary;
  final String worldColorHex;
  final CatalogPublishStatus status;
  final int order;
  final String track;
  final int? minGrade;
  final int? maxGrade;
  final bool independentAllowed;
  final List<AuthoringTopic> topics;

  bool get isDraft => status == CatalogPublishStatus.draft;
  bool get isPublished => status == CatalogPublishStatus.published;

  factory AuthoringSubject.fromJson(Map<String, dynamic> json) {
    final topicsRaw = json['topics'];
    return AuthoringSubject(
      subjectId: json['subject_id'] as String? ?? '',
      slug: json['subject_slug'] as String? ?? '',
      subjectVersionId: json['subject_version_id'] as String? ?? '',
      version: (json['subject_version'] as num?)?.toInt() ?? 1,
      title: json['subject_title'] as String? ?? '',
      titleUr: json['subject_title_ur'] as String?,
      summary: json['subject_summary'] as String? ?? '',
      worldColorHex: json['world_color_hex'] as String? ?? '#2F7BFF',
      status: CatalogPublishStatus.fromWire(json['subject_status'] as String?),
      order: (json['subject_order'] as num?)?.toInt() ?? 0,
      track: json['track'] as String? ?? 'both',
      minGrade: (json['min_grade'] as num?)?.toInt(),
      maxGrade: (json['max_grade'] as num?)?.toInt(),
      independentAllowed: json['independent_allowed'] as bool? ?? true,
      topics: [
        if (topicsRaw is List)
          for (final row in topicsRaw.whereType<Map>())
            AuthoringTopic.fromJson(Map<String, dynamic>.from(row)),
      ],
    );
  }
}

/// Publish gates mirrored server-side for UI preview checks.
abstract final class LearningContentPublishPolicy {
  static bool subjectReady(AuthoringSubject subject) =>
      subject.title.trim().isNotEmpty;

  static bool topicReady(AuthoringTopic topic) =>
      topic.title.trim().isNotEmpty &&
      (topic.videoProvider?.trim().isNotEmpty ?? false) &&
      (topic.videoRef?.trim().isNotEmpty ?? false);
}
