/// GME-02 game session + bridge protocol models.

import 'game_catalog.dart';

enum GameSessionStatus {
  active,
  completed,
  aborted,
  expired;

  static GameSessionStatus parse(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'completed':
        return GameSessionStatus.completed;
      case 'aborted':
        return GameSessionStatus.aborted;
      case 'expired':
        return GameSessionStatus.expired;
      case 'active':
      default:
        return GameSessionStatus.active;
    }
  }

  String get wire => name;
}

/// One-time start payload from `start_game_session`.
class GameSessionStart {
  const GameSessionStart({
    required this.sessionId,
    required this.playToken,
    required this.gameVersionId,
    required this.slug,
    required this.titleEn,
    required this.entryKind,
    required this.entryRef,
    required this.allowedOrigins,
    required this.expiresAt,
    this.gameId = '',
    this.version = 1,
    this.titleUr = '',
    this.localeHint = 'en',
  });

  final String sessionId;
  final String playToken;
  final String gameVersionId;
  final String gameId;
  final String slug;
  final int version;
  final String titleEn;
  final String titleUr;
  final GameEntryKind entryKind;
  final String entryRef;
  final List<String> allowedOrigins;
  final DateTime expiresAt;
  final String localeHint;

  String titleFor(bool urdu) =>
      urdu && titleUr.trim().isNotEmpty ? titleUr : titleEn;

  bool get isFixture => entryRef.startsWith('fixture://');

  factory GameSessionStart.fromJson(Map<String, dynamic> json) {
    final origins = json['allowed_origins'];
    return GameSessionStart(
      sessionId: json['session_id'] as String? ?? '',
      playToken: json['play_token'] as String? ?? '',
      gameVersionId: json['game_version_id'] as String? ?? '',
      gameId: json['game_id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      version: (json['version'] as num?)?.toInt() ?? 1,
      titleEn: json['title_en'] as String? ?? '',
      titleUr: json['title_ur'] as String? ?? '',
      entryKind: GameEntryKind.parse(json['entry_kind'] as String?),
      entryRef: json['entry_ref'] as String? ?? '',
      allowedOrigins: [
        if (origins is List)
          for (final o in origins)
            if (o != null) '$o',
      ],
      expiresAt: DateTime.tryParse('${json['expires_at']}') ??
          DateTime.now().toUtc().add(const Duration(minutes: 30)),
      localeHint: json['locale_hint'] as String? ?? 'en',
    );
  }
}

class GameClientCompletionResult {
  const GameClientCompletionResult({
    required this.sessionId,
    required this.status,
    required this.verified,
    required this.message,
    this.verifiedScore,
    this.xpAwarded = 0,
  });

  final String sessionId;
  final GameSessionStatus status;
  final bool verified;
  final String message;
  final int? verifiedScore;
  final int xpAwarded;

  factory GameClientCompletionResult.fromJson(Map<String, dynamic> json) {
    return GameClientCompletionResult(
      sessionId: json['session_id'] as String? ?? '',
      status: GameSessionStatus.parse(json['status'] as String?),
      verified: json['verified'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      verifiedScore: (json['verified_score'] as num?)?.toInt(),
      xpAwarded: (json['xp_awarded'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Thrown when start/play is blocked by eligibility or kill switch (NS143).
class GameSessionBlocked implements Exception {
  const GameSessionBlocked({
    required this.code,
    this.message = 'Game version is not eligible to play.',
  });

  final String code;
  final String message;

  bool get isVersionDisabled =>
      code == 'NS143' ||
      code == 'version_disabled' ||
      code == 'version_ineligible';

  @override
  String toString() => 'GameSessionBlocked($code): $message';
}

/// Learner poll payload from `get_game_session_play_status`.
class GameSessionPlayStatus {
  const GameSessionPlayStatus({
    required this.sessionId,
    required this.status,
    required this.versionEligible,
    required this.killSwitch,
  });

  final String sessionId;
  final GameSessionStatus status;
  final bool versionEligible;
  final bool killSwitch;

  factory GameSessionPlayStatus.fromJson(Map<String, dynamic> json) {
    return GameSessionPlayStatus(
      sessionId: json['session_id'] as String? ?? '',
      status: GameSessionStatus.parse(json['status'] as String?),
      versionEligible: json['version_eligible'] as bool? ?? true,
      killSwitch: json['kill_switch'] as bool? ?? false,
    );
  }
}

/// Handbook §11.2 Game -> Nano messages.
enum GameBridgeInboundKind {
  ready,
  progress,
  completed,
  error,
  unknown;

  static GameBridgeInboundKind parse(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'ready':
        return GameBridgeInboundKind.ready;
      case 'progress':
        return GameBridgeInboundKind.progress;
      case 'completed':
        return GameBridgeInboundKind.completed;
      case 'error':
        return GameBridgeInboundKind.error;
      default:
        return GameBridgeInboundKind.unknown;
    }
  }
}

class GameBridgeMessage {
  const GameBridgeMessage({
    required this.kind,
    this.payload = const {},
  });

  final GameBridgeInboundKind kind;
  final Map<String, dynamic> payload;

  static const maxPayloadChars = 8192;

  /// Parse + reject unknown types / oversized envelopes.
  static GameBridgeMessage? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final encoded = map.toString();
    if (encoded.length > maxPayloadChars) return null;
    final kind = GameBridgeInboundKind.parse(map['type'] as String?);
    if (kind == GameBridgeInboundKind.unknown) return null;
    final payload = map['payload'];
    return GameBridgeMessage(
      kind: kind,
      payload: payload is Map
          ? Map<String, dynamic>.from(payload)
          : <String, dynamic>{
              for (final e in map.entries)
                if (e.key != 'type') e.key: e.value,
            },
    );
  }
}

/// Handbook §11.3 origin allowlist.
abstract final class GameOriginPolicy {
  static List<String> originsForEntryRef(String entryRef) {
    final ref = entryRef.trim();
    if (ref.startsWith('fixture://')) return [ref];
    final uri = Uri.tryParse(ref);
    if (uri == null || uri.scheme.toLowerCase() != 'https') return const [];
    if (uri.host.isEmpty) return const [];
    return ['https://${uri.host.toLowerCase()}'];
  }

  static bool allowsNavigation({
    required List<String> allowedOrigins,
    required String url,
  }) {
    final candidate = url.trim();
    if (candidate.isEmpty) return false;
    for (final origin in allowedOrigins) {
      if (origin.startsWith('fixture://')) {
        if (candidate == origin || candidate.startsWith('$origin/')) {
          return true;
        }
        continue;
      }
      if (candidate == origin || candidate.startsWith('$origin/')) {
        return true;
      }
      final allowed = Uri.tryParse(origin);
      final nav = Uri.tryParse(candidate);
      if (allowed == null || nav == null) continue;
      if (allowed.scheme.toLowerCase() == 'https' &&
          nav.scheme.toLowerCase() == 'https' &&
          allowed.host.toLowerCase() == nav.host.toLowerCase()) {
        return true;
      }
    }
    return false;
  }
}
