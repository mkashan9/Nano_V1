import '../l10n/nano_app_locale.dart';
import 'question_bank.dart';

/// Order policy for questions or options inside a quiz.
enum QuizOrderPolicy {
  fixed,
  shuffle;

  static QuizOrderPolicy fromName(String? name) =>
      name == 'shuffle' ? QuizOrderPolicy.shuffle : QuizOrderPolicy.fixed;

  String get wireName => name;
}

/// Snapshot of pass/timer/retake rules for one quiz version.
class QuizPolicy {
  const QuizPolicy({
    this.passPercent = 70,
    this.timerSeconds,
    this.maxRetakes,
    this.expiresAt,
    this.optionOrder = QuizOrderPolicy.fixed,
    this.questionOrder = QuizOrderPolicy.fixed,
    this.localePolicy = 'both',
    this.experiencePolicy = 'both',
  });

  factory QuizPolicy.fromRow(Map<String, dynamic> row) {
    return QuizPolicy(
      passPercent: (row['pass_percent'] as num?)?.toDouble() ?? 70,
      timerSeconds: (row['timer_seconds'] as num?)?.toInt(),
      maxRetakes: (row['max_retakes'] as num?)?.toInt(),
      expiresAt: switch (row['expires_at']) {
        final String value => DateTime.tryParse(value)?.toUtc(),
        final DateTime value => value.toUtc(),
        _ => null,
      },
      optionOrder: QuizOrderPolicy.fromName(row['option_order_policy'] as String?),
      questionOrder:
          QuizOrderPolicy.fromName(row['question_order_policy'] as String?),
      localePolicy: (row['locale_policy'] as String?) ?? 'both',
      experiencePolicy: (row['experience_policy'] as String?) ?? 'both',
    );
  }

  final double passPercent;
  final int? timerSeconds;
  final int? maxRetakes;
  final DateTime? expiresAt;
  final QuizOrderPolicy optionOrder;
  final QuizOrderPolicy questionOrder;
  final String localePolicy;
  final String experiencePolicy;

  bool get preservesQuestionOrder => questionOrder == QuizOrderPolicy.fixed;
}

/// One ordered question inside a quiz.
class QuizItem {
  const QuizItem({
    required this.sortOrder,
    required this.questionVersionId,
    required this.stem,
    this.stemUr,
    this.kind = QuestionKind.multipleChoice,
    this.difficulty = QuestionDifficulty.easy,
    this.options = const [],
    this.explanation = '',
    this.explanationUr,
    this.quizItemId,
    this.questionId,
  });

  factory QuizItem.fromRow(Map<String, dynamic> row) {
    final optionsRaw = row['options'];
    final options = <QuestionOption>[];
    if (optionsRaw is List) {
      for (final item in optionsRaw) {
        if (item is Map) {
          options.add(
            QuestionOption.fromRow(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return QuizItem(
      quizItemId: row['quiz_item_id'] as String?,
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 1,
      questionVersionId: (row['question_version_id'] as String?) ?? '',
      questionId: row['question_id'] as String?,
      stem: (row['stem'] as String?) ?? '',
      stemUr: row['stem_ur'] as String?,
      kind: QuestionKind.fromName(row['kind'] as String?),
      difficulty: QuestionDifficulty.fromName(row['difficulty'] as String?),
      options: options,
      explanation: (row['explanation'] as String?) ?? '',
      explanationUr: row['explanation_ur'] as String?,
    );
  }

  final String? quizItemId;
  final int sortOrder;
  final String questionVersionId;
  final String? questionId;
  final String stem;
  final String? stemUr;
  final QuestionKind kind;
  final QuestionDifficulty difficulty;
  final List<QuestionOption> options;
  final String explanation;
  final String? explanationUr;

  String stemFor(NanoAppLocale locale) =>
      locale == NanoAppLocale.ur && (stemUr?.isNotEmpty ?? false)
          ? stemUr!
          : stem;

  /// True when any option still carries a correctness flag (curator only).
  bool get exposesCorrectness => options.any((o) => o.isCorrect);
}

/// A quiz version attached to one topic (video) version.
class TopicQuiz {
  const TopicQuiz({
    required this.id,
    required this.topicVersionId,
    required this.title,
    this.titleUr,
    this.topicSlug = '',
    this.topicTitle = '',
    this.version = 1,
    this.status = QuestionStatus.draft,
    this.policy = const QuizPolicy(),
    this.items = const [],
    this.publishedAt,
  });

  factory TopicQuiz.fromRow(Map<String, dynamic> row) {
    final itemsRaw = row['items'];
    final items = <QuizItem>[];
    if (itemsRaw is List) {
      for (final item in itemsRaw) {
        if (item is Map) {
          items.add(QuizItem.fromRow(Map<String, dynamic>.from(item)));
        }
      }
    }
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return TopicQuiz(
      id: (row['quiz_version_id'] as String?) ?? (row['id'] as String?) ?? '',
      topicVersionId: (row['topic_version_id'] as String?) ?? '',
      topicSlug: (row['topic_slug'] as String?) ?? '',
      topicTitle: (row['topic_title'] as String?) ?? '',
      version: (row['version'] as num?)?.toInt() ?? 1,
      status: QuestionStatus.fromName(row['status'] as String?),
      title: (row['title'] as String?) ?? '',
      titleUr: row['title_ur'] as String?,
      policy: QuizPolicy.fromRow(row),
      items: items,
      publishedAt: switch (row['published_at']) {
        final String value => DateTime.tryParse(value)?.toUtc(),
        final DateTime value => value.toUtc(),
        _ => null,
      },
    );
  }

  final String id;
  final String topicVersionId;
  final String topicSlug;
  final String topicTitle;
  final int version;
  final QuestionStatus status;
  final String title;
  final String? titleUr;
  final QuizPolicy policy;
  final List<QuizItem> items;
  final DateTime? publishedAt;

  String titleFor(NanoAppLocale locale) =>
      locale == NanoAppLocale.ur && (titleUr?.isNotEmpty ?? false)
          ? titleUr!
          : title;

  bool get isPublished => status == QuestionStatus.published;

  /// Learner projections must never expose correctness.
  bool get isLearnerSafe => !items.any((item) => item.exposesCorrectness);
}
