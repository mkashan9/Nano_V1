import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// GME-02/05/07 game session lifecycle (start / abort / status / complete).
abstract class GameSessionRepository {
  Future<GameSessionStart> startSession(String gameVersionId);

  Future<void> abortSession(String sessionId);

  Future<GameSessionPlayStatus> getPlayStatus(String sessionId);

  Future<GameClientCompletionResult> reportClientCompleted({
    required String sessionId,
    required String playToken,
    Map<String, dynamic> payload = const {},
  });
}

class FakeGameSessionRepository implements GameSessionRepository {
  FakeGameSessionRepository({
    this.alwaysFail = false,
    Set<String>? disabledVersionIds,
    GameSessionStart? seed,
  })  : disabledVersionIds = disabledVersionIds ?? {},
        _seed = seed;

  final bool alwaysFail;
  final Set<String> disabledVersionIds;
  final GameSessionStart? _seed;
  final Map<String, GameSessionStart> _byId = {};
  final Map<String, GameSessionStatus> _status = {};

  /// Test helper: mark active sessions aborted (simulates admin kill switch).
  void forceAbortActive() {
    for (final id in _byId.keys) {
      if (_status[id] == GameSessionStatus.active) {
        _status[id] = GameSessionStatus.aborted;
      }
    }
  }

  @override
  Future<GameSessionStart> startSession(String gameVersionId) async {
    if (alwaysFail) throw StateError('Could not start game');
    if (disabledVersionIds.contains(gameVersionId)) {
      throw const GameSessionBlocked(
        code: 'NS143',
        message: 'Game version is not eligible to play.',
      );
    }
    final flutter = gameVersionId.contains('shape');
    final start = _seed ??
        GameSessionStart(
          sessionId: 'sess-$gameVersionId',
          playToken: 'token-$gameVersionId-secret',
          gameVersionId: gameVersionId,
          slug: flutter ? 'shape_sort' : 'number_rush',
          titleEn: flutter ? 'Shape Sort' : 'Number Rush',
          entryKind: flutter ? GameEntryKind.flutter : GameEntryKind.web,
          entryRef:
              flutter ? 'fixture://shape_sort' : 'fixture://number_rush',
          allowedOrigins: [
            flutter ? 'fixture://shape_sort' : 'fixture://number_rush',
          ],
          expiresAt: DateTime.utc(2026, 8, 2, 13),
        );
    _byId[start.sessionId] = start;
    _status[start.sessionId] = GameSessionStatus.active;
    return start;
  }

  @override
  Future<void> abortSession(String sessionId) async {
    _status[sessionId] = GameSessionStatus.aborted;
    _byId.remove(sessionId);
  }

  @override
  Future<GameSessionPlayStatus> getPlayStatus(String sessionId) async {
    final start = _byId[sessionId];
    final status = _status[sessionId] ?? GameSessionStatus.aborted;
    final eligible = start != null &&
        !disabledVersionIds.contains(start.gameVersionId) &&
        status == GameSessionStatus.active;
    final kill = status == GameSessionStatus.aborted ||
        (start != null && disabledVersionIds.contains(start.gameVersionId));
    return GameSessionPlayStatus(
      sessionId: sessionId,
      status: status,
      versionEligible: eligible,
      killSwitch: kill,
    );
  }

  @override
  Future<GameClientCompletionResult> reportClientCompleted({
    required String sessionId,
    required String playToken,
    Map<String, dynamic> payload = const {},
  }) async {
    final start = _byId[sessionId];
    if (start == null || start.playToken != playToken) {
      throw StateError('Invalid session');
    }
    final status = _status[sessionId] ?? GameSessionStatus.active;
    if (status != GameSessionStatus.active) {
      return GameClientCompletionResult(
        sessionId: sessionId,
        status: status,
        verified: false,
        xpAwarded: 0,
        message: 'Session already closed.',
      );
    }
    if (disabledVersionIds.contains(start.gameVersionId)) {
      _status[sessionId] = GameSessionStatus.aborted;
      return GameClientCompletionResult(
        sessionId: sessionId,
        status: GameSessionStatus.aborted,
        verified: false,
        xpAwarded: 0,
        message: 'Result rejected.',
      );
    }
    final score = (payload['raw_score'] as num?)?.toInt() ?? -1;
    final duration = (payload['duration_ms'] as num?)?.toInt() ?? -1;
    final nonce = '${payload['nonce'] ?? ''}';
    final payloadSession = '${payload['session_id'] ?? ''}';
    if (payloadSession != sessionId ||
        nonce.length < 8 ||
        score < 0 ||
        score > 1000 ||
        duration < 0 ||
        duration > 1800000) {
      _status[sessionId] = GameSessionStatus.completed;
      return GameClientCompletionResult(
        sessionId: sessionId,
        status: GameSessionStatus.completed,
        verified: false,
        xpAwarded: 0,
        message: 'Result rejected.',
      );
    }
    _status[sessionId] = GameSessionStatus.completed;
    return GameClientCompletionResult(
      sessionId: sessionId,
      status: GameSessionStatus.completed,
      verified: true,
      verifiedScore: score,
      xpAwarded: 20,
      message: 'Result verified. XP awarded.',
    );
  }
}

class SupabaseGameSessionRepository implements GameSessionRepository {
  SupabaseGameSessionRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<GameSessionStart> startSession(String gameVersionId) async {
    try {
      final raw = await _client.rpc(
        'start_game_session',
        params: {'p_version_id': gameVersionId},
      );
      if (raw is! Map) throw StateError('Could not start game.');
      return GameSessionStart.fromJson(Map<String, dynamic>.from(raw));
    } on PostgrestException catch (error) {
      if (error.code == 'NS143') {
        throw GameSessionBlocked(
          code: error.code ?? 'NS143',
          message: error.message,
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> abortSession(String sessionId) async {
    await _client.rpc(
      'abort_game_session',
      params: {'p_session_id': sessionId},
    );
  }

  @override
  Future<GameSessionPlayStatus> getPlayStatus(String sessionId) async {
    final raw = await _client.rpc(
      'get_game_session_play_status',
      params: {'p_session_id': sessionId},
    );
    if (raw is! Map) throw StateError('Could not read play status.');
    return GameSessionPlayStatus.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<GameClientCompletionResult> reportClientCompleted({
    required String sessionId,
    required String playToken,
    Map<String, dynamic> payload = const {},
  }) async {
    final raw = await _client.rpc(
      'report_game_client_completed',
      params: {
        'p_session_id': sessionId,
        'p_play_token': playToken,
        'p_payload': payload,
      },
    );
    if (raw is! Map) throw StateError('Could not report completion.');
    return GameClientCompletionResult.fromJson(Map<String, dynamic>.from(raw));
  }
}
