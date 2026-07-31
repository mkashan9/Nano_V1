import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// Reads the learner's own progress summary and their ranked next-up list.
///
/// Both come from server read models. The client never decides what is
/// eligible, unlocked, or worth suggesting; it only presents the ranking and
/// the reason the server gave.
abstract class LearningInsightsRepository {
  Future<LearningInsights> loadInsights();
}

/// Fixtures shaped like the seeded development content.
class FakeLearningInsightsRepository implements LearningInsightsRepository {
  FakeLearningInsightsRepository({
    this.alwaysFail = false,
    this.empty = false,
    this.allFinished = false,
    this.mathStarted = true,
    this.delay = Duration.zero,
  });

  final bool alwaysFail;
  final bool empty;

  /// Nothing left to suggest, which the UI must celebrate rather than blank.
  final bool allFinished;
  final bool mathStarted;
  final Duration delay;

  var loadCount = 0;

  @override
  Future<LearningInsights> loadInsights() async {
    loadCount++;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (alwaysFail) throw StateError('Insights unavailable');
    if (empty) return const LearningInsights();

    final now = DateTime.now().toUtc();
    if (allFinished) {
      return LearningInsights(
        subjects: [
          SubjectProgress(
            subjectId: 'subject-math',
            slug: 'math',
            title: 'Math',
            titleUr: 'حساب',
            order: 1,
            topicsTotal: 2,
            topicsCompleted: 2,
            watchedSeconds: 240,
            lastActivityAt: now,
          ),
        ],
        updatedAt: now,
      );
    }

    return LearningInsights(
      subjects: [
        SubjectProgress(
          subjectId: 'subject-math',
          slug: 'math',
          title: 'Math',
          titleUr: 'حساب',
          order: 1,
          worldColorHex: '#2F7BFF',
          topicsTotal: 2,
          topicsCompleted: mathStarted ? 1 : 0,
          topicsInProgress: mathStarted ? 1 : 0,
          topicsLocked: mathStarted ? 0 : 1,
          watchedSeconds: mathStarted ? 150 : 0,
          lastActivityAt: mathStarted ? now : null,
        ),
        SubjectProgress(
          subjectId: 'subject-science',
          slug: 'science',
          title: 'Science',
          titleUr: 'سائنس',
          order: 2,
          worldColorHex: '#FF8A3D',
          topicsTotal: 3,
          topicsCompleted: 0,
          topicsInProgress: 1,
          topicsLocked: 1,
          watchedSeconds: 30,
          lastActivityAt: now.subtract(const Duration(days: 2)),
        ),
      ],
      suggestions: [
        const NextUpSuggestion(
          topicVersionId: 'tv-addition-1',
          topicId: 'topic-addition',
          subjectId: 'subject-math',
          title: 'Adding small numbers',
          titleUr: 'چھوٹے اعداد جمع',
          subjectTitle: 'Math',
          subjectTitleUr: 'حساب',
          reason: NextUpReason.resume,
          rank: 1,
          estimatedMinutes: 15,
          durationSeconds: 150,
          watchedSeconds: 60,
          resumeSeconds: 60,
        ),
        const NextUpSuggestion(
          topicVersionId: 'tv-living-things-1',
          topicId: 'topic-living-things',
          subjectId: 'subject-science',
          title: 'Living things',
          titleUr: 'جاندار',
          subjectTitle: 'Science',
          subjectTitleUr: 'سائنس',
          reason: NextUpReason.nextInSubject,
          rank: 2,
          estimatedMinutes: 18,
          durationSeconds: 180,
        ),
      ],
      updatedAt: now,
    );
  }
}

class SupabaseLearningInsightsRepository implements LearningInsightsRepository {
  SupabaseLearningInsightsRepository(this._client);

  static const _summaryColumns =
      'subject_id, subject_slug, subject_order, subject_title, '
      'subject_title_ur, world_color_hex, topics_total, topics_completed, '
      'topics_in_progress, topics_locked, watched_seconds, last_activity_at';

  static const _nextUpColumns =
      'topic_version_id, topic_id, subject_id, topic_title, topic_title_ur, '
      'subject_title, subject_title_ur, world_color_hex, reason, rank, '
      'estimated_minutes, duration_seconds, watched_seconds, resume_seconds';

  /// Enough for a recommendation plus a couple of alternatives; the ranking
  /// itself stays on the server.
  static const _suggestionLimit = 5;

  final SupabaseClient _client;

  @override
  Future<LearningInsights> loadInsights() async {
    final summaryRows = await _client
        .from('learning_progress_summary')
        .select(_summaryColumns)
        .order('subject_order');
    final nextUpRows = await _client
        .from('learning_next_up')
        .select(_nextUpColumns)
        .order('rank')
        .limit(_suggestionLimit);

    return LearningInsights(
      subjects: [
        for (final row in summaryRows as List)
          SubjectProgress.fromRow(Map<String, dynamic>.from(row as Map)),
      ],
      suggestions: [
        for (final row in nextUpRows as List)
          NextUpSuggestion.fromRow(Map<String, dynamic>.from(row as Map)),
      ],
      updatedAt: DateTime.now().toUtc(),
    );
  }
}
