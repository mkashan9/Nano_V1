import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// LRN-03/04 player: resumes where the learner stopped, reports position to the
/// server on a heartbeat, shows captions, offers refresh moments at safe
/// boundaries in long videos, and only offers completion once the server has
/// credited enough watch time.
///
/// The video surface itself is a placeholder until MED-01 lands approved
/// provider playback; everything around it — accounting, resume, captions,
/// checkpoints, completion — is the real path.
class TopicPlayerPage extends StatefulWidget {
  const TopicPlayerPage({
    super.key,
    required this.topic,
    required this.progressRepository,
    this.checkpointRepository,
    this.junior = true,
    this.captionsEnabled,
    this.reducedMotion,
    this.refreshPromptsEnabled,
    this.tick = const Duration(seconds: 1),
    this.onProgress,
  });

  final CatalogTopic topic;
  final LearningProgressRepository progressRepository;

  /// Absent for short content that has no refresh moments.
  final CheckpointRepository? checkpointRepository;
  final bool junior;

  /// Overrides for tests. Left null, these follow the learner's saved
  /// accessibility preferences.
  final bool? captionsEnabled;
  final bool? reducedMotion;
  final bool? refreshPromptsEnabled;

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
  var _checkpoints = const <RefreshCheckpoint>[];
  final _answered = <String>{};
  RefreshCheckpoint? _pending;

  AccessibilityPreferences get _a11y =>
      NanoAccessibilityScope.maybeOf(context)?.preferences ??
      AccessibilityPreferences.defaults;

  bool get _captionsOn =>
      _showCaptions ?? widget.captionsEnabled ?? _a11y.captionsEnabled;

  bool get _reducedMotion => widget.reducedMotion ?? _a11y.reducedMotion;

  /// Classroom Mode silences optional prompts, as does turning refresh prompts
  /// off. Required checkpoints ignore both.
  bool get _allowOptionalPrompts =>
      widget.refreshPromptsEnabled ?? !_a11y.classroomMode;

  int get _creditGate => CheckpointPolicy.creditGate(
        _checkpoints,
        answeredIds: _answered,
        durationSeconds: _topic.durationSeconds,
      );

  int get _seekCeiling => CheckpointPolicy.seekCeiling(
        policy: _topic.seekPolicy,
        watchedSeconds: _topic.watchedSeconds,
        durationSeconds: _topic.durationSeconds,
      );

  @override
  void initState() {
    super.initState();
    _loadCheckpoints();
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _loadCheckpoints() async {
    final repo = widget.checkpointRepository;
    if (repo == null) return;
    try {
      final checkpoints = await repo.forTopicVersion(_topic.topicVersionId);
      final answered = await repo.answeredIds(_topic.topicVersionId);
      if (!mounted) return;
      setState(() {
        _checkpoints = checkpoints;
        _answered
          ..clear()
          ..addAll(answered);
      });
    } catch (_) {
      // Without checkpoints the video simply plays straight through.
    }
  }

  void _togglePlay() {
    setState(() {
      _playing = !_playing;
      _notice = null;
    });
    if (_playing) {
      _clock = Timer.periodic(widget.tick, (_) => _advance());
    } else {
      _stopClock();
      _sendHeartbeat();
    }
  }

  void _stopClock() {
    _clock?.cancel();
    _clock = null;
  }

  void _advance() {
    if (!mounted) return;
    final next = _position + 1;
    setState(() {
      _position = next >= _topic.durationSeconds ? _topic.durationSeconds : next;
      _secondsSinceBeat++;
    });
    if (_position >= _topic.durationSeconds) {
      _stopClock();
      setState(() => _playing = false);
      _sendHeartbeat();
      return;
    }
    final due = CheckpointPolicy.dueAt(
      _checkpoints,
      _position,
      answeredIds: _answered,
      allowOptional: _allowOptionalPrompts,
    );
    if (due != null && _pending?.id != due.id) {
      _pauseFor(due);
      return;
    }
    if (_secondsSinceBeat >= PlaybackPolicy.heartbeat.inSeconds) {
      _sendHeartbeat();
    }
  }

  /// A refresh moment stops playback rather than talking over the video.
  void _pauseFor(RefreshCheckpoint checkpoint) {
    _stopClock();
    setState(() {
      _playing = false;
      _pending = checkpoint;
    });
    _sendHeartbeat();
  }

  Future<void> _answer(
    RefreshCheckpoint checkpoint,
    CheckpointResponse response, {
    required bool resume,
  }) async {
    setState(() {
      _pending = null;
      _answered.add(checkpoint.id);
    });
    try {
      await widget.checkpointRepository?.acknowledge(
        checkpointId: checkpoint.id,
        response: response,
      );
    } catch (_) {
      if (!mounted) return;
      // The prompt was answered locally; the gate stays until the server
      // agrees, so say so rather than pretending credit will flow.
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          NanoCopy(NanoAppLocale.en);
      setState(() {
        _answered.remove(checkpoint.id);
        _notice = copy.topicSaveFailed;
      });
      return;
    }
    if (!mounted || !resume) return;
    setState(() => _playing = true);
    _clock = Timer.periodic(widget.tick, (_) => _advance());
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
    final chapter = CheckpointPolicy.chapterAt(_topic.chapters, _position);
    final gate = _creditGate;
    final gated = gate < _topic.durationSeconds &&
        _topic.watchedSeconds >= gate &&
        !_topic.isCompleted;
    final pending = _pending;

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
                  onPressed:
                      _topic.hasVideo && pending == null ? _togglePlay : null,
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
                      onChanged: _topic.hasVideo && pending == null
                          ? (value) => setState(
                                // Content may forbid skipping ahead, so the
                                // scrubber stops where the server would clamp.
                                () => _position =
                                    value.round().clamp(0, _seekCeiling),
                              )
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
            if (_topic.seekPolicy == SeekPolicy.noSkipAhead)
              Text(copy.noSkipAheadNotice, style: theme.textTheme.bodySmall),
            if (chapter != null)
              Text(
                chapter.titleFor(locale),
                style: theme.textTheme.titleMedium,
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
            if (pending != null) ...[
              const SizedBox(height: NanoSpacing.md),
              _CheckpointCard(
                checkpoint: pending,
                copy: copy,
                locale: locale,
                junior: widget.junior,
                onContinue: () => _answer(
                  pending,
                  pending.defaultResponse,
                  resume: true,
                ),
                onBreak: () => _answer(
                  pending,
                  CheckpointResponse.postponed,
                  resume: false,
                ),
              ),
            ],
            if (gated && pending == null) ...[
              const SizedBox(height: NanoSpacing.sm),
              Semantics(
                liveRegion: true,
                child: Text(
                  copy.creditPausedNotice,
                  style: theme.textTheme.bodyMedium,
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

class _CheckpointCard extends StatelessWidget {
  const _CheckpointCard({
    required this.checkpoint,
    required this.copy,
    required this.locale,
    required this.junior,
    required this.onContinue,
    required this.onBreak,
  });

  final RefreshCheckpoint checkpoint;
  final NanoCopy copy;
  final NanoAppLocale locale;
  final bool junior;
  final VoidCallback onContinue;
  final VoidCallback onBreak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      container: true,
      child: Card(
        color: theme.colorScheme.secondaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            junior ? NanoRadii.junior : NanoRadii.senior,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(NanoSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CompanionSlot(size: junior ? 64 : 48),
                  const SizedBox(width: NanoSpacing.sm),
                  Expanded(
                    child: Text(
                      checkpoint.title(copy),
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: NanoSpacing.sm),
              Text(
                checkpoint.promptFor(locale),
                style: theme.textTheme.bodyLarge,
              ),
              if (checkpoint.isRequired) ...[
                const SizedBox(height: NanoSpacing.sm),
                Text(
                  copy.creditPausedNotice,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: NanoSpacing.md),
              Wrap(
                spacing: NanoSpacing.sm,
                runSpacing: NanoSpacing.sm,
                children: [
                  FilledButton(
                    onPressed: onContinue,
                    child: Text(copy.keepWatchingLabel),
                  ),
                  TextButton(
                    onPressed: onBreak,
                    child: Text(copy.takeABreakLabel),
                  ),
                ],
              ),
            ],
          ),
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
