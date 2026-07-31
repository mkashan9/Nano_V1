import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// Opens a topic, reports player position, and asks the server to complete it.
///
/// The client reports *where the player head is*, never how much was watched:
/// credit and completion are decided by `record_playback_heartbeat` and
/// `complete_topic`.
abstract class LearningProgressRepository {
  Future<TopicProgress> start(String topicVersionId);

  Future<TopicProgress> heartbeat({
    required String topicVersionId,
    required int positionSeconds,
  });

  Future<TopicProgress> complete(String topicVersionId);
}

/// In-memory store that mirrors the server rules for UI-first work.
class FakeLearningProgressRepository implements LearningProgressRepository {
  FakeLearningProgressRepository({
    this.userId = 'u1',
    Set<String>? lockedVersionIds,
    Set<String>? unavailableVersionIds,
    this.alwaysFail = false,
    this.durationSeconds = 120,
    this.completionThreshold = 0.9,
    this.creditPerBeat = 15,
  })  : lockedVersionIds =
            lockedVersionIds ?? {'tv-addition-1', 'tv-plants-1'},
        unavailableVersionIds =
            unavailableVersionIds ?? {'tv-first-loop-1'};

  final String userId;
  final Set<String> lockedVersionIds;
  final Set<String> unavailableVersionIds;
  final bool alwaysFail;
  final int durationSeconds;
  final double completionThreshold;

  /// Watch seconds a heartbeat is allowed to earn, standing in for the
  /// server's wall-clock accounting.
  final int creditPerBeat;

  final Map<String, TopicProgress> rows = {};
  final List<String> started = [];
  final List<int> positions = [];
  final List<String> completed = [];

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
      watchedSeconds: existing?.watchedSeconds ?? 0,
    );
    rows[topicVersionId] = next;
    return next;
  }

  @override
  Future<TopicProgress> heartbeat({
    required String topicVersionId,
    required int positionSeconds,
  }) async {
    _guard(topicVersionId);
    positions.add(positionSeconds);
    final existing = rows[topicVersionId];
    final position =
        positionSeconds.clamp(0, durationSeconds).toInt();
    if (existing == null) {
      final seeded = TopicProgress(
        userId: userId,
        topicVersionId: topicVersionId,
        status: TopicProgressStatus.inProgress,
        progress: 0,
        resumeSeconds: position,
        watchedSeconds: 0,
      );
      rows[topicVersionId] = seeded;
      return seeded;
    }
    final advanced = position - existing.resumeSeconds;
    final credit = PlaybackPolicy.creditFor(
      positionDelta: advanced,
      elapsedSeconds: creditPerBeat,
    );
    final watched =
        (existing.watchedSeconds + credit).clamp(0, durationSeconds).toInt();
    final next = TopicProgress(
      userId: userId,
      topicVersionId: topicVersionId,
      status: existing.isCompleted
          ? TopicProgressStatus.completed
          : TopicProgressStatus.inProgress,
      progress: watched / durationSeconds,
      resumeSeconds: position,
      watchedSeconds: watched,
      completedAt: existing.completedAt,
    );
    rows[topicVersionId] = next;
    return next;
  }

  @override
  Future<TopicProgress> complete(String topicVersionId) async {
    _guard(topicVersionId);
    final existing = rows[topicVersionId];
    if (existing != null && existing.isCompleted) return existing;
    final watched = existing?.watchedSeconds ?? 0;
    if (!PlaybackPolicy.canComplete(
      watchedSeconds: watched,
      durationSeconds: durationSeconds,
      threshold: completionThreshold,
    )) {
      final required = PlaybackPolicy.requiredSeconds(
        durationSeconds: durationSeconds,
        threshold: completionThreshold,
      );
      throw TopicGateException(
        reason: TopicGateReason.notWatchedEnough,
        message: 'Keep watching: $watched of $required seconds credited',
        code: 'NL005',
      );
    }
    completed.add(topicVersionId);
    final next = TopicProgress(
      userId: userId,
      topicVersionId: topicVersionId,
      status: TopicProgressStatus.completed,
      progress: 1,
      resumeSeconds: existing?.resumeSeconds ?? 0,
      watchedSeconds: watched,
      completedAt: DateTime.now().toUtc(),
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

  /// Seeds credited watch time, standing in for a learner who already watched.
  void seedWatched(String topicVersionId, int watchedSeconds) {
    final existing = rows[topicVersionId];
    rows[topicVersionId] = TopicProgress(
      userId: userId,
      topicVersionId: topicVersionId,
      status: existing?.status ?? TopicProgressStatus.inProgress,
      progress: watchedSeconds / durationSeconds,
      resumeSeconds: existing?.resumeSeconds ?? watchedSeconds,
      watchedSeconds: watchedSeconds,
      completedAt: existing?.completedAt,
    );
  }

  /// After the prerequisite is finished, unlock the next topic.
  void unlock(String topicVersionId) {
    lockedVersionIds.remove(topicVersionId);
  }
}

class SupabaseLearningProgressRepository
    implements LearningProgressRepository {
  SupabaseLearningProgressRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<TopicProgress> start(String topicVersionId) => _call(
        'start_topic',
        {'p_topic_version_id': topicVersionId},
      );

  @override
  Future<TopicProgress> heartbeat({
    required String topicVersionId,
    required int positionSeconds,
  }) =>
      _call('record_playback_heartbeat', {
        'p_topic_version_id': topicVersionId,
        'p_position_seconds': positionSeconds,
      });

  @override
  Future<TopicProgress> complete(String topicVersionId) => _call(
        'complete_topic',
        {'p_topic_version_id': topicVersionId},
      );

  Future<TopicProgress> _call(
    String function,
    Map<String, dynamic> params,
  ) async {
    try {
      final row = await _client.rpc(function, params: params);
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
      TopicGateReason.locked => _match(message, r'Finish .+ first') ?? message,
      TopicGateReason.unavailable => 'This topic is not available.',
      TopicGateReason.notLearner =>
        'Only learners can save learning progress.',
      TopicGateReason.notWatchedEnough =>
        _match(message, r'Keep watching[^"\\]*') ?? 'Keep watching.',
      TopicGateReason.unknown => "Couldn't start. Try again.",
    };
    return TopicGateException(reason: reason, message: friendly, code: code);
  }

  String? _codeFrom(String message) {
    for (final code in const ['NL001', 'NL002', 'NL003', 'NL004', 'NL005']) {
      if (message.contains(code)) return code;
    }
    if (message.contains('Finish ') && message.contains(' first')) {
      return 'NL001';
    }
    if (message.contains('Keep watching')) return 'NL005';
    if (message.contains('not available')) return 'NL002';
    if (message.contains('Only an active learner')) return 'NL003';
    return null;
  }

  String? _match(String message, String pattern) =>
      RegExp(pattern).firstMatch(message)?.group(0);
}
