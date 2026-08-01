import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

import 'quiz_result_view.dart';

/// QZ-03/QZ-05 Junior attempt: one question per screen; answers persist and
/// finish submits for a server score.
class JuniorQuizPage extends StatefulWidget {
  const JuniorQuizPage({
    super.key,
    required this.topicVersionId,
    required this.repository,
    this.attemptRepository,
    this.companionName = 'Nori',
    this.topicTitle,
  });

  final String topicVersionId;
  final LearnerQuizRepository repository;
  final QuizAttemptRepository? attemptRepository;
  final String companionName;
  final String? topicTitle;

  @override
  State<JuniorQuizPage> createState() => _JuniorQuizPageState();
}

class _JuniorQuizPageState extends State<JuniorQuizPage> {
  NanoViewState _state = const NanoViewLoading();
  JuniorQuizFlow? _flow;
  String? _attemptId;
  ScoreResult? _score;
  AttemptResult? _result;
  var _submitting = false;
  late final QuizAttemptRepository _attempts =
      widget.attemptRepository ?? FakeQuizAttemptRepository();

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
      final session = await _attempts.startOrResume(widget.topicVersionId);
      if (!mounted) return;
      setState(() {
        _attemptId = session.attemptId;
        _score = null;
        _result = null;
        _flow = session.answers.isEmpty
            ? JuniorQuizFlow.start(quiz)
            : JuniorQuizFlow.resume(quiz, session.answers);
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  Future<void> _select(String optionId) async {
    final flow = _flow;
    final attemptId = _attemptId;
    if (flow == null || flow.finished || attemptId == null) return;
    final next = flow.select(optionId);
    setState(() => _flow = next);
    try {
      await _attempts.saveAnswer(
        attemptId: attemptId,
        questionVersionId: next.currentItem.questionVersionId,
        selectedOptionId: optionId,
      );
    } catch (_) {
      // Keep the local selection; the next save or submit will surface issues.
    }
  }

  Future<void> _advance() async {
    final flow = _flow;
    if (flow == null || !flow.canAdvance || _submitting) return;
    if (!flow.isLastQuestion) {
      setState(() => _flow = flow.advance());
      return;
    }
    setState(() {
      _submitting = true;
      _flow = flow.advance();
    });
    try {
      final score = await _attempts.submit(_attemptId!);
      // The review and explanations are a second server read, so a failure
      // here still leaves the learner with the score they earned.
      AttemptResult? result;
      try {
        result = await _attempts.result(score.attemptId);
      } catch (_) {
        result = null;
      }
      if (!mounted) return;
      setState(() {
        _score = score;
        _result = result;
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _flow = flow;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not submit quiz')),
      );
    }
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
                  child: _result != null
                      ? QuizResultView(
                          result: _result!,
                          copy: copy,
                          locale: locale,
                          junior: true,
                          companionName: widget.companionName,
                          retaking: _submitting,
                          onRetake: _load,
                        )
                      : flow.finished || _score != null
                          ? _FinishedPane(
                              copy: copy,
                              companionName: widget.companionName,
                              prompt: flow.promptFor(
                                locale,
                                companionName: widget.companionName,
                              ),
                              score: _score,
                            )
                          : _QuestionPane(
                              flow: flow,
                              copy: copy,
                              locale: locale,
                              companionName: widget.companionName,
                              theme: theme,
                              submitting: _submitting,
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
    required this.submitting,
    required this.onSelect,
    required this.onAdvance,
  });

  final JuniorQuizFlow flow;
  final NanoCopy copy;
  final NanoAppLocale locale;
  final String companionName;
  final ThemeData theme;
  final bool submitting;
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
            CompanionSlot(size: 88, semanticLabel: companionName),
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
        Text(item.stemFor(locale), style: theme.textTheme.headlineSmall),
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
                    onTap: submitting ? null : () => onSelect(option.id),
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
          onPressed: flow.canAdvance && !submitting ? onAdvance : null,
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
    this.score,
  });

  final NanoCopy copy;
  final String companionName;
  final String prompt;
  final ScoreResult? score;

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
        if (score != null) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              copy.quizServerScore(score!.scorePercent),
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: NanoSpacing.sm),
          Text(
            score!.passed ? copy.quizPassedLabel : copy.quizFailedLabel,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: NanoSpacing.sm),
          Text(
            copy.quizScoreFromServerNotice,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ] else ...[
          Text(
            prompt,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: NanoSpacing.md),
          Text(
            copy.quizScoreLaterNotice,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
        const Spacer(),
        OutlinedButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(copy.quizDoneButtonLabel),
        ),
      ],
    );
  }
}
