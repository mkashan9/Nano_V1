import 'package:flutter/material.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:nano_games/src/game_bridge_controller.dart';

/// In-app fixture surface for `fixture://` games (no remote WebView).
///
/// Posts the handbook bridge messages through [GameBridgeController].
class FixtureGameSurface extends StatefulWidget {
  const FixtureGameSurface({
    super.key,
    required this.bridge,
    this.autoReady = true,
  });

  final GameBridgeController bridge;
  final bool autoReady;

  @override
  State<FixtureGameSurface> createState() => _FixtureGameSurfaceState();
}

class _FixtureGameSurfaceState extends State<FixtureGameSurface> {
  var _score = 0;
  var _started = false;
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    if (widget.autoReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.bridge.handleInbound({'type': 'ready'});
      });
    }
  }

  void _tap() {
    if (!_started) {
      _started = true;
      _startedAt = DateTime.now().toUtc();
    }
    setState(() => _score += 1);
    widget.bridge.handleInbound({
      'type': 'progress',
      'payload': {'checkpoint': _score},
    });
  }

  void _finish() {
    final started = _startedAt ?? DateTime.now().toUtc();
    final duration =
        DateTime.now().toUtc().difference(started).inMilliseconds;
    widget.bridge.handleInbound({
      'type': 'completed',
      'payload': {
        'session_id': widget.bridge.session.sessionId,
        'raw_score': _score,
        'duration_ms': duration,
        'metrics': {'taps': _score},
        'nonce': 'fixture-${widget.bridge.session.sessionId}-$_score',
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.bridge.session.titleEn;
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Fixture host · score $_score',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _tap,
              child: const Text('Tap to score'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _score > 0 ? _finish : null,
              child: const Text('Finish'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Resolves whether a session can use the fixture surface.
bool canUseFixtureSurface(GameSessionStart session) =>
    session.entryKind == GameEntryKind.web &&
    session.isFixture &&
    GameOriginPolicy.allowsNavigation(
      allowedOrigins: session.allowedOrigins,
      url: session.entryRef,
    );
