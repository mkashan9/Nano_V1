import '../l10n/nano_app_locale.dart';
import '../l10n/nano_copy.dart';

/// Progress across one subject, as counted by the server for this learner.
class SubjectProgress {
  const SubjectProgress({
    required this.subjectId,
    required this.slug,
    required this.title,
    this.titleUr,
    this.order = 0,
    this.worldColorHex,
    this.topicsTotal = 0,
    this.topicsCompleted = 0,
    this.topicsInProgress = 0,
    this.topicsLocked = 0,
    this.watchedSeconds = 0,
    this.lastActivityAt,
  });

  factory SubjectProgress.fromRow(Map<String, dynamic> row) {
    return SubjectProgress(
      subjectId: row['subject_id'] as String,
      slug: (row['subject_slug'] as String?) ?? '',
      title: (row['subject_title'] as String?) ?? '',
      titleUr: row['subject_title_ur'] as String?,
      order: (row['subject_order'] as num?)?.toInt() ?? 0,
      worldColorHex: row['world_color_hex'] as String?,
      topicsTotal: (row['topics_total'] as num?)?.toInt() ?? 0,
      topicsCompleted: (row['topics_completed'] as num?)?.toInt() ?? 0,
      topicsInProgress: (row['topics_in_progress'] as num?)?.toInt() ?? 0,
      topicsLocked: (row['topics_locked'] as num?)?.toInt() ?? 0,
      watchedSeconds: (row['watched_seconds'] as num?)?.toInt() ?? 0,
      lastActivityAt: switch (row['last_activity_at']) {
        final String value => DateTime.tryParse(value)?.toUtc(),
        final DateTime value => value.toUtc(),
        _ => null,
      },
    );
  }

  final String subjectId;
  final String slug;
  final String title;
  final String? titleUr;
  final int order;
  final String? worldColorHex;
  final int topicsTotal;
  final int topicsCompleted;
  final int topicsInProgress;

  /// Counted so the UI can say "3 of 8, 2 still locked" instead of implying the
  /// learner is behind on content they cannot open yet.
  final int topicsLocked;
  final int watchedSeconds;
  final DateTime? lastActivityAt;

  String titleFor(NanoAppLocale locale) =>
      locale == NanoAppLocale.ur && (titleUr?.isNotEmpty ?? false)
          ? titleUr!
          : title;

  /// Share of this subject finished, 0 when there is nothing to finish.
  double get completionRatio =>
      topicsTotal == 0 ? 0 : topicsCompleted / topicsTotal;

  bool get isStarted => topicsCompleted > 0 || topicsInProgress > 0;
  bool get isFinished => topicsTotal > 0 && topicsCompleted == topicsTotal;
  int get topicsRemaining => topicsTotal - topicsCompleted;
}

/// Why a topic is being suggested.
enum NextUpReason {
  resume,
  reviewQuiz,
  nextInSubject,
  newSubject;

  static NextUpReason fromName(String? name) => switch (name) {
        'resume' => NextUpReason.resume,
        'review_quiz' => NextUpReason.reviewQuiz,
        'next_in_subject' => NextUpReason.nextInSubject,
        _ => NextUpReason.newSubject,
      };
}

/// One ranked suggestion from `public.learning_next_up`.
class NextUpSuggestion {
  const NextUpSuggestion({
    required this.topicVersionId,
    required this.topicId,
    required this.subjectId,
    required this.title,
    this.titleUr,
    required this.subjectTitle,
    this.subjectTitleUr,
    this.reason = NextUpReason.newSubject,
    this.rank = 1,
    this.estimatedMinutes = 0,
    this.durationSeconds = 0,
    this.watchedSeconds = 0,
    this.resumeSeconds = 0,
    this.worldColorHex,
  });

  factory NextUpSuggestion.fromRow(Map<String, dynamic> row) {
    return NextUpSuggestion(
      topicVersionId: row['topic_version_id'] as String,
      topicId: (row['topic_id'] as String?) ?? '',
      subjectId: (row['subject_id'] as String?) ?? '',
      title: (row['topic_title'] as String?) ?? '',
      titleUr: row['topic_title_ur'] as String?,
      subjectTitle: (row['subject_title'] as String?) ?? '',
      subjectTitleUr: row['subject_title_ur'] as String?,
      reason: NextUpReason.fromName(row['reason'] as String?),
      rank: (row['rank'] as num?)?.toInt() ?? 1,
      estimatedMinutes: (row['estimated_minutes'] as num?)?.toInt() ?? 0,
      durationSeconds: (row['duration_seconds'] as num?)?.toInt() ?? 0,
      watchedSeconds: (row['watched_seconds'] as num?)?.toInt() ?? 0,
      resumeSeconds: (row['resume_seconds'] as num?)?.toInt() ?? 0,
      worldColorHex: row['world_color_hex'] as String?,
    );
  }

  final String topicVersionId;
  final String topicId;
  final String subjectId;
  final String title;
  final String? titleUr;
  final String subjectTitle;
  final String? subjectTitleUr;
  final NextUpReason reason;

  /// 1 is the recommendation; the rest are alternatives in the same order.
  final int rank;
  final int estimatedMinutes;
  final int durationSeconds;
  final int watchedSeconds;
  final int resumeSeconds;
  final String? worldColorHex;

  String titleFor(NanoAppLocale locale) =>
      locale == NanoAppLocale.ur && (titleUr?.isNotEmpty ?? false)
          ? titleUr!
          : title;

  String subjectTitleFor(NanoAppLocale locale) =>
      locale == NanoAppLocale.ur && (subjectTitleUr?.isNotEmpty ?? false)
          ? subjectTitleUr!
          : subjectTitle;

  bool get isResume => reason == NextUpReason.resume;

  String reasonLabel(NanoCopy copy) => switch (reason) {
        NextUpReason.resume => copy.reasonResume,
        NextUpReason.reviewQuiz => copy.reasonReviewQuiz,
        NextUpReason.nextInSubject => copy.reasonNextInSubject,
        NextUpReason.newSubject => copy.reasonNewSubject,
      };
}

/// Everything the progress screen needs, aggregated from the two read models.
class LearningInsights {
  const LearningInsights({
    this.subjects = const [],
    this.suggestions = const [],
    this.fromCache = false,
    this.updatedAt,
  });

  final List<SubjectProgress> subjects;
  final List<NextUpSuggestion> suggestions;
  final bool fromCache;
  final DateTime? updatedAt;

  bool get isEmpty => subjects.isEmpty;

  int get topicsCompleted => subjects.fold(
        0,
        (total, subject) => total + subject.topicsCompleted,
      );

  int get topicsTotal => subjects.fold(
        0,
        (total, subject) => total + subject.topicsTotal,
      );

  int get watchedSeconds => subjects.fold(
        0,
        (total, subject) => total + subject.watchedSeconds,
      );

  int get watchedMinutes => watchedSeconds ~/ 60;

  double get completionRatio =>
      topicsTotal == 0 ? 0 : topicsCompleted / topicsTotal;

  /// The single recommendation, or null when everything visible is finished.
  NextUpSuggestion? get recommendation =>
      suggestions.isEmpty ? null : suggestions.first;

  List<NextUpSuggestion> get alternatives =>
      suggestions.length <= 1 ? const [] : suggestions.sublist(1);

  /// Subjects ordered as the catalog orders them.
  List<SubjectProgress> get orderedSubjects =>
      [...subjects]..sort((a, b) => a.order.compareTo(b.order));

  /// The subject the learner is doing best in.
  ///
  /// Deliberately coarse: this is progress, not mastery. Real strengths arrive
  /// with quiz scoring (QZ-05); until then the honest signal is how much of a
  /// subject someone has actually finished.
  SubjectProgress? get strongest {
    final started = subjects.where((subject) => subject.isStarted).toList();
    if (started.isEmpty) return null;
    started.sort((a, b) {
      final byRatio = b.completionRatio.compareTo(a.completionRatio);
      if (byRatio != 0) return byRatio;
      return b.topicsCompleted.compareTo(a.topicsCompleted);
    });
    final best = started.first;
    return best.topicsCompleted == 0 ? null : best;
  }

  /// The started subject with the least finished, which is where to spend time
  /// next. Null when only one subject has been started.
  SubjectProgress? get needsAttention {
    final started = subjects
        .where((subject) => subject.isStarted && !subject.isFinished)
        .toList();
    if (started.length < 2) return null;
    started.sort((a, b) {
      final byRatio = a.completionRatio.compareTo(b.completionRatio);
      if (byRatio != 0) return byRatio;
      return a.topicsCompleted.compareTo(b.topicsCompleted);
    });
    final focus = started.first;
    return focus.subjectId == strongest?.subjectId ? null : focus;
  }
}
