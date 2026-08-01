import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/quiz/presentation/junior_quiz_page.dart';
import 'package:student_app/features/quiz/presentation/senior_quiz_page.dart';
import 'package:video_player/video_player.dart';

/// LRN-03/04 player: resumes where the learner stopped, reports position to the
/// server on a heartbeat, shows captions, offers refresh moments at safe
/// boundaries in long videos, and only offers completion once the server has
/// credited enough watch time. QZ-03/QZ-04 add Take quiz by experience.
///
/// MED-08 replaced the placeholder surface with a real decoder for any topic
/// that carries a playable URL. Every topic in the catalog today is a `fixture`
/// with a slug rather than a URL, so the deterministic one-second clock is
/// still what most sessions run on — and it stays, because a test should not
/// need a codec to prove that watch credit is accounted correctly.
class TopicPlayerPage extends StatefulWidget {
  const TopicPlayerPage({
    super.key,
    required this.topic,
    required this.progressRepository,
    this.checkpointRepository,
    this.learnerQuizRepository,
    this.quizAttemptRepository,
    this.companionName,
    this.learnerDisplayName,
    this.shareCards,
    this.junior = true,
    this.captionsEnabled,
    this.reducedMotion,
    this.refreshPromptsEnabled,
    this.tick = const Duration(seconds: 1),
    this.onProgress,
    this.openVideo,
  });

  final CatalogTopic topic;
  final LearningProgressRepository progressRepository;

  /// Absent for short content that has no refresh moments.
  final CheckpointRepository? checkpointRepository;
  final LearnerQuizRepository? learnerQuizRepository;
  final QuizAttemptRepository? quizAttemptRepository;
  final String? companionName;
  final String? learnerDisplayName;
  final ShareCardRepository? shareCards;
  final bool junior;

  /// Overrides for tests. Left null, these follow the learner's saved
  /// accessibility preferences.
  final bool? captionsEnabled;
  final bool? reducedMotion;
  final bool? refreshPromptsEnabled;

  /// Playback clock interval, shortened by tests.
  final Duration tick;
  final ValueChanged<CatalogTopic>? onProgress;

  /// How a playable topic is opened (MED-08). Left null this is the real
  /// decoder; a test that wants the video path without a codec supplies a
  /// double. Topics with no playable URL never call it at all.
  final VideoPlayerController Function(Uri url)? openVideo;

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
    unawaited(_openVideo());
  }

  @override
  void dispose() {
    _clock?.cancel();
    _video?.removeListener(_onVideoChanged);
    _video?.dispose();
    super.dispose();
  }

  VideoPlayerController? _video;

  /// A URL this device can actually decode, or null (MED-08).
  ///
  /// Deliberately a question about the reference rather than about the provider
  /// name: a `fixture` topic carries a slug, an embed-only provider carries an
  /// id, and neither parses as something to fetch. Anything that does parse as
  /// http is played.
  Uri? get _playableUrl {
    final ref = _topic.videoRef;
    if (ref == null || ref.isEmpty) return null;
    final uri = Uri.tryParse(ref);
    if (uri == null || !uri.hasScheme) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return uri;
  }

  Future<void> _openVideo() async {
    final url = _playableUrl;
    if (url == null) return;
    final open = widget.openVideo ?? VideoPlayerController.networkUrl;
    VideoPlayerController? controller;
    try {
      controller = open(url);
      _video = controller;
      await controller.initialize();
      if (!mounted || _video != controller) {
        await controller.dispose();
        return;
      }
      // Resume exactly where the server said the learner stopped.
      if (_position > 0) {
        await controller.seekTo(Duration(seconds: _position));
      }
      controller.addListener(_onVideoChanged);
      setState(() {});
    } catch (_) {
      // A topic that will not decode falls back to the clock, which still
      // credits watch time honestly. A learner sees the same controls either
      // way, so nothing here needs an error message.
      if (_video == controller) _video = null;
      try {
        await controller?.dispose();
      } catch (_) {
        // Never opened.
      }
    }
  }

  /// The decoder is the clock when there is one: position comes from the frames
  /// actually shown, not from a timer that assumes they were.
  void _onVideoChanged() {
    final controller = _video;
    if (!mounted || controller == null) return;
    final value = controller.value;
    if (!value.isInitialized) return;
    if (value.isPlaying != _playing) {
      setState(() => _playing = value.isPlaying);
    }
    final seconds = value.position.inSeconds;
    if (seconds != _position) _applyPosition(seconds);
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
    final video = _video;
    if (video != null) {
      // The decoder reports its own position, so no timer runs beside it.
      unawaited(_playing ? video.play() : video.pause());
      if (!_playing) _sendHeartbeat();
      return;
    }
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

  void _advance() => _applyPosition(_position + 1);

  /// One place decides what a new position means, whichever clock produced it:
  /// the timer for fixture topics, the decoder for real ones. Checkpoints,
  /// heartbeats, and completion therefore behave identically on both paths, and
  /// the server contract never learns which one was running.
  void _applyPosition(int next) {
    if (!mounted) return;
    final previous = _position;
    setState(() {
      _position = next.clamp(0, _topic.durationSeconds);
      _secondsSinceBeat += (_position - previous).abs();
    });
    if (_position >= _topic.durationSeconds) {
      _stopClock();
      unawaited(_video?.pause() ?? Future.value());
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
    unawaited(_video?.pause() ?? Future.value());
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
      // CMP-03: completion is worth a word, and only once the server agreed.
      NanoCompanionScope.maybeOf(context)?.report(
        CompanionEvent.videoComplete,
        surface: CompanionSurface.learning,
      );
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
              video: _video,
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
                          ? (value) {
                              // Content may forbid skipping ahead, so the
                              // scrubber stops where the server would clamp.
                              final target =
                                  value.round().clamp(0, _seekCeiling);
                              setState(() => _position = target);
                              // The decoder follows the clamped position, never
                              // the raw gesture, so no-skip-ahead holds on the
                              // real path as well as the fixture one.
                              unawaited(
                                _video?.seekTo(Duration(seconds: target)) ??
                                    Future.value(),
                              );
                            }
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
            if (widget.learnerQuizRepository != null && !_topic.isLocked) ...[
              const SizedBox(height: NanoSpacing.sm),
              OutlinedButton(
                onPressed: () {
                  final locale = NanoLocaleScope.maybeOf(context)?.locale ??
                      NanoAppLocale.en;
                  final title = _topic.titleFor(locale);
                  final repo = widget.learnerQuizRepository!;
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => widget.junior
                          ? JuniorQuizPage(
                              topicVersionId: _topic.topicVersionId,
                              repository: repo,
                              attemptRepository: widget.quizAttemptRepository,
                              companionName: widget.companionName ?? 'Nori',
                              topicTitle: title,
                              learnerDisplayName: widget.learnerDisplayName,
                              shareCards: widget.shareCards,
                            )
                          : SeniorQuizPage(
                              topicVersionId: _topic.topicVersionId,
                              repository: repo,
                              attemptRepository: widget.quizAttemptRepository,
                              topicTitle: title,
                              learnerDisplayName: widget.learnerDisplayName,
                              shareCards: widget.shareCards,
                            ),
                    ),
                  );
                },
                child: Text(copy.takeQuizLabel),
              ),
            ],
            const SizedBox(height: NanoSpacing.lg),
            // CMP-03: the learning surface makes this Explorer Nori, sized by
            // placement rather than by this page.
            CompanionSurfaceStage(
              surface: CompanionSurface.learning,
              junior: widget.junior,
              entryEvent: CompanionEvent.videoStart,
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
    required this.video,
    required this.copy,
  });

  final bool junior;
  final bool playing;
  final bool hasVideo;

  /// The decoder for a topic that carries a playable URL, or null for a fixture
  /// topic, which is every topic in the catalog today.
  final VideoPlayerController? video;
  final NanoCopy copy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = video;
    final radius = BorderRadius.circular(
      junior ? NanoRadii.junior : NanoRadii.senior,
    );
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: radius,
        ),
        child: controller != null && controller.value.isInitialized
            ? ClipRRect(
                borderRadius: radius,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                ),
              )
            : Center(
                child: hasVideo
                    ? Icon(
                        playing ? Icons.graphic_eq : Icons.movie_outlined,
                        size: junior ? 56 : 44,
                      )
                    : Text(
                        copy.videoUnavailable,
                        style: theme.textTheme.bodyMedium,
                      ),
              ),
      ),
    );
  }
}
