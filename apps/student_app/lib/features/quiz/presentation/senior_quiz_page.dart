import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// QZ-04 Senior attempt: free navigation, review checklist, local selections
/// only — no client-side final score (QZ-05).
class SeniorQuizPage extends StatefulWidget {
  const SeniorQuizPage({
    super.key,
    required this.topicVersionId,
    required this.repository,
    this.topicTitle,
  });

  final String topicVersionId;
  final LearnerQuizRepository repository;
  final String? topicTitle;

  @override
  State<SeniorQuizPage> createState() => _SeniorQuizPageState();
}

class _SeniorQuizPageState extends State<SeniorQuizPage> {
  NanoViewState _state = const NanoViewLoading();
  SeniorQuizFlow? _flow;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final quiz = await widget.repository.quizForTopic(widget.topicVersionId);
      if (!mounted) return;
      if (quiz == null) {
        setState(() {
          _flow = null;
          _state = const NanoViewEmpty(
            title: 'No quiz yet',
            message: 'This topic does not have a published quiz.',
          );
        });
        return;
      }
      setState(() {
        _flow = SeniorQuizFlow.start(quiz);
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  void _update(SeniorQuizFlow next) => setState(() => _flow = next);

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        NanoCopy(NanoAppLocale.en);
    final locale =
        NanoLocaleScope.maybeOf(context)?.locale ?? NanoAppLocale.en;
    final theme = Theme.of(context);
    final flow = _flow;
    final title = widget.topicTitle ?? copy.takeQuizLabel;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: NanoViewStateHost(
        state: _state,
        onRetry: _load,
        child: flow == null
            ? Center(child: Text(copy.quizUnavailableLabel))
            : NanoMaxContentWidth(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    NanoSpacing.md,
                    NanoSpacing.md,
                    NanoSpacing.md,
                    NanoSpacing.xxl,
                  ),
                  child: flow.finished
                      ? _FinishedPane(copy: copy)
                      : flow.reviewing
                          ? _ReviewPane(
                              flow: flow,
                              copy: copy,
                              onJump: (i) => _update(flow.jumpTo(i)),
                              onExit: () => _update(flow.exitReview()),
                              onFinish: () => _update(flow.finish()),
                            )
                          : _QuestionPane(
                              flow: flow,
                              copy: copy,
                              locale: locale,
                              theme: theme,
                              onSelect: (id) => _update(flow.select(id)),
                              onJump: (i) => _update(flow.jumpTo(i)),
                              onPrevious: () => _update(flow.goPrevious()),
                              onNext: () => _update(flow.goNext()),
                              onReview: () => _update(flow.enterReview()),
                            ),
                ),
              ),
      ),
    );
  }
}

class _QuestionPane extends StatelessWidget {
  const _QuestionPane({
    required this.flow,
    required this.copy,
    required this.locale,
    required this.theme,
    required this.onSelect,
    required this.onJump,
    required this.onPrevious,
    required this.onNext,
    required this.onReview,
  });

  final SeniorQuizFlow flow;
  final NanoCopy copy;
  final NanoAppLocale locale;
  final ThemeData theme;
  final ValueChanged<String> onSelect;
  final ValueChanged<int> onJump;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final item = flow.currentItem;
    final selected = flow.selectedOptionId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          copy.quizAnsweredCount(flow.answeredCount, flow.questionCount),
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: NanoSpacing.sm),
        Semantics(
          label: copy.quizNavigatorLabel,
          child: Wrap(
            spacing: NanoSpacing.xs,
            runSpacing: NanoSpacing.xs,
            children: [
              for (var i = 0; i < flow.questionCount; i++)
                ChoiceChip(
                  label: Text('${i + 1}'),
                  selected: i == flow.currentIndex,
                  onSelected: (_) => onJump(i),
                  avatar: flow.isAnswered(i)
                      ? const Icon(Icons.check, size: 16)
                      : null,
                ),
            ],
          ),
        ),
        const SizedBox(height: NanoSpacing.md),
        Text(
          copy.quizProgressLabel(flow.currentIndex + 1, flow.questionCount),
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: NanoSpacing.sm),
        Text(item.stemFor(locale), style: theme.textTheme.titleLarge),
        const SizedBox(height: NanoSpacing.md),
        Expanded(
          child: ListView.separated(
            itemCount: item.options.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: NanoSpacing.sm),
            itemBuilder: (context, index) {
              final option = item.options[index];
              final isSelected = option.id == selected;
              return Semantics(
                button: true,
                selected: isSelected,
                label: option.labelFor(locale),
                child: Material(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(NanoRadii.senior),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(NanoRadii.senior),
                    onTap: () => onSelect(option.id),
                    child: Padding(
                      padding: const EdgeInsets.all(
                        NanoSpacing.cardPaddingSenior,
                      ),
                      child: Text(
                        option.labelFor(locale),
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: NanoSpacing.md),
        Row(
          children: [
            OutlinedButton(
              onPressed: flow.isFirstQuestion ? null : onPrevious,
              child: Text(copy.quizPreviousLabel),
            ),
            const SizedBox(width: NanoSpacing.sm),
            OutlinedButton(
              onPressed: flow.isLastQuestion ? null : onNext,
              child: Text(copy.quizNextLabel),
            ),
            const Spacer(),
            FilledButton(
              onPressed: onReview,
              child: Text(copy.quizSubmitReviewLabel),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReviewPane extends StatelessWidget {
  const _ReviewPane({
    required this.flow,
    required this.copy,
    required this.onJump,
    required this.onExit,
    required this.onFinish,
  });

  final SeniorQuizFlow flow;
  final NanoCopy copy;
  final ValueChanged<int> onJump;
  final VoidCallback onExit;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(copy.quizReviewLabel, style: theme.textTheme.headlineSmall),
        const SizedBox(height: NanoSpacing.sm),
        Text(
          copy.quizAnsweredCount(flow.answeredCount, flow.questionCount),
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: NanoSpacing.md),
        Expanded(
          child: ListView.separated(
            itemCount: flow.questionCount,
            separatorBuilder: (_, __) =>
                const SizedBox(height: NanoSpacing.xs),
            itemBuilder: (context, index) {
              final answered = flow.isAnswered(index);
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(NanoRadii.senior),
                ),
                title: Text(copy.quizItemNumber(index + 1)),
                subtitle: Text(
                  answered
                      ? copy.quizAnsweredLabel
                      : copy.quizUnansweredLabel,
                ),
                trailing: Icon(
                  answered ? Icons.check_circle : Icons.error_outline,
                ),
                onTap: () => onJump(index),
              );
            },
          ),
        ),
        const SizedBox(height: NanoSpacing.md),
        Row(
          children: [
            OutlinedButton(
              onPressed: onExit,
              child: Text(copy.quizPreviousLabel),
            ),
            const Spacer(),
            FilledButton(
              onPressed: flow.canFinish ? onFinish : null,
              child: Text(copy.quizFinishLabel),
            ),
          ],
        ),
        if (!flow.allAnswered) ...[
          const SizedBox(height: NanoSpacing.sm),
          Text(
            copy.quizUnansweredLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

class _FinishedPane extends StatelessWidget {
  const _FinishedPane({required this.copy});

  final NanoCopy copy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: NanoSpacing.xl),
        Text(
          copy.quizDoneTitle,
          style: theme.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: NanoSpacing.md),
        Text(
          copy.quizScoreLaterNotice,
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        OutlinedButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(copy.quizDoneButtonLabel),
        ),
      ],
    );
  }
}
