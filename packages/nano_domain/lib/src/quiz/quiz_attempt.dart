/// Server-authored outcome for a submitted quiz attempt (QZ-05).
class ScoreResult {
  const ScoreResult({
    required this.attemptId,
    required this.scorePercent,
    required this.passed,
    required this.correctCount,
    required this.totalCount,
    this.idempotent = false,
    this.scoredAt,
  });

  factory ScoreResult.fromRow(Map<String, dynamic> row) {
    return ScoreResult(
      attemptId: (row['attempt_id'] as String?) ?? '',
      scorePercent: (row['score_percent'] as num?)?.toDouble() ?? 0,
      passed: row['passed'] as bool? ?? false,
      correctCount: (row['correct_count'] as num?)?.toInt() ?? 0,
      totalCount: (row['total_count'] as num?)?.toInt() ?? 0,
      idempotent: row['idempotent'] as bool? ?? false,
      scoredAt: switch (row['scored_at']) {
        final String value => DateTime.tryParse(value)?.toUtc(),
        final DateTime value => value.toUtc(),
        _ => null,
      },
    );
  }

  final String attemptId;
  final double scorePercent;
  final bool passed;
  final int correctCount;
  final int totalCount;
  final bool idempotent;
  final DateTime? scoredAt;
}

/// Open or resumed attempt with saved selections (no correctness).
class QuizAttemptSession {
  const QuizAttemptSession({
    required this.attemptId,
    required this.quizVersionId,
    required this.topicVersionId,
    required this.attemptNumber,
    this.resumed = false,
    this.answers = const {},
  });

  factory QuizAttemptSession.fromRow(Map<String, dynamic> row) {
    final answers = <String, String>{};
    final raw = row['answers'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          final qid = item['question_version_id'] as String?;
          final oid = item['selected_option_id'] as String?;
          if (qid != null && oid != null) answers[qid] = oid;
        }
      }
    }
    return QuizAttemptSession(
      attemptId: (row['attempt_id'] as String?) ?? '',
      quizVersionId: (row['quiz_version_id'] as String?) ?? '',
      topicVersionId: (row['topic_version_id'] as String?) ?? '',
      attemptNumber: (row['attempt_number'] as num?)?.toInt() ?? 1,
      resumed: row['resumed'] as bool? ?? false,
      answers: answers,
    );
  }

  final String attemptId;
  final String quizVersionId;
  final String topicVersionId;
  final int attemptNumber;
  final bool resumed;
  final Map<String, String> answers;
}
