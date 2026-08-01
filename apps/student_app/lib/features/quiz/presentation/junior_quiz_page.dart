import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// QZ-03 Junior attempt: one question per screen, companion prompts,
/// local selections only — no client-side final score (QZ-05).
class JuniorQuizPage extends StatefulWidget {
  const JuniorQuizPage({
    super.key,
    required this.topicVersionId,
    required this.repository,
    this.companionName = 'Nori',
    this.topicTitle,
  });

  final String topicVersionId;
  final LearnerQuizRepository repository;
  final String companionName;
  final String? topicTitle;

  @override
  State<JuniorQuizPage> createState() => _JuniorQuizPageState();
}

class _JuniorQuizPageState extends State<JuniorQuizPage> {
  NanoViewState _state = const NanoViewLoading();
  JuniorQuizFlow? _flow;

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
        _flow = JuniorQuizFlow.start(quiz);
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  void _select(String optionId) {
    final flow = _flow;
    if (flow == null || flow.finished) return;
    setState(() => _flow = flow.select(optionId));
  }

  void _advance() {
    final flow = _flow;
    if (flow == null || !flow.canAdvance) return;
    setState(() => _flow = flow.advance());
  }

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
                      ? _FinishedPane(
                          copy: copy,
                          companionName: widget.companionName,
                          prompt: flow.promptFor(
                            locale,
                            companionName: widget.companionName,
                          ),
                        )
                      : _QuestionPane(
                          flow: flow,
                          copy: copy,
                          locale: locale,
                          companionName: widget.companionName,
                          theme: theme,
                          onSelect: _select,
                          onAdvance: _advance,
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
    required this.companionName,
    required this.theme,
    required this.onSelect,
    required this.onAdvance,
  });

  final JuniorQuizFlow flow;
  final NanoCopy copy;
  final NanoAppLocale locale;
  final String companionName;
  final ThemeData theme;
  final ValueChanged<String> onSelect;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final item = flow.currentItem;
    final selected = flow.selectedOptionId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CompanionSlot(
              size: 88,
              semanticLabel: companionName,
            ),
            const SizedBox(width: NanoSpacing.md),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  flow.promptFor(locale, companionName: companionName),
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: NanoSpacing.md),
        Text(
          copy.quizProgressLabel(flow.currentIndex + 1, flow.questionCount),
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: NanoSpacing.xs),
        LinearProgressIndicator(
          value: (flow.currentIndex + 1) / flow.questionCount,
        ),
        const SizedBox(height: NanoSpacing.lg),
        Text(
          item.stemFor(locale),
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: NanoSpacing.lg),
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
                  borderRadius: BorderRadius.circular(NanoRadii.junior),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(NanoRadii.junior),
                    onTap: () => onSelect(option.id),
                    child: Padding(
                      padding: const EdgeInsets.all(
                        NanoSpacing.cardPaddingJunior,
                      ),
                      child: Text(
                        option.labelFor(locale),
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: NanoSpacing.md),
        FilledButton(
          onPressed: flow.canAdvance ? onAdvance : null,
          child: Text(
            flow.isLastQuestion ? copy.quizFinishLabel : copy.quizNextLabel,
          ),
        ),
      ],
    );
  }
}

class _FinishedPane extends StatelessWidget {
  const _FinishedPane({
    required this.copy,
    required this.companionName,
    required this.prompt,
  });

  final NanoCopy copy;
  final String companionName;
  final String prompt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: NanoSpacing.xl),
        Center(
          child: CompanionSlot(size: 120, semanticLabel: companionName),
        ),
        const SizedBox(height: NanoSpacing.lg),
        Text(
          copy.quizDoneTitle,
          style: theme.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: NanoSpacing.md),
        Semantics(
          liveRegion: true,
          child: Text(
            prompt,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
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
