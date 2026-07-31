import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/learning/presentation/topic_detail_page.dart';

/// LRN-01 subject detail: ordered topics with server-reported lock state,
/// estimated time, and objectives. LRN-02 opens the topic detail and runs
/// start/resume through the progress repository.
class SubjectTopicsPage extends StatefulWidget {
  const SubjectTopicsPage({
    super.key,
    required this.repository,
    required this.subjectId,
    this.progressRepository,
    this.checkpointRepository,
    this.junior = true,
    this.onTopicOpen,
  });

  final LearningCatalogRepository repository;
  final String subjectId;
  final LearningProgressRepository? progressRepository;
  final CheckpointRepository? checkpointRepository;
  final bool junior;
  final ValueChanged<CatalogTopic>? onTopicOpen;

  @override
  State<SubjectTopicsPage> createState() => _SubjectTopicsPageState();
}

class _SubjectTopicsPageState extends State<SubjectTopicsPage> {
  NanoViewState _state = const NanoViewLoading();
  CatalogSubject? _subject;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final subject = await widget.repository.loadSubject(widget.subjectId);
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          NanoCopy(NanoAppLocale.en);
      setState(() {
        _subject = subject;
        if (subject == null || subject.topics.isEmpty) {
          _state = NanoViewEmpty(
            title: copy.catalogEmpty,
            message: copy.emptyMessage,
          );
        } else {
          _state = const NanoViewReady();
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        NanoCopy(NanoAppLocale.en);
    final locale = NanoLocaleScope.maybeOf(context)?.locale ?? NanoAppLocale.en;
    final subject = _subject;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          subject?.titleFor(locale) ?? copy.subjects,
        ),
      ),
      body: NanoViewStateHost(
        state: _state,
        onRetry: _load,
        child: subject == null
            ? const SizedBox.shrink()
            : _SubjectTopicsBody(
                subject: subject,
                copy: copy,
                locale: locale,
                junior: widget.junior,
                onTopicOpen: _openTopic,
              ),
      ),
    );
  }

  void _openTopic(CatalogTopic topic) {
    widget.onTopicOpen?.call(topic);
    final progress = widget.progressRepository;
    if (progress == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TopicDetailPage(
          topic: topic,
          progressRepository: progress,
          checkpointRepository: widget.checkpointRepository,
          junior: widget.junior,
          onOpened: (_) => _load(),
        ),
      ),
    );
  }
}

class _SubjectTopicsBody extends StatelessWidget {
  const _SubjectTopicsBody({
    required this.subject,
    required this.copy,
    required this.locale,
    required this.junior,
    this.onTopicOpen,
  });

  final CatalogSubject subject;
  final NanoCopy copy;
  final NanoAppLocale locale;
  final bool junior;
  final ValueChanged<CatalogTopic>? onTopicOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = subject.nextTopic;
    return NanoMaxContentWidth(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          NanoSpacing.md,
          NanoSpacing.md,
          NanoSpacing.md,
          NanoSpacing.xxl,
        ),
        children: [
          if (junior)
            JuniorActionCard(
              title: subject.titleFor(locale),
              subtitle: subject.summary.isEmpty ? null : subject.summary,
              backgroundColor: Color(subject.worldColorValue),
            )
          else
            SeniorProgressCard(
              title: subject.titleFor(locale),
              tag: copy.topicsDone(subject.completedTopics, subject.topics.length),
              progress: subject.progress,
              meta: subject.remainingMinutes == 0
                  ? null
                  : copy.minutesLabel(subject.remainingMinutes),
            ),
          if (next != null) ...[
            const SizedBox(height: NanoSpacing.lg),
            Text(copy.nextUpTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: NanoSpacing.sm),
            _TopicTile(
              topic: next,
              copy: copy,
              locale: locale,
              junior: junior,
              highlight: true,
              onOpen: onTopicOpen == null ? null : () => onTopicOpen!(next),
            ),
          ],
          const SizedBox(height: NanoSpacing.lg),
          Text(copy.topicCount(subject.topics.length),
              style: theme.textTheme.titleLarge),
          const SizedBox(height: NanoSpacing.sm),
          for (final topic in subject.topics)
            Padding(
              padding: const EdgeInsets.only(bottom: NanoSpacing.sm),
              child: _TopicTile(
                topic: topic,
                copy: copy,
                locale: locale,
                junior: junior,
                onOpen: onTopicOpen == null ? null : () => onTopicOpen!(topic),
              ),
            ),
        ],
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({
    required this.topic,
    required this.copy,
    required this.locale,
    required this.junior,
    this.highlight = false,
    this.onOpen,
  });

  final CatalogTopic topic;
  final NanoCopy copy;
  final NanoAppLocale locale;
  final bool junior;
  final bool highlight;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locked = topic.isLocked;
    final title = topic.titleFor(locale);
    final actionLabel = topic.isCompleted
        ? copy.completedLabel
        : topic.canResume
            ? copy.resumeLabel
            : locked
                ? copy.lockedLabel
                : copy.startLabel;
    return Semantics(
      button: onOpen != null,
      enabled: true,
      label: locked
          ? '$title, ${copy.lockedBecause(topic.blockingTitles.join(', '))}'
          : '$title, $actionLabel',
      child: Material(
        color: highlight
            ? NanoColors.canvasElevated
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(
          junior ? NanoRadii.junior : NanoRadii.senior,
        ),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(
            junior ? NanoRadii.junior : NanoRadii.senior,
          ),
          child: Padding(
            padding: const EdgeInsets.all(NanoSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      locked
                          ? Icons.lock_outline
                          : topic.isCompleted
                              ? Icons.check_circle_outline
                              : Icons.play_circle_outline,
                      size: junior ? 28 : 22,
                    ),
                    const SizedBox(width: NanoSpacing.sm),
                    Expanded(
                      child: Text(
                        title,
                        style: junior
                            ? theme.textTheme.titleLarge
                            : theme.textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      copy.minutesLabel(topic.estimatedMinutes),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                if (locked) ...[
                  const SizedBox(height: NanoSpacing.xs),
                  Text(
                    copy.lockedBecause(topic.blockingTitles.join(', ')),
                    style: theme.textTheme.bodyMedium,
                  ),
                ] else ...[
                  if (topic.objectives.isNotEmpty) ...[
                    const SizedBox(height: NanoSpacing.xs),
                    Text(copy.objectivesLabel, style: theme.textTheme.labelLarge),
                    for (final objective in topic.objectives)
                      Text('• $objective', style: theme.textTheme.bodyMedium),
                  ],
                  if (!topic.isCompleted && topic.progress > 0) ...[
                    const SizedBox(height: NanoSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(NanoRadii.pill),
                      child: LinearProgressIndicator(
                        value: topic.progress,
                        minHeight: 8,
                      ),
                    ),
                  ],
                  const SizedBox(height: NanoSpacing.sm),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      actionLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
