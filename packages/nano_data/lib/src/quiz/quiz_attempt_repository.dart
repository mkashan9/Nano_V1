import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

import 'learner_quiz_repository.dart';

/// Starts/resumes attempts, saves answers, and submits for server scoring.
abstract class QuizAttemptRepository {
  Future<QuizAttemptSession> startOrResume(String topicVersionId);

  Future<void> saveAnswer({
    required String attemptId,
    required String questionVersionId,
    required String selectedOptionId,
  });

  Future<ScoreResult> submit(String attemptId);

  /// Results with per-question review and explanations (QZ-06). Only a
  /// submitted attempt has a result; the server refuses the rest.
  Future<AttemptResult> result(String attemptId);

  /// Submitted attempts, newest first, optionally for one topic (QZ-06).
  Future<List<QuizAttemptHistoryEntry>> history({String? topicVersionId});
}

class FakeQuizAttemptRepository implements QuizAttemptRepository {
  FakeQuizAttemptRepository({
    this.alwaysFail = false,
    this.passPercent = 70,
    this.maxRetakes,
    Map<String, String>? answerKey,
    Map<String, String>? explanations,
    LearnerQuizRepository? quizzes,
  })  : _answerKey = answerKey ?? _defaultKey,
        _explanations = explanations ?? _defaultExplanations,
        _quizzes = quizzes ?? FakeLearnerQuizRepository();

  final bool alwaysFail;
  final double passPercent;

  /// Retakes beyond the first sitting; null matches an uncapped quiz policy.
  final int? maxRetakes;
  final Map<String, String> _answerKey;
  final Map<String, String> _explanations;
  final LearnerQuizRepository _quizzes;

  final List<_Attempt> _attempts = [];
  final Map<String, ScoreResult> _scores = {};
  var startCount = 0;
  var saveCount = 0;
  var submitCount = 0;

  static const _defaultKey = {
    '51000000-0000-0000-0000-000000000001': 'b',
    '51000000-0000-0000-0000-000000000002': 'b',
    '51000000-0000-0000-0000-000000000003': 'yes',
  };

  /// Explanations live with the answer key, not with the learner quiz, because
  /// the learner projection must not carry them before submit.
  static const _defaultExplanations = {
    '51000000-0000-0000-0000-000000000001':
        'Counting to five means there are five.',
    '51000000-0000-0000-0000-000000000002': 'Two plus three is five.',
    '51000000-0000-0000-0000-000000000003':
        'Living things need air to breathe.',
  };

  _Attempt _find(String attemptId) => _attempts.firstWhere(
        (item) => item.id == attemptId,
        orElse: () => throw StateError('Attempt not found'),
      );

  int _submittedCount(String topicVersionId) => _attempts
      .where(
        (item) =>
            item.topicVersionId == topicVersionId &&
            item.status == 'submitted',
      )
      .length;

  int? _retakesRemaining(String topicVersionId) => maxRetakes == null
      ? null
      : (maxRetakes! + 1 - _submittedCount(topicVersionId))
          .clamp(0, maxRetakes! + 1);

  @override
  Future<QuizAttemptSession> startOrResume(String topicVersionId) async {
    if (alwaysFail) throw StateError('Attempts unavailable');
    startCount++;
    for (final attempt in _attempts) {
      if (attempt.topicVersionId == topicVersionId &&
          attempt.status == 'in_progress') {
        return QuizAttemptSession(
          attemptId: attempt.id,
          quizVersionId: attempt.quizVersionId,
          topicVersionId: topicVersionId,
          attemptNumber: attempt.attemptNumber,
          resumed: true,
          answers: Map.from(attempt.answers),
        );
      }
    }
    final quiz = await _quizzes.quizForTopic(topicVersionId);
    if (quiz == null) throw StateError('No published quiz for this topic.');
    final submitted = _submittedCount(topicVersionId);
    if (maxRetakes != null && submitted > maxRetakes!) {
      throw StateError('No retakes remaining for this quiz.');
    }
    final attempt = _Attempt(
      id: 'attempt-$startCount',
      quizVersionId: quiz.id,
      topicVersionId: topicVersionId,
      quizTitle: quiz.title,
      quizTitleUr: quiz.titleUr,
      topicTitle: quiz.topicTitle,
      attemptNumber: submitted + 1,
      answers: {},
    );
    _attempts.add(attempt);
    return QuizAttemptSession(
      attemptId: attempt.id,
      quizVersionId: attempt.quizVersionId,
      topicVersionId: topicVersionId,
      attemptNumber: attempt.attemptNumber,
      resumed: false,
    );
  }

  @override
  Future<void> saveAnswer({
    required String attemptId,
    required String questionVersionId,
    required String selectedOptionId,
  }) async {
    if (alwaysFail) throw StateError('Attempts unavailable');
    saveCount++;
    final attempt = _find(attemptId);
    if (attempt.status != 'in_progress') {
      throw StateError('Submitted attempts cannot accept answers');
    }
    attempt.answers[questionVersionId] = selectedOptionId;
  }

  @override
  Future<ScoreResult> submit(String attemptId) async {
    if (alwaysFail) throw StateError('Attempts unavailable');
    final existing = _scores[attemptId];
    if (existing != null) {
      return ScoreResult(
        attemptId: existing.attemptId,
        scorePercent: existing.scorePercent,
        passed: existing.passed,
        correctCount: existing.correctCount,
        totalCount: existing.totalCount,
        idempotent: true,
        scoredAt: existing.scoredAt,
      );
    }
    submitCount++;
    final attempt = _find(attemptId);
    final quiz = await _quizzes.quizForTopic(attempt.topicVersionId);
    if (quiz == null) throw StateError('Quiz missing');
    if (attempt.answers.length < quiz.items.length) {
      throw StateError('Answer every question before submitting');
    }
    var correct = 0;
    for (final item in quiz.items) {
      final selected = attempt.answers[item.questionVersionId];
      if (selected != null && _answerKey[item.questionVersionId] == selected) {
        correct++;
      }
    }
    final total = quiz.items.length;
    final percent = (correct / total) * 100;
    final result = ScoreResult(
      attemptId: attemptId,
      scorePercent: double.parse(percent.toStringAsFixed(2)),
      passed: percent >= passPercent,
      correctCount: correct,
      totalCount: total,
      scoredAt: DateTime.now().toUtc(),
    );
    attempt.status = 'submitted';
    attempt.submittedAt = result.scoredAt;
    _scores[attemptId] = result;
    return result;
  }

  @override
  Future<AttemptResult> result(String attemptId) async {
    if (alwaysFail) throw StateError('Attempts unavailable');
    final attempt = _find(attemptId);
    final score = _scores[attemptId];
    if (score == null) {
      throw StateError('Results are available after the attempt is submitted.');
    }
    final quiz = await _quizzes.quizForTopic(attempt.topicVersionId);
    if (quiz == null) throw StateError('Quiz missing');
    final items = <AttemptReviewItem>[];
    for (final item in quiz.items) {
      final selected = attempt.answers[item.questionVersionId];
      final correctId = _answerKey[item.questionVersionId];
      items.add(
        AttemptReviewItem(
          sortOrder: item.sortOrder,
          questionVersionId: item.questionVersionId,
          stem: item.stem,
          stemUr: item.stemUr,
          kind: item.kind,
          options: item.options,
          selectedOptionId: selected,
          correctOptionId: correctId,
          wasCorrect: selected != null && selected == correctId,
          explanation: _explanations[item.questionVersionId] ?? '',
        ),
      );
    }
    final remaining = _retakesRemaining(attempt.topicVersionId);
    return AttemptResult(
      attemptId: attemptId,
      quizVersionId: attempt.quizVersionId,
      topicVersionId: attempt.topicVersionId,
      attemptNumber: attempt.attemptNumber,
      scorePercent: score.scorePercent,
      passed: score.passed,
      correctCount: score.correctCount,
      totalCount: score.totalCount,
      passPercent: passPercent,
      quizTitle: attempt.quizTitle,
      quizTitleUr: attempt.quizTitleUr,
      topicTitle: attempt.topicTitle,
      attemptsUsed: _submittedCount(attempt.topicVersionId),
      maxRetakes: maxRetakes,
      retakesRemaining: remaining,
      canRetake: remaining == null || remaining > 0,
      scoredAt: score.scoredAt,
      items: items,
    );
  }

  @override
  Future<List<QuizAttemptHistoryEntry>> history({
    String? topicVersionId,
  }) async {
    if (alwaysFail) throw StateError('Attempts unavailable');
    final entries = <QuizAttemptHistoryEntry>[];
    for (final attempt in _attempts) {
      if (attempt.status != 'submitted') continue;
      if (topicVersionId != null && attempt.topicVersionId != topicVersionId) {
        continue;
      }
      final score = _scores[attempt.id];
      entries.add(
        QuizAttemptHistoryEntry(
          attemptId: attempt.id,
          topicVersionId: attempt.topicVersionId,
          quizVersionId: attempt.quizVersionId,
          attemptNumber: attempt.attemptNumber,
          quizTitle: attempt.quizTitle,
          quizTitleUr: attempt.quizTitleUr,
          topicTitle: attempt.topicTitle,
          scorePercent: score?.scorePercent,
          passed: score?.passed,
          submittedAt: attempt.submittedAt,
        ),
      );
    }
    entries.sort((a, b) => b.attemptNumber.compareTo(a.attemptNumber));
    return entries;
  }
}

class _Attempt {
  _Attempt({
    required this.id,
    required this.quizVersionId,
    required this.topicVersionId,
    required this.attemptNumber,
    required this.answers,
    this.quizTitle = '',
    this.quizTitleUr,
    this.topicTitle = '',
  });

  final String id;
  final String quizVersionId;
  final String topicVersionId;
  final String quizTitle;
  final String? quizTitleUr;
  final String topicTitle;
  final int attemptNumber;
  final Map<String, String> answers;
  String status = 'in_progress';
  DateTime? submittedAt;
}

class SupabaseQuizAttemptRepository implements QuizAttemptRepository {
  SupabaseQuizAttemptRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<QuizAttemptSession> startOrResume(String topicVersionId) async {
    final result = await _client.rpc(
      'start_or_resume_quiz_attempt',
      params: {'p_topic_version_id': topicVersionId},
    );
    return QuizAttemptSession.fromRow(
      Map<String, dynamic>.from(result as Map),
    );
  }

  @override
  Future<void> saveAnswer({
    required String attemptId,
    required String questionVersionId,
    required String selectedOptionId,
  }) async {
    await _client.rpc(
      'save_attempt_answer',
      params: {
        'p_attempt_id': attemptId,
        'p_question_version_id': questionVersionId,
        'p_selected_option_id': selectedOptionId,
      },
    );
  }

  @override
  Future<ScoreResult> submit(String attemptId) async {
    final result = await _client.rpc(
      'submit_quiz_attempt',
      params: {'p_attempt_id': attemptId},
    );
    return ScoreResult.fromRow(Map<String, dynamic>.from(result as Map));
  }

  @override
  Future<AttemptResult> result(String attemptId) async {
    final result = await _client.rpc(
      'get_attempt_result',
      params: {'p_attempt_id': attemptId},
    );
    return AttemptResult.fromRow(Map<String, dynamic>.from(result as Map));
  }

  @override
  Future<List<QuizAttemptHistoryEntry>> history({
    String? topicVersionId,
  }) async {
    var query = _client.from('learner_quiz_history').select();
    if (topicVersionId != null) {
      query = query.eq('topic_version_id', topicVersionId);
    }
    final rows = await query
        .eq('status', 'submitted')
        .order('submitted_at', ascending: false);
    return [
      for (final row in rows as List)
        QuizAttemptHistoryEntry.fromRow(Map<String, dynamic>.from(row as Map)),
    ];
  }
}
