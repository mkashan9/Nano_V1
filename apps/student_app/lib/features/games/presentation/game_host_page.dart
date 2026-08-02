import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:nano_games/nano_games.dart';
import 'package:student_app/features/games/presentation/nano_game_feedback_sink.dart';

/// GME-02/03/06 secure game host with accessibility-aware feedback.
class GameHostPage extends StatefulWidget {
  const GameHostPage({
    super.key,
    required this.game,
    required this.sessionRepository,
    this.accessibility = AccessibilityPreferences.defaults,
    this.onAccessibilityChanged,
    this.feedback,
    this.localeHint = 'en',
  });

  final CatalogGame game;
  final GameSessionRepository sessionRepository;
  final AccessibilityPreferences accessibility;
  final ValueChanged<AccessibilityPreferences>? onAccessibilityChanged;
  final NanoFeedback? feedback;
  final String localeHint;

  @override
  State<GameHostPage> createState() => _GameHostPageState();
}

class _GameHostPageState extends State<GameHostPage> {
  NanoViewState _state = const NanoViewLoading();
  GameSessionStart? _session;
  GameBridgeController? _bridge;
  GameFeedbackSink? _feedbackSink;
  late AccessibilityPreferences _a11y;
  String? _banner;
  var _finishing = false;

  @override
  void initState() {
    super.initState();
    _a11y = widget.accessibility;
    _start();
  }

  GamePlaySettings get _settings => GamePlaySettings.fromAccessibility(_a11y);

  Future<void> _start() async {
    setState(() {
      _state = const NanoViewLoading();
      _banner = null;
    });
    const fallbackCopy = NanoCopy(NanoAppLocale.en);
    try {
      final kind = widget.game.entryKind;
      if (kind != GameEntryKind.web && kind != GameEntryKind.flutter) {
        setState(() {
          _state = NanoViewError(message: fallbackCopy.gamesStartError);
        });
        return;
      }
      final session =
          await widget.sessionRepository.startSession(widget.game.versionId);
      if (!mounted) return;
      final copy =
          NanoLocaleScope.maybeOf(context)?.copy ?? fallbackCopy;

      if (kind == GameEntryKind.web) {
        if (!session.isFixture) {
          setState(() {
            _state = NanoViewError(message: copy.gamesHttpsDeferred);
          });
          await widget.sessionRepository.abortSession(session.sessionId);
          return;
        }
        if (!canUseFixtureSurface(session)) {
          setState(() {
            _state = NanoViewError(message: copy.gamesStartError);
          });
          await widget.sessionRepository.abortSession(session.sessionId);
          return;
        }
      } else if (!canUseNativeFlutterSurface(session)) {
        setState(() {
          _state = NanoViewError(message: copy.gamesStartError);
        });
        await widget.sessionRepository.abortSession(session.sessionId);
        return;
      }

      final settings = _settings;
      final feedback = widget.feedback ?? NanoFeedback(preferences: _a11y);
      feedback.updatePreferences(_a11y);
      final bridge = GameBridgeController(
        session: session,
        settings: settings,
        onMessage: _onBridgeMessage,
        onUnknownOrOversized: () {
          if (!mounted) return;
          final live =
              NanoLocaleScope.maybeOf(context)?.copy ?? fallbackCopy;
          setState(() => _banner = live.gamesBridgeRejected);
        },
      );
      setState(() {
        _session = session;
        _bridge = bridge;
        _feedbackSink = NanoGameFeedbackSink(feedback);
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      final copy =
          NanoLocaleScope.maybeOf(context)?.copy ?? fallbackCopy;
      setState(() => _state = NanoViewError(message: copy.gamesStartError));
    }
  }

  void _toggleClassroom(bool enabled) {
    final next = _a11y.copyWith(classroomMode: enabled);
    setState(() {
      _a11y = next;
      _bridge?.settings = GamePlaySettings.fromAccessibility(next);
      widget.feedback?.updatePreferences(next);
    });
    widget.onAccessibilityChanged?.call(next);
  }

  Future<void> _onBridgeMessage(GameBridgeMessage message) async {
    if (message.kind != GameBridgeInboundKind.completed || _finishing) return;
    final session = _session;
    if (session == null) return;
    _finishing = true;
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    try {
      final result = await widget.sessionRepository.reportClientCompleted(
        sessionId: session.sessionId,
        playToken: session.playToken,
        payload: message.payload,
      );
      if (!mounted) return;
      final banner = result.message.isNotEmpty
          ? result.message
          : result.verified
              ? (result.xpAwarded > 0
                  ? copy.gamesResultVerifiedXp(result.xpAwarded)
                  : copy.gamesResultVerified)
              : copy.gamesResultRejected;
      setState(() => _banner = banner);
    } catch (_) {
      if (!mounted) return;
      setState(() => _banner = copy.gamesStartError);
    }
  }

  Future<void> _close() async {
    final session = _session;
    if (session != null && _banner == null) {
      try {
        await widget.sessionRepository.abortSession(session.sessionId);
      } catch (_) {}
    }
    if (mounted) Navigator.of(context).maybePop();
  }

  Widget _surface(GameBridgeController bridge) {
    if (bridge.session.entryKind == GameEntryKind.flutter) {
      return NativeShapeSortSurface(
        bridge: bridge,
        feedback: _feedbackSink,
      );
    }
    return FixtureGameSurface(
      bridge: bridge,
      feedback: _feedbackSink,
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final bridge = _bridge;
    final settings = _settings;
    return NanoScaffold(
      padBody: true,
      body: NanoViewStateHost(
        state: _state,
        onRetry: _start,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.game.titleFor(copy.isUrdu),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(onPressed: _close, child: Text(copy.gamesClose)),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(copy.gamesClassroomMode),
              subtitle: Text(
                settings.classroomMode
                    ? copy.gamesClassroomOnHint
                    : copy.gamesClassroomOffHint,
              ),
              value: settings.classroomMode,
              onChanged: _toggleClassroom,
            ),
            if (_banner != null) ...[
              const SizedBox(height: NanoSpacing.sm),
              Text(_banner!, style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: NanoSpacing.md),
            if (bridge != null) Expanded(child: _surface(bridge)),
          ],
        ),
      ),
    );
  }
}
