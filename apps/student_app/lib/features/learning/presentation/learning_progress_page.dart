import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// LRN-05 progress screen: what the learner has finished, where their time went,
/// and what to open next with the server's reason for suggesting it.
///
/// Nothing here is computed from a guess about eligibility or locks. The
/// suggestion list arrives ranked from `public.learning_next_up`, so anything
/// the learner cannot open is already absent.
class LearningProgressPage extends StatefulWidget {
  const LearningProgressPage({
    super.key,
    required this.repository,
    this.junior = true,
    this.onOpenSuggestion,
  });

  final LearningInsightsRepository repository;
  final bool junior;

  /// Opens the suggested topic. Absent in previews, where the card is inert.
  final ValueChanged<NextUpSuggestion>? onOpenSuggestion;

  @override
  State<LearningProgressPage> createState() => _LearningProgressPageState();
}

class _LearningProgressPageState extends State<LearningProgressPage> {
  NanoViewState _state = const NanoViewLoading();
  LearningInsights? _insights;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final insights = await widget.repository.loadInsights();
      if (!mounted) return;
      setState(() {
        _insights = insights;
        _state = insights.isEmpty
            ? const NanoViewEmpty(
                title: 'No learning yet',
                message: 'Open a subject to start.',
              )
            : const NanoViewReady();
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
    final insights = _insights;
    return Scaffold(
      appBar: AppBar(title: Text(copy.progressTitle)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: NanoViewStateHost(
          state: _state,
          onRetry: _load,
          child: insights == null
              ? const SizedBox.shrink()
              : _InsightsBody(
                  insights: insights,
                  junior: widget.junior,
                  onOpenSuggestion: widget.onOpenSuggestion,
                ),
        ),
      ),
    );
  }
}

class _InsightsBody extends StatelessWidget {
  const _InsightsBody({
    required this.insights,
    required this.junior,
    this.onOpenSuggestion,
  });

  final LearningInsights insights;
  final bool junior;
  final ValueChanged<NextUpSuggestion>? onOpenSuggestion;

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        NanoCopy(NanoAppLocale.en);
    final locale = NanoLocaleScope.maybeOf(context)?.locale ?? NanoAppLocale.en;
    final theme = Theme.of(context);
    final recommendation = insights.recommendation;
    final strongest = insights.strongest;
    final focus = insights.needsAttention;

    return NanoMaxContentWidth(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          NanoSpacing.md,
          NanoSpacing.md,
          NanoSpacing.md,
          NanoSpacing.xxl,
        ),
        children: [
          Text(
            copy.topicsDone(insights.topicsCompleted, insights.topicsTotal),
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: NanoSpacing.xs),
          Text(
            copy.watchedMinutes(insights.watchedMinutes),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: NanoSpacing.md),
          Text(copy.recommendedTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: NanoSpacing.sm),
          if (recommendation == null)
            _Panel(
              junior: junior,
              // CMP-03: an empty recommendation list is one of the moments the
              // companion is allowed to fill.
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.allCaughtUp,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: NanoSpacing.xs),
                  CompanionSurfaceStage(
                    surface: CompanionSurface.progress,
                    junior: junior,
                    entryEvent: CompanionEvent.emptyState,
                  ),
                ],
              ),
            )
          else
            _SuggestionCard(
              suggestion: recommendation,
              junior: junior,
              primary: true,
              onOpen: onOpenSuggestion,
            ),
          for (final alternative in insights.alternatives) ...[
            const SizedBox(height: NanoSpacing.sm),
            _SuggestionCard(
              suggestion: alternative,
              junior: junior,
              primary: false,
              onOpen: onOpenSuggestion,
            ),
          ],
          const SizedBox(height: NanoSpacing.lg),
          Text(copy.progressTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: NanoSpacing.sm),
          for (final subject in insights.orderedSubjects) ...[
            _SubjectProgressRow(subject: subject, copy: copy, locale: locale),
            const SizedBox(height: NanoSpacing.md),
          ],
          if (strongest != null)
            Text(
              '${copy.strongestLabel}: ${strongest.titleFor(locale)}',
              style: theme.textTheme.bodyLarge,
            ),
          if (focus != null) ...[
            const SizedBox(height: NanoSpacing.xs),
            Text(
              '${copy.focusLabel}: ${focus.titleFor(locale)}',
              style: theme.textTheme.bodyLarge,
            ),
          ],
          if (strongest == null && focus == null)
            Text(copy.nothingStartedYet, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.suggestion,
    required this.junior,
    required this.primary,
    this.onOpen,
  });

  final NextUpSuggestion suggestion;
  final bool junior;
  final bool primary;
  final ValueChanged<NextUpSuggestion>? onOpen;

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        NanoCopy(NanoAppLocale.en);
    final locale = NanoLocaleScope.maybeOf(context)?.locale ?? NanoAppLocale.en;
    final theme = Theme.of(context);
    final open = onOpen == null ? null : () => onOpen!(suggestion);

    return _Panel(
      junior: junior,
      onTap: open,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            suggestion.subjectTitleFor(locale),
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: NanoSpacing.xs),
          Text(
            suggestion.titleFor(locale),
            style: primary
                ? theme.textTheme.titleLarge
                : theme.textTheme.titleMedium,
          ),
          const SizedBox(height: NanoSpacing.xs),
          Text(
            suggestion.reasonLabel(copy),
            style: theme.textTheme.bodyMedium,
          ),
          if (suggestion.isResume && suggestion.durationSeconds > 0) ...[
            const SizedBox(height: NanoSpacing.xs),
            Semantics(
              label: copy.watchedLabel,
              value: PlaybackPolicy.clock(suggestion.watchedSeconds),
              child: LinearProgressIndicator(
                value: (suggestion.watchedSeconds / suggestion.durationSeconds)
                    .clamp(0.0, 1.0),
              ),
            ),
          ],
          if (primary) ...[
            const SizedBox(height: NanoSpacing.sm),
            FilledButton(
              onPressed: open,
              child: Text(
                suggestion.isResume ? copy.resumeLabel : copy.startLabel,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.junior, required this.child, this.onTap});

  final bool junior;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(
      junior ? NanoRadii.junior : NanoRadii.senior,
    );
    return Card(
      shape: RoundedRectangleBorder(borderRadius: radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: EdgeInsets.all(
            junior ? NanoSpacing.cardPaddingJunior : NanoSpacing.cardPaddingSenior,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SubjectProgressRow extends StatelessWidget {
  const _SubjectProgressRow({
    required this.subject,
    required this.copy,
    required this.locale,
  });

  final SubjectProgress subject;
  final NanoCopy copy;
  final NanoAppLocale locale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = copy.topicsDone(subject.topicsCompleted, subject.topicsTotal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                subject.titleFor(locale),
                style: theme.textTheme.titleMedium,
              ),
            ),
            // The numbers carry the meaning; the bar is decoration on top.
            Text(done, style: theme.textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: NanoSpacing.xs),
        Semantics(
          label: subject.titleFor(locale),
          value: done,
          child: LinearProgressIndicator(value: subject.completionRatio),
        ),
        if (subject.topicsLocked > 0) ...[
          const SizedBox(height: NanoSpacing.xs),
          Text(
            copy.lockedCount(subject.topicsLocked),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
