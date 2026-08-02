import 'package:nano_domain/nano_domain.dart';

/// Narrow typed bridge between host and game surface.
class GameBridgeController {
  GameBridgeController({
    required this.session,
    this.settings = GamePlaySettings.defaults,
    void Function(GameBridgeMessage message)? onMessage,
    this.onUnknownOrOversized,
  }) : _onMessage = onMessage;

  final GameSessionStart session;
  GamePlaySettings settings;
  final void Function(GameBridgeMessage message)? _onMessage;
  final void Function()? onUnknownOrOversized;

  var ready = false;
  GameBridgeMessage? lastCompleted;
  GameBridgeMessage? lastError;

  /// Host → game: session_started envelope (never includes Supabase tokens).
  Map<String, dynamic> sessionStartedEnvelope({String locale = 'en'}) {
    return {
      'type': 'session_started',
      'payload': {
        'session_id': session.sessionId,
        'game_version': session.version,
        'signed_token': session.playToken,
        'locale': locale,
        'settings': settings.toBridgeJson(),
      },
    };
  }

  Map<String, dynamic> hostCommand(String type) {
    assert(type == 'pause' || type == 'resume' || type == 'terminate');
    return {'type': type};
  }

  /// Game → host. Returns false when rejected.
  bool handleInbound(Object? raw) {
    final message = GameBridgeMessage.tryParse(raw);
    if (message == null) {
      onUnknownOrOversized?.call();
      return false;
    }
    switch (message.kind) {
      case GameBridgeInboundKind.ready:
        ready = true;
      case GameBridgeInboundKind.completed:
        lastCompleted = message;
      case GameBridgeInboundKind.error:
        lastError = message;
      case GameBridgeInboundKind.progress:
      case GameBridgeInboundKind.unknown:
        break;
    }
    _onMessage?.call(message);
    return true;
  }
}
