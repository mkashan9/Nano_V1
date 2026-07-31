import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// LRN-02 topic detail: objectives, resources, time, progress, unlock reason,
/// and a primary action that goes through the server write path.
class TopicDetailPage extends StatefulWidget {
  const TopicDetailPage({
    super.key,
    required this.topic,
    required this.progressRepository,
    this.junior = true,
    this.onOpened,
  });

  final CatalogTopic topic;
  final LearningProgressRepository progressRepository;
  final bool junior;

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
          ],
        ),
      ),
    );
  }
}
