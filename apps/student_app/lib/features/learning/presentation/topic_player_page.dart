import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// LRN-03 player: resumes where the learner stopped, reports position to the
/// server on a heartbeat, shows captions, and only offers completion once the
/// server has credited enough watch time.
///
/// The video surface itself is a placeholder until MED-01 lands approved
/// provider playback; everything around it — accounting, resume, captions,
/// completion — is the real path.
class TopicPlayerPage extends StatefulWidget {
  const TopicPlayerPage({
    super.key,
    required this.topic,
    required this.progressRepository,
    this.junior = true,
    this.captionsEnabled,
    this.reducedMotion,
    this.tick = const Duration(seconds: 1),
    this.onProgress,
  });

  final CatalogTopic topic;
  final LearningProgressRepository progressRepository;
  final bool junior;

  /// Overrides for tests. Left null, both follow the learner's saved
  /// accessibility preferences.
  final bool? captionsEnabled;
  final bool? reducedMotion;

  /// Playback clock interval, shortened by tests.
  final Duration tick;
  final ValueChanged<CatalogTopic>? onProgress;

  @override
  State<TopicPlayerPage> createState() => _TopicPlayerPageState();
}

class _TopicPlayerPageState extends State<TopicPlayerPage> {
  late CatalogTopic _topic = widget.topic;
  late int _position = PlaybackPolicy.resumeFrom(
    resumeSeconds: widget.topic.resumeSeconds,
    durationSeconds: widget.topic.durationSeconds,
    isCompleted: widget.topic.isCompleted,
  );
  bool? _showCaptions;
  Timer? _clock;
  var _playing = false;
  var _busy = false;
  int _secondsSinceBeat = 0;
  String? _notice;

  AccessibilityPreferences get _a11y =>
      NanoAccessibilityScope.maybeOf(context)?.preferences ??
      AccessibilityPreferences.defaults;

  bool get _captionsOn =>
      _showCaptions ?? widget.captionsEnabled ?? _a11y.captionsEnabled;

  bool get _reducedMotion => widget.reducedMotion ?? _a11y.reducedMotion;

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _playing = !_playing;
      _notice = null;
    });
    if (_playing) {
      _clock = Timer.periodic(widget.tick, (_) => _advance());
    } else {
      _clock?.cancel();
      _clock = null;
      _sendHeartbeat();
    }
  }

  void _advance() {
    if (!mounted) return;
    final next = _position + 1;
    setState(() {
      _position = next >= _topic.durationSeconds ? _topic.durationSeconds : next;
      _secondsSinceBeat++;
    });
    if (_position >= _topic.durationSeconds) {
      _clock?.cancel();
      _clock = null;
      setState(() => _playing = false);
      _sendHeartbeat();
      return;
    }
    if (_secondsSinceBeat >= PlaybackPolicy.heartbeat.inSeconds) {
      _sendHeartbeat();
    }
  }

  Future<void> _sendHeartbeat() async {
    _secondsSinceBeat = 0;
    try {
      final row = await widget.progressRepository.heartbeat(
        topicVersionId: _topic.topicVersionId,
        positionSeconds: _position,
      );
      if (!mounted) return;
      setState(() => _topic = TopicActionPolicy.applyProgress(_topic, row));
      widget.onProgress?.call(_topic);
    } on TopicGateException catch (error) {
      if (!mounted) return;
      setState(() => _notice = error.message);
    } catch (_) {
      // A missed beat is not worth interrupting playback; the next one retries.
    }
  }

  Future<void> _complete() async {
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      final row = await widget.progressRepository.complete(
        _topic.topicVersionId,
      );
      if (!mounted) return;
      _clock?.cancel();
      _clock = null;
      setState(() {
        _topic = TopicActionPolicy.applyProgress(_topic, row);
        _playing = false;
        _busy = false;
      });
      widget.onProgress?.call(_topic);
    } on TopicGateException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _notice = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          NanoCopy(NanoAppLocale.en);
      setState(() {
        _busy = false;
        _notice = copy.topicSaveFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        NanoCopy(NanoAppLocale.en);
    final locale = NanoLocaleScope.maybeOf(context)?.locale ?? NanoAppLocale.en;
    final theme = Theme.of(context);
    final cue = _topic.captions.cueAt(_position);
    final canComplete = _topic.meetsCompletionThreshold && !_topic.isCompleted;

    return Scaffold(
      appBar: AppBar(title: Text(_topic.titleFor(locale))),
      body: NanoMaxContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            NanoSpacing.md,
            NanoSpacing.md,
            NanoSpacing.md,
            NanoSpacing.xxl,
          ),
          children: [
            _PlayerSurface(
              junior: widget.junior,
              playing: _playing && !_reducedMotion,
              hasVideo: _topic.hasVideo,
              copy: copy,
            ),
            const SizedBox(height: NanoSpacing.sm),
            Row(
              children: [
                IconButton(
                  onPressed: _topic.hasVideo ? _togglePlay : null,
                  icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                  tooltip: _playing ? copy.pauseLabel : copy.playLabel,
                ),
                Expanded(
                  child: Semantics(
                    label: copy.progressLabel,
                    value: PlaybackPolicy.clock(_position),
                    child: Slider(
                      value: _position
                          .clamp(0, _topic.durationSeconds)
                          .toDouble(),
                      max: _topic.durationSeconds.toDouble(),
                      onChanged: _topic.hasVideo
                          ? (value) => setState(() => _position = value.round())
                          : null,
                      onChangeEnd: (_) => _sendHeartbeat(),
                    ),
                  ),
                ),
                Text(
                  '${PlaybackPolicy.clock(_position)} / '
                  '${PlaybackPolicy.clock(_topic.durationSeconds)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${copy.watchedLabel}: '
                    '${PlaybackPolicy.clock(_topic.watchedSeconds)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(copy.captionsLabel, style: theme.textTheme.bodyMedium),
                Switch(
                  value: _captionsOn,
                  onChanged: (value) => setState(() => _showCaptions = value),
                ),
              ],
            ),
            if (_captionsOn) ...[
              const SizedBox(height: NanoSpacing.sm),
              Semantics(
                liveRegion: true,
                child: Text(
                  _topic.captions.isEmpty
                      ? copy.noCaptionsLabel
                      : cue?.textFor(locale) ?? '…',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
            const SizedBox(height: NanoSpacing.md),
            if (_topic.isCompleted)
              Text(copy.completedLabel, style: theme.textTheme.titleLarge)
            else
              Text(
                canComplete
                    ? copy.percentComplete(_topic.percentComplete)
                    : copy.keepWatchingHint(_topic.secondsLeftToComplete),
                style: theme.textTheme.bodyMedium,
              ),
            if (_notice != null) ...[
              const SizedBox(height: NanoSpacing.sm),
              Semantics(
                liveRegion: true,
                child: Text(
                  _notice!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
            const SizedBox(height: NanoSpacing.md),
            FilledButton(
              onPressed: canComplete && !_busy ? _complete : null,
              child: Text(copy.markCompleteLabel),
            ),
            const SizedBox(height: NanoSpacing.lg),
            Align(
              alignment: Alignment.centerLeft,
              child: CompanionSlot(size: widget.junior ? 96 : 72),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerSurface extends StatelessWidget {
  const _PlayerSurface({
    required this.junior,
    required this.playing,
    required this.hasVideo,
    required this.copy,
  });

  final bool junior;
  final bool playing;
  final bool hasVideo;
  final NanoCopy copy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(
            junior ? NanoRadii.junior : NanoRadii.senior,
          ),
        ),
        child: Center(
          child: hasVideo
              ? Icon(
                  playing ? Icons.graphic_eq : Icons.movie_outlined,
                  size: junior ? 56 : 44,
                )
              : Text(copy.videoUnavailable, style: theme.textTheme.bodyMedium),
        ),
      ),
    );
  }
}
