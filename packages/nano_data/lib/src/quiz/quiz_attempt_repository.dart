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
}

class FakeQuizAttemptRepository implements QuizAttemptRepository {
  FakeQuizAttemptRepository({
    this.alwaysFail = false,
    this.passPercent = 70,
    Map<String, String>? answerKey,
    LearnerQuizRepository? quizzes,
  })  : _answerKey = answerKey ?? _defaultKey,
        _quizzes = quizzes ?? FakeLearnerQuizRepository();

  final bool alwaysFail;
  final double passPercent;
  final Map<String, String> _answerKey;
  final LearnerQuizRepository _quizzes;

  final Map<String, _OpenAttempt> _open = {};
  final Map<String, ScoreResult> _scores = {};
  var startCount = 0;
  var saveCount = 0;
  var submitCount = 0;

  static const _defaultKey = {
    '51000000-0000-0000-0000-000000000001': 'b',
    '51000000-0000-0000-0000-000000000002': 'b',
    '51000000-0000-0000-0000-000000000003': 'yes',
  };

  @override
  Future<QuizAttemptSession> startOrResume(String topicVersionId) async {
    if (alwaysFail) throw StateError('Attempts unavailable');
    startCount++;
    final existing = _open[topicVersionId];
    if (existing != null && existing.status == 'in_progress') {
      return QuizAttemptSession(
        attemptId: existing.id,
        quizVersionId: existing.quizVersionId,
        topicVersionId: topicVersionId,
        attemptNumber: existing.attemptNumber,
        resumed: true,
        answers: Map.from(existing.answers),
      );
    }
    final quiz = await _quizzes.quizForTopic(topicVersionId);
    if (quiz == null) throw StateError('No published quiz for this topic.');
    final id = 'attempt-${startCount}';
    _open[topicVersionId] = _OpenAttempt(
      id: id,
      quizVersionId: quiz.id,
      topicVersionId: topicVersionId,
      attemptNumber: 1,
      answers: {},
    );
    return QuizAttemptSession(
      attemptId: id,
      quizVersionId: quiz.id,
      topicVersionId: topicVersionId,
      attemptNumber: 1,
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
    final open = _open.values.firstWhere(
      (item) => item.id == attemptId,
      orElse: () => throw StateError('Attempt not found'),
    );
    if (open.status != 'in_progress') {
      throw StateError('Submitted attempts cannot accept answers');
    }
    open.answers[questionVersionId] = selectedOptionId;
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
    final open = _open.values.firstWhere(
      (item) => item.id == attemptId,
      orElse: () => throw StateError('Attempt not found'),
    );
    final quiz = await _quizzes.quizForTopic(open.topicVersionId);
    if (quiz == null) throw StateError('Quiz missing');
    if (open.answers.length < quiz.items.length) {
      throw StateError('Answer every question before submitting');
    }
    var correct = 0;
    for (final item in quiz.items) {
      final selected = open.answers[item.questionVersionId];
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
    open.status = 'submitted';
    _scores[attemptId] = result;
    return result;
  }
}

class _OpenAttempt {
  _OpenAttempt({
    required this.id,
    required this.quizVersionId,
    required this.topicVersionId,
    required this.attemptNumber,
    required this.answers,
    this.status = 'in_progress',
  });

  final String id;
  final String quizVersionId;
  final String topicVersionId;
  final int attemptNumber;
  final Map<String, String> answers;
  String status;
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
}
