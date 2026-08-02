import 'package:flutter/material.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:nano_games/src/game_bridge_controller.dart';
import 'package:nano_games/src/game_feedback.dart';

/// In-app fixture surface for `fixture://` games (no remote WebView).
class FixtureGameSurface extends StatefulWidget {
  const FixtureGameSurface({
    super.key,
    required this.bridge,
    this.feedback,
    this.autoReady = true,
  });

  final GameBridgeController bridge;
  final GameFeedbackSink? feedback;
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

  Future<void> _tap() async {
    if (!_started) {
      _started = true;
      _startedAt = DateTime.now().toUtc();
    }
    setState(() => _score += 1);
    widget.bridge.handleInbound({
      'type': 'progress',
      'payload': {'checkpoint': _score},
    });
    await widget.feedback?.tick();
  }

  Future<void> _finish() async {
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
    await widget.feedback?.success();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quiet = widget.bridge.settings.classroomMode ||
        !widget.bridge.settings.effectiveSoundEnabled;
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.bridge.session.titleEn,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              quiet
                  ? 'Fixture host · quiet · score $_score'
                  : 'Fixture host · score $_score',
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

bool canUseFixtureSurface(GameSessionStart session) =>
    session.entryKind == GameEntryKind.web &&
    session.isFixture &&
    GameOriginPolicy.allowsNavigation(
      allowedOrigins: session.allowedOrigins,
      url: session.entryRef,
    );
