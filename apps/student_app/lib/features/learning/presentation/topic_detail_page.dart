import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/quiz/presentation/junior_quiz_page.dart';
import 'package:student_app/features/quiz/presentation/senior_quiz_page.dart';

import 'topic_player_page.dart';

/// LRN-02 topic detail: objectives, resources, time, progress, unlock reason,
/// and a primary action that goes through the server write path. LRN-03 hands
/// an opened topic to the player. QZ-03/QZ-04 add Take quiz by experience.
class TopicDetailPage extends StatefulWidget {
  const TopicDetailPage({
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
    this.openPlayer = true,
    this.onOpened,
  });

  final CatalogTopic topic;
  final LearningProgressRepository progressRepository;
  final CheckpointRepository? checkpointRepository;
  final LearnerQuizRepository? learnerQuizRepository;
  final QuizAttemptRepository? quizAttemptRepository;
  final String? companionName;
  final String? learnerDisplayName;
  final ShareCardRepository? shareCards;
  final bool junior;

  /// Whether a successful start pushes the player. Off in tests that only
  /// assert the detail surface.
  final bool openPlayer;

  /// Fired after a successful start/resume so a parent list can refresh.
  final ValueChanged<CatalogTopic>? onOpened;

  @override
  State<TopicDetailPage> createState() => _TopicDetailPageState();
}

class _TopicDetailPageState extends State<TopicDetailPage> {
  late CatalogTopic _topic = widget.topic;
  var _busy = false;
  String? _error;

  TopicAction get _action => TopicActionPolicy.forTopic(_topic);

  Future<void> _runAction() async {
    if (!_action.isEnabled || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final row = await widget.progressRepository.start(_topic.topicVersionId);
      if (!mounted) return;
      final updated = TopicActionPolicy.applyProgress(_topic, row);
      setState(() {
        _topic = updated;
        _busy = false;
      });
      widget.onOpened?.call(updated);
      if (widget.openPlayer && updated.hasVideo) await _openPlayer(updated);
    } on TopicGateException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          NanoCopy(NanoAppLocale.en);
      setState(() {
        _busy = false;
        _error = copy.topicGateFailed;
      });
    }
  }

  Future<void> _openPlayer(CatalogTopic topic) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TopicPlayerPage(
          topic: topic,
          progressRepository: widget.progressRepository,
          checkpointRepository: widget.checkpointRepository,
          learnerQuizRepository: widget.learnerQuizRepository,
          quizAttemptRepository: widget.quizAttemptRepository,
          companionName: widget.companionName,
          learnerDisplayName: widget.learnerDisplayName,
          shareCards: widget.shareCards,
          junior: widget.junior,
          onProgress: (updated) {
            if (!mounted) return;
            setState(() => _topic = updated);
            widget.onOpened?.call(updated);
          },
        ),
      ),
    );
  }

  Future<void> _openQuiz() async {
    final repo = widget.learnerQuizRepository;
    if (repo == null) return;
    final locale =
        NanoLocaleScope.maybeOf(context)?.locale ?? NanoAppLocale.en;
    final title = _topic.titleFor(locale);
    await Navigator.of(context).push(
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
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        NanoCopy(NanoAppLocale.en);
    final locale = NanoLocaleScope.maybeOf(context)?.locale ?? NanoAppLocale.en;
    final theme = Theme.of(context);
    final action = _action;
    final title = _topic.titleFor(locale);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: NanoMaxContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            NanoSpacing.md,
            NanoSpacing.md,
            NanoSpacing.md,
            NanoSpacing.xxl,
          ),
          children: [
            if (widget.junior)
              JuniorActionCard(
                title: title,
                subtitle:
                    '${copy.estimatedTimeLabel}: ${copy.minutesLabel(_topic.estimatedMinutes)}',
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              )
            else
              SeniorProgressCard(
                title: title,
                tag: copy.minutesLabel(_topic.estimatedMinutes),
                progress: _topic.progress,
                meta: _topic.isCompleted
                    ? copy.completedLabel
                    : copy.percentComplete(_topic.percentComplete),
              ),
            const SizedBox(height: NanoSpacing.lg),
            if (_topic.isLocked) ...[
              Text(copy.unlockTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: NanoSpacing.sm),
              Text(
                copy.lockedBecause(_topic.blockingTitles.join(', ')),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: NanoSpacing.lg),
            ] else ...[
              if (_topic.canResume) ...[
                Text(
                  copy.resumeFrom(_topic.resumeSeconds),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: NanoSpacing.md),
              ],
              if (_topic.objectives.isNotEmpty) ...[
                Text(copy.objectivesLabel, style: theme.textTheme.titleLarge),
                const SizedBox(height: NanoSpacing.sm),
                for (final objective in _topic.objectives)
                  Padding(
                    padding: const EdgeInsets.only(bottom: NanoSpacing.xs),
                    child: Text('• $objective',
                        style: theme.textTheme.bodyLarge),
                  ),
                const SizedBox(height: NanoSpacing.lg),
              ],
              Text(copy.resourcesLabel, style: theme.textTheme.titleLarge),
              const SizedBox(height: NanoSpacing.sm),
              if (_topic.resources.isEmpty)
                Text(copy.emptyMessage, style: theme.textTheme.bodyMedium)
              else
                for (final resource in _topic.resources)
                  Padding(
                    padding: const EdgeInsets.only(bottom: NanoSpacing.xs),
                    child: Text('• $resource',
                        style: theme.textTheme.bodyLarge),
                  ),
              const SizedBox(height: NanoSpacing.lg),
            ],
            if (_error != null) ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
              const SizedBox(height: NanoSpacing.md),
            ],
            Semantics(
              button: true,
              enabled: action.isEnabled && !_busy,
              label: action.isEnabled
                  ? action.label(copy)
                  : '$title, ${copy.lockedBecause(_topic.blockingTitles.join(', '))}',
              child: FilledButton(
                onPressed:
                    action.isEnabled && !_busy ? _runAction : null,
                child: Text(action.label(copy)),
              ),
            ),
            if (widget.learnerQuizRepository != null && !_topic.isLocked) ...[
              const SizedBox(height: NanoSpacing.sm),
              OutlinedButton(
                onPressed: _openQuiz,
                child: Text(copy.takeQuizLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
