import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// Opens a topic and records heartbeat progress. Completion is out of scope:
/// video and quiz modules write that status on the server.
abstract class LearningProgressRepository {
  Future<TopicProgress> start(String topicVersionId);

  Future<TopicProgress> saveProgress({
    required String topicVersionId,
    required int resumeSeconds,
    required double progress,
  });
}

/// In-memory progress store that mirrors the server gates for UI-first work.
class FakeLearningProgressRepository implements LearningProgressRepository {
  FakeLearningProgressRepository({
    this.userId = 'u1',
    Set<String>? lockedVersionIds,
    Set<String>? unavailableVersionIds,
    this.alwaysFail = false,
  })  : lockedVersionIds =
            lockedVersionIds ?? {'tv-addition-1', 'tv-plants-1'},
        unavailableVersionIds =
            unavailableVersionIds ?? {'tv-first-loop-1'};

  final String userId;
  final Set<String> lockedVersionIds;
  final Set<String> unavailableVersionIds;
  final bool alwaysFail;
  final Map<String, TopicProgress> rows = {};
  final List<String> started = [];
  final List<String> saved = [];

  @override
  Future<TopicProgress> start(String topicVersionId) async {
    _guard(topicVersionId);
    started.add(topicVersionId);
    final existing = rows[topicVersionId];
    if (existing != null && existing.isCompleted) return existing;
    final next = TopicProgress(
      userId: userId,
      topicVersionId: topicVersionId,
      status: TopicProgressStatus.inProgress,
      progress: existing?.progress ?? 0,
      resumeSeconds: existing?.resumeSeconds ?? 0,
    );
    rows[topicVersionId] = next;
    return next;
  }

  @override
  Future<TopicProgress> saveProgress({
    required String topicVersionId,
    required int resumeSeconds,
    required double progress,
  }) async {
    _guard(topicVersionId);
    saved.add(topicVersionId);
    final existing = rows[topicVersionId];
    if (existing != null && existing.isCompleted) return existing;
    final clamped = progress.clamp(0.0, 1.0);
    final next = TopicProgress(
      userId: userId,
      topicVersionId: topicVersionId,
      status: TopicProgressStatus.inProgress,
      progress: existing == null
          ? clamped
          : (existing.progress > clamped ? existing.progress : clamped),
      resumeSeconds: resumeSeconds < 0 ? 0 : resumeSeconds,
    );
    rows[topicVersionId] = next;
    return next;
  }

  void _guard(String topicVersionId) {
    if (alwaysFail) {
      throw const TopicGateException(
        reason: TopicGateReason.unknown,
        message: "Couldn't start. Try again.",
      );
    }
    if (unavailableVersionIds.contains(topicVersionId)) {
      throw const TopicGateException(
        reason: TopicGateReason.unavailable,
        message: 'This topic is not available.',
        code: 'NL002',
      );
    }
    if (lockedVersionIds.contains(topicVersionId)) {
      throw const TopicGateException(
        reason: TopicGateReason.locked,
        message: 'Finish Counting to 20 first',
        code: 'NL001',
      );
    }
  }

  /// After Counting is marked completed locally, unlock Addition.
  void unlock(String topicVersionId) {
    lockedVersionIds.remove(topicVersionId);
  }
}

class SupabaseLearningProgressRepository
    implements LearningProgressRepository {
  SupabaseLearningProgressRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<TopicProgress> start(String topicVersionId) async {
    try {
      final row = await _client.rpc(
        'start_topic',
        params: {'p_topic_version_id': topicVersionId},
      );
      return TopicProgress.fromRow(Map<String, dynamic>.from(row as Map));
    } catch (error) {
      throw _map(error);
    }
  }

  @override
  Future<TopicProgress> saveProgress({
    required String topicVersionId,
    required int resumeSeconds,
    required double progress,
  }) async {
    try {
      final row = await _client.rpc(
        'save_topic_progress',
        params: {
          'p_topic_version_id': topicVersionId,
          'p_resume_seconds': resumeSeconds,
          'p_progress': progress,
        },
      );
      return TopicProgress.fromRow(Map<String, dynamic>.from(row as Map));
    } catch (error) {
      throw _map(error);
    }
  }

  Exception _map(Object error) {
    if (error is TopicGateException) return error;
    final message = error.toString();
    final code = _codeFrom(message);
    final reason = TopicGateReason.fromCode(code);
    final friendly = switch (reason) {
      TopicGateReason.locked => _messageAfter(message) ?? message,
      TopicGateReason.unavailable => 'This topic is not available.',
      TopicGateReason.notLearner =>
        'Only learners can save learning progress.',
      TopicGateReason.unknown => "Couldn't start. Try again.",
    };
    return TopicGateException(reason: reason, message: friendly, code: code);
  }

  String? _codeFrom(String message) {
    for (final code in const ['NL001', 'NL002', 'NL003', 'NL004']) {
      if (message.contains(code)) return code;
    }
    if (message.contains('Finish ') && message.contains(' first')) {
      return 'NL001';
    }
    if (message.contains('not available')) return 'NL002';
    if (message.contains('Only an active learner')) return 'NL003';
    return null;
  }

  String? _messageAfter(String message) {
    final match = RegExp(r'Finish .+ first').firstMatch(message);
    return match?.group(0);
  }
}
