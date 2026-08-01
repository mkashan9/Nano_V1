import '../l10n/nano_app_locale.dart';
import 'question_bank.dart';

/// One reviewed question after submit: what the learner picked, what was
/// correct, and why (QZ-06).
class AttemptReviewItem {
  const AttemptReviewItem({
    required this.sortOrder,
    required this.questionVersionId,
    required this.stem,
    this.stemUr,
    this.kind = QuestionKind.multipleChoice,
    this.options = const [],
    this.selectedOptionId,
    this.correctOptionId,
    this.wasCorrect = false,
    this.explanation = '',
    this.explanationUr,
  });

  factory AttemptReviewItem.fromRow(Map<String, dynamic> row) {
    final optionsRaw = row['options'];
    final options = <QuestionOption>[];
    if (optionsRaw is List) {
      for (final option in optionsRaw) {
        if (option is Map) {
          options.add(
            QuestionOption.fromRow(Map<String, dynamic>.from(option)),
          );
        }
      }
    }
    return AttemptReviewItem(
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 1,
      questionVersionId: (row['question_version_id'] as String?) ?? '',
      stem: (row['stem'] as String?) ?? '',
      stemUr: row['stem_ur'] as String?,
      kind: QuestionKind.fromName(row['kind'] as String?),
      options: options,
      selectedOptionId: row['selected_option_id'] as String?,
      correctOptionId: row['correct_option_id'] as String?,
      wasCorrect: row['was_correct'] == true,
      explanation: (row['explanation'] as String?) ?? '',
      explanationUr: row['explanation_ur'] as String?,
    );
  }

  final int sortOrder;
  final String questionVersionId;
  final String stem;
  final String? stemUr;
  final QuestionKind kind;
  final List<QuestionOption> options;
  final String? selectedOptionId;
  final String? correctOptionId;
  final bool wasCorrect;
  final String explanation;
  final String? explanationUr;

  String stemFor(NanoAppLocale locale) =>
      locale == NanoAppLocale.ur && (stemUr?.isNotEmpty ?? false)
          ? stemUr!
          : stem;

  String explanationFor(NanoAppLocale locale) =>
      locale == NanoAppLocale.ur && (explanationUr?.isNotEmpty ?? false)
          ? explanationUr!
          : explanation;

  bool get hasExplanation => explanation.trim().isNotEmpty;

  bool get skipped => (selectedOptionId ?? '').isEmpty;

  QuestionOption? _option(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final option in options) {
      if (option.id == id) return option;
    }
    return null;
  }

  String? selectedLabelFor(NanoAppLocale locale) =>
      _option(selectedOptionId)?.labelFor(locale);

  String? correctLabelFor(NanoAppLocale locale) =>
      _option(correctOptionId)?.labelFor(locale);
}

/// Server-authored result for a submitted attempt, with the retake budget the
/// server will actually honour (QZ-06).
class AttemptResult {
  const AttemptResult({
    required this.attemptId,
    required this.quizVersionId,
    required this.topicVersionId,
    required this.scorePercent,
    required this.passed,
    required this.correctCount,
    required this.totalCount,
    this.attemptNumber = 1,
    this.passPercent = 70,
    this.quizTitle = '',
    this.quizTitleUr,
    this.topicTitle = '',
    this.topicTitleUr,
    this.attemptsUsed = 1,
    this.maxRetakes,
    this.retakesRemaining,
    this.canRetake = true,
    this.scoredAt,
    this.items = const [],
  });

  factory AttemptResult.fromRow(Map<String, dynamic> row) {
    final itemsRaw = row['items'];
    final items = <AttemptReviewItem>[];
    if (itemsRaw is List) {
      for (final item in itemsRaw) {
        if (item is Map) {
          items.add(
            AttemptReviewItem.fromRow(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return AttemptResult(
      attemptId: (row['attempt_id'] as String?) ?? '',
      quizVersionId: (row['quiz_version_id'] as String?) ?? '',
      topicVersionId: (row['topic_version_id'] as String?) ?? '',
      attemptNumber: (row['attempt_number'] as num?)?.toInt() ?? 1,
      scorePercent: (row['score_percent'] as num?)?.toDouble() ?? 0,
      passed: row['passed'] == true,
      correctCount: (row['correct_count'] as num?)?.toInt() ?? 0,
      totalCount: (row['total_count'] as num?)?.toInt() ?? items.length,
      passPercent: (row['pass_percent'] as num?)?.toDouble() ?? 70,
      quizTitle: (row['quiz_title'] as String?) ?? '',
      quizTitleUr: row['quiz_title_ur'] as String?,
      topicTitle: (row['topic_title'] as String?) ?? '',
      topicTitleUr: row['topic_title_ur'] as String?,
      attemptsUsed: (row['attempts_used'] as num?)?.toInt() ?? 1,
      maxRetakes: (row['max_retakes'] as num?)?.toInt(),
      retakesRemaining: (row['retakes_remaining'] as num?)?.toInt(),
      canRetake: row['can_retake'] as bool? ?? true,
      scoredAt: switch (row['scored_at']) {
        final String value => DateTime.tryParse(value)?.toUtc(),
        final DateTime value => value.toUtc(),
        _ => null,
      },
      items: items,
    );
  }

  final String attemptId;
  final String quizVersionId;
  final String topicVersionId;
  final int attemptNumber;
  final double scorePercent;
  final bool passed;
  final int correctCount;
  final int totalCount;
  final double passPercent;
  final String quizTitle;
  final String? quizTitleUr;
  final String topicTitle;
  final String? topicTitleUr;
  final int attemptsUsed;

  /// Retakes allowed beyond the first sitting; null means the quiz is uncapped.
  final int? maxRetakes;

  /// Sittings still available, or null when uncapped.
  final int? retakesRemaining;
  final bool canRetake;
  final DateTime? scoredAt;
  final List<AttemptReviewItem> items;

  String quizTitleFor(NanoAppLocale locale) =>
      locale == NanoAppLocale.ur && (quizTitleUr?.isNotEmpty ?? false)
          ? quizTitleUr!
          : quizTitle;

  bool get isCapped => maxRetakes != null;

  /// Server-authored: the client never re-derives pass from the percent.
  bool get needsReview => !passed;

  Iterable<AttemptReviewItem> get missedItems =>
      items.where((item) => !item.wasCorrect);
}

/// One submitted attempt in the learner's history (QZ-06).
class QuizAttemptHistoryEntry {
  const QuizAttemptHistoryEntry({
    required this.attemptId,
    required this.topicVersionId,
    required this.quizVersionId,
    required this.attemptNumber,
    this.quizTitle = '',
    this.quizTitleUr,
    this.topicTitle = '',
    this.scorePercent,
    this.passed,
    this.submittedAt,
  });

  factory QuizAttemptHistoryEntry.fromRow(Map<String, dynamic> row) {
    return QuizAttemptHistoryEntry(
      attemptId: (row['attempt_id'] as String?) ?? '',
      topicVersionId: (row['topic_version_id'] as String?) ?? '',
      quizVersionId: (row['quiz_version_id'] as String?) ?? '',
      attemptNumber: (row['attempt_number'] as num?)?.toInt() ?? 1,
      quizTitle: (row['quiz_title'] as String?) ?? '',
      quizTitleUr: row['quiz_title_ur'] as String?,
      topicTitle: (row['topic_title'] as String?) ?? '',
      scorePercent: (row['score_percent'] as num?)?.toDouble(),
      passed: row['passed'] as bool?,
      submittedAt: switch (row['submitted_at']) {
        final String value => DateTime.tryParse(value)?.toUtc(),
        final DateTime value => value.toUtc(),
        _ => null,
      },
    );
  }

  final String attemptId;
  final String topicVersionId;
  final String quizVersionId;
  final int attemptNumber;
  final String quizTitle;
  final String? quizTitleUr;
  final String topicTitle;
  final double? scorePercent;
  final bool? passed;
  final DateTime? submittedAt;

  bool get isScored => scorePercent != null;
}
