import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// GME-02 game session lifecycle (start / abort / client-completed).
abstract class GameSessionRepository {
  Future<GameSessionStart> startSession(String gameVersionId);

  Future<void> abortSession(String sessionId);

  Future<GameClientCompletionResult> reportClientCompleted({
    required String sessionId,
    required String playToken,
    Map<String, dynamic> payload = const {},
  });
}

class FakeGameSessionRepository implements GameSessionRepository {
  FakeGameSessionRepository({
    this.alwaysFail = false,
    GameSessionStart? seed,
  }) : _seed = seed;

  final bool alwaysFail;
  final GameSessionStart? _seed;
  final Map<String, GameSessionStart> _byId = {};

  @override
  Future<GameSessionStart> startSession(String gameVersionId) async {
    if (alwaysFail) throw StateError('Could not start game');
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
    return start;
  }

  @override
  Future<void> abortSession(String sessionId) async {
    _byId.remove(sessionId);
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
    return GameClientCompletionResult(
      sessionId: sessionId,
      status: GameSessionStatus.completed,
      verified: false,
      message: 'Result received. Verification comes later.',
    );
  }
}

class SupabaseGameSessionRepository implements GameSessionRepository {
  SupabaseGameSessionRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<GameSessionStart> startSession(String gameVersionId) async {
    final raw = await _client.rpc(
      'start_game_session',
      params: {'p_version_id': gameVersionId},
    );
    if (raw is! Map) throw StateError('Could not start game.');
    return GameSessionStart.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<void> abortSession(String sessionId) async {
    await _client.rpc(
      'abort_game_session',
      params: {'p_session_id': sessionId},
    );
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
