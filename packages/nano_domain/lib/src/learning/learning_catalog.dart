import '../l10n/nano_app_locale.dart';
import 'learning_subject.dart';
import 'refresh_checkpoint.dart';
import 'topic_playback.dart';

/// Per-learner state for one published topic version.
enum TopicProgressStatus {
  notStarted,
  inProgress,
  completed;

  static TopicProgressStatus fromName(String? value) => switch (value) {
        'in_progress' => TopicProgressStatus.inProgress,
        'completed' => TopicProgressStatus.completed,
        _ => TopicProgressStatus.notStarted,
      };
}

/// One published topic version plus the caller's progress and lock state.
///
/// Lock state arrives from the server as the list of prerequisite titles the
/// learner still has to finish, so the client never decides what is unlocked.
class CatalogTopic {
  const CatalogTopic({
    required this.topicId,
    required this.topicVersionId,
    required this.slug,
    required this.title,
    required this.order,
    required this.estimatedMinutes,
    this.titleUr,
    this.objectives = const [],
    this.resources = const [],
    this.status = TopicProgressStatus.notStarted,
    this.progress = 0,
    this.resumeSeconds = 0,
    this.watchedSeconds = 0,
    this.durationSeconds = 300,
    this.completionThreshold = 0.9,
    this.videoProvider,
    this.videoRef,
    this.captions = const CaptionTrack([]),
    this.chapters = const [],
    this.seekPolicy = SeekPolicy.free,
    this.blockingTitles = const [],
  });

  factory CatalogTopic.fromRow(Map<String, dynamic> row) {
    return CatalogTopic(
      topicId: row['topic_id'] as String,
      topicVersionId: row['topic_version_id'] as String,
      slug: row['topic_slug'] as String,
      title: row['topic_title'] as String,
      titleUr: row['topic_title_ur'] as String?,
      order: (row['topic_order'] as num?)?.toInt() ?? 0,
      estimatedMinutes: (row['estimated_minutes'] as num?)?.toInt() ?? 0,
      objectives: _stringList(row['objectives']),
      resources: _stringList(row['resources']),
      status: TopicProgressStatus.fromName(row['progress_status'] as String?),
      progress: (row['progress'] as num?)?.toDouble() ?? 0,
      resumeSeconds: (row['resume_seconds'] as num?)?.toInt() ?? 0,
      watchedSeconds: (row['watched_seconds'] as num?)?.toInt() ?? 0,
      durationSeconds: (row['duration_seconds'] as num?)?.toInt() ?? 300,
      completionThreshold:
          (row['completion_threshold'] as num?)?.toDouble() ?? 0.9,
      videoProvider: row['video_provider'] as String?,
      videoRef: row['video_ref'] as String?,
      captions: CaptionTrack.fromRows(row['captions']),
      chapters: VideoChapter.listFrom(row['chapters']),
      seekPolicy: SeekPolicy.fromName(row['seek_policy'] as String?),
      blockingTitles: _stringList(row['blocking_titles']),
    );
  }

  final String topicId;
  final String topicVersionId;
  final String slug;
  final String title;
  final String? titleUr;
  final int order;
  final int estimatedMinutes;
  final List<String> objectives;
  final List<String> resources;
  final TopicProgressStatus status;
  final double progress;
  final int resumeSeconds;

  /// Watch time the server has credited, which is what completion is measured
  /// against. The client never adds to this on its own.
  final int watchedSeconds;
  final int durationSeconds;
  final double completionThreshold;
  final String? videoProvider;
  final String? videoRef;
  final CaptionTrack captions;
  final List<VideoChapter> chapters;

  /// Whether the content lets the learner drag ahead of what they watched.
  final SeekPolicy seekPolicy;

  /// Prerequisite topic titles still outstanding, as computed on the server.
  final List<String> blockingTitles;

  bool get isLocked => blockingTitles.isNotEmpty;
  bool get isCompleted => status == TopicProgressStatus.completed;
  bool get canResume =>
      !isLocked && status == TopicProgressStatus.inProgress && resumeSeconds > 0;
  int get percentComplete => (progress.clamp(0, 1) * 100).round();
  bool get hasVideo => (videoRef?.isNotEmpty ?? false);

  bool get meetsCompletionThreshold => PlaybackPolicy.canComplete(
        watchedSeconds: watchedSeconds,
        durationSeconds: durationSeconds,
        threshold: completionThreshold,
      );

  int get secondsLeftToComplete => PlaybackPolicy.remainingSeconds(
        watchedSeconds: watchedSeconds,
        durationSeconds: durationSeconds,
        threshold: completionThreshold,
      );

  String titleFor(NanoAppLocale locale) =>
      locale == NanoAppLocale.ur && (titleUr?.isNotEmpty ?? false)
          ? titleUr!
          : title;

  CatalogTopic copyWith({
    TopicProgressStatus? status,
    double? progress,
    int? resumeSeconds,
    int? watchedSeconds,
    SeekPolicy? seekPolicy,
    List<String>? blockingTitles,
  }) {
    return CatalogTopic(
      topicId: topicId,
      topicVersionId: topicVersionId,
      slug: slug,
      title: title,
      titleUr: titleUr,
      order: order,
      estimatedMinutes: estimatedMinutes,
      objectives: objectives,
      resources: resources,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      resumeSeconds: resumeSeconds ?? this.resumeSeconds,
      watchedSeconds: watchedSeconds ?? this.watchedSeconds,
      durationSeconds: durationSeconds,
      completionThreshold: completionThreshold,
      videoProvider: videoProvider,
      videoRef: videoRef,
      captions: captions,
      chapters: chapters,
      seekPolicy: seekPolicy ?? this.seekPolicy,
      blockingTitles: blockingTitles ?? this.blockingTitles,
    );
  }
}

/// One published subject version with its ordered topics.
class CatalogSubject {
  const CatalogSubject({
    required this.subjectId,
    required this.subjectVersionId,
    required this.slug,
    required this.title,
    required this.order,
    required this.topics,
    this.titleUr,
    this.summary = '',
    this.worldColorValue = 0xFF2F7BFF,
  });

  static const int fallbackWorldColor = 0xFF2F7BFF;

  /// Rows for a single subject, as returned by the catalog read model.
  factory CatalogSubject.fromRows(List<Map<String, dynamic>> rows) {
    final first = rows.first;
    final topics = rows.map(CatalogTopic.fromRow).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return CatalogSubject(
      subjectId: first['subject_id'] as String,
      subjectVersionId: first['subject_version_id'] as String,
      slug: first['subject_slug'] as String,
      title: first['subject_title'] as String,
      titleUr: first['subject_title_ur'] as String?,
      summary: (first['subject_summary'] as String?) ?? '',
      worldColorValue: parseWorldColor(first['world_color_hex'] as String?),
      order: (first['subject_order'] as num?)?.toInt() ?? 0,
      topics: topics,
    );
  }

  final String subjectId;
  final String subjectVersionId;
  final String slug;
  final String title;
  final String? titleUr;
  final String summary;
  final int worldColorValue;
  final int order;
  final List<CatalogTopic> topics;

  int get completedTopics => topics.where((t) => t.isCompleted).length;
  int get lockedTopics => topics.where((t) => t.isLocked).length;
  bool get isComplete => topics.isNotEmpty && completedTopics == topics.length;

  double get progress =>
      topics.isEmpty ? 0 : completedTopics / topics.length;

  /// Minutes still to spend, used as the subject's "time left" hint.
  int get remainingMinutes => topics
      .where((t) => !t.isCompleted)
      .fold(0, (sum, t) => sum + t.estimatedMinutes);

  /// What the learner should open next: resume an in-progress topic, otherwise
  /// the first unlocked topic that is not finished.
  CatalogTopic? get nextTopic {
    for (final topic in topics) {
      if (topic.canResume) return topic;
    }
    for (final topic in topics) {
      if (!topic.isCompleted && !topic.isLocked) return topic;
    }
    return null;
  }

  String titleFor(NanoAppLocale locale) =>
      locale == NanoAppLocale.ur && (titleUr?.isNotEmpty ?? false)
          ? titleUr!
          : title;

  /// Reuses the home grid record (STU-03) so the catalog and home never drift.
  LearningSubject toHomeSubject({NanoAppLocale locale = NanoAppLocale.en}) {
    return LearningSubject(
      id: subjectId,
      title: titleFor(locale),
      progress: progress,
      worldColorValue: worldColorValue,
      estimatedMinutes: remainingMinutes == 0 ? null : remainingMinutes,
      shortPrompt: summary.isEmpty ? null : summary,
    );
  }

  static int parseWorldColor(String? hex) {
    if (hex == null || hex.length != 7 || !hex.startsWith('#')) {
      return fallbackWorldColor;
    }
    final value = int.tryParse(hex.substring(1), radix: 16);
    return value == null ? fallbackWorldColor : 0xFF000000 | value;
  }
}

/// The catalog a single learner is allowed to see.
class LearningCatalog {
  const LearningCatalog({
    required this.subjects,
    required this.updatedAt,
    this.fromCache = false,
  });

  /// Groups flat read-model rows into subjects, preserving server ordering.
  factory LearningCatalog.fromRows(
    List<Map<String, dynamic>> rows, {
    required DateTime updatedAt,
    bool fromCache = false,
  }) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      grouped.putIfAbsent(row['subject_id'] as String, () => []).add(row);
    }
    final subjects = grouped.values.map(CatalogSubject.fromRows).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return LearningCatalog(
      subjects: subjects,
      updatedAt: updatedAt,
      fromCache: fromCache,
    );
  }

  final List<CatalogSubject> subjects;
  final DateTime updatedAt;
  final bool fromCache;

  bool get isEmpty => subjects.isEmpty;

  CatalogSubject? subjectById(String id) {
    for (final subject in subjects) {
      if (subject.subjectId == id) return subject;
    }
    return null;
  }

  /// Senior search across subject titles, summaries, and topic titles.
  List<CatalogSubject> search(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return subjects;
    return subjects.where((subject) {
      if (subject.title.toLowerCase().contains(needle)) return true;
      if ((subject.titleUr ?? '').toLowerCase().contains(needle)) return true;
      if (subject.summary.toLowerCase().contains(needle)) return true;
      return subject.topics.any(
        (topic) =>
            topic.title.toLowerCase().contains(needle) ||
            (topic.titleUr ?? '').toLowerCase().contains(needle),
      );
    }).toList();
  }

  /// The single best next step across every eligible subject.
  CatalogTopic? get nextRecommendation {
    for (final subject in subjects) {
      final topic = subject.nextTopic;
      if (topic != null && topic.canResume) return topic;
    }
    for (final subject in subjects) {
      final topic = subject.nextTopic;
      if (topic != null) return topic;
    }
    return null;
  }

  /// Version identity, so a Junior and Senior render of the same catalog can be
  /// proven to reference the same published content.
  Set<String> get topicVersionIds => {
        for (final subject in subjects)
          for (final topic in subject.topics) topic.topicVersionId,
      };

  List<LearningSubject> toHomeSubjects({
    NanoAppLocale locale = NanoAppLocale.en,
  }) =>
      [for (final subject in subjects) subject.toHomeSubject(locale: locale)];
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  if (value is String && value.isNotEmpty) {
    return [value];
  }
  return const [];
}
