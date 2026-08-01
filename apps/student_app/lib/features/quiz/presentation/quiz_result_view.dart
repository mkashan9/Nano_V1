import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// QZ-06 results: the server score, a per-question review with explanations,
/// and the retake budget the server will honour.
///
/// Junior and Senior share the data and differ only in density and warmth,
/// so a learner cannot see a different verdict depending on the shell.
class QuizResultView extends StatelessWidget {
  const QuizResultView({
    super.key,
    required this.result,
    required this.copy,
    required this.locale,
    this.junior = false,
    this.companionName = 'Nori',
    this.retaking = false,
    this.onRetake,
    this.onDone,
  });

  final AttemptResult result;
  final NanoCopy copy;
  final NanoAppLocale locale;
  final bool junior;
  final String companionName;
  final bool retaking;
  final VoidCallback? onRetake;
  final VoidCallback? onDone;

  /// CMP-01: the companion reacts to the outcome the server reported, and to
  /// nothing it worked out for itself. Seeding with the attempt number and
  /// timing with `scoredAt` keeps the reaction reproducible.
  ///
  /// CMP-02: the quiz surface makes this Quiz Coach Nori, so a celebration here
  /// stays coaching rather than turning into a milestone.
  CompanionReaction? _reaction(BuildContext context) {
    final preferences = NanoAccessibilityScope.maybeOf(context)?.preferences ??
        AccessibilityPreferences.defaults;
    return CompanionRuntime.forExperience(
      junior: junior,
      surface: CompanionSurface.quiz,
      preferences: preferences,
      companionName: companionName,
    )
        .notify(
          CompanionEvent.forOutcome(passed: result.passed),
          now: result.scoredAt ?? DateTime.now(),
          seed: result.attemptNumber - 1,
        )
        .reaction;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        CompanionStage(
          reaction: _reaction(context),
          companionName: companionName,
          locale: locale,
        ),
        const SizedBox(height: NanoSpacing.md),
        Text(
          // Junior keeps the celebration it earned; Senior leads with the data.
          junior ? copy.quizDoneTitle : copy.quizResultsTitle,
          style: junior
              ? theme.textTheme.headlineMedium
              : theme.textTheme.headlineSmall,
          textAlign: junior ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: NanoSpacing.sm),
        Semantics(
          liveRegion: true,
          child: Column(
            crossAxisAlignment: junior
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Text(
                copy.quizServerScore(result.scorePercent),
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: NanoSpacing.xs),
              Text(
                result.passed ? copy.quizPassedLabel : copy.quizFailedLabel,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: NanoSpacing.xs),
              Text(
                copy.quizCorrectCountLabel(
                  result.correctCount,
                  result.totalCount,
                ),
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: NanoSpacing.xs),
        Text(
          copy.quizPassMarkLabel(result.passPercent),
          style: theme.textTheme.bodyMedium,
          textAlign: junior ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: NanoSpacing.xs),
        Text(
          copy.quizScoreFromServerNotice,
          style: theme.textTheme.bodyMedium,
          textAlign: junior ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: NanoSpacing.lg),
        Text(
          copy.quizReviewAnswersTitle,
          style: theme.textTheme.titleMedium,
        ),
        if (junior) ...[
          const SizedBox(height: NanoSpacing.xs),
          Text(
            copy.quizJuniorReviewIntro,
            style: theme.textTheme.bodyLarge,
          ),
        ],
        const SizedBox(height: NanoSpacing.sm),
        for (final item in result.items)
          Padding(
            padding: const EdgeInsets.only(bottom: NanoSpacing.sm),
            child: _ReviewCard(
              item: item,
              copy: copy,
              locale: locale,
              junior: junior,
            ),
          ),
        const SizedBox(height: NanoSpacing.md),
        Text(
          switch (result.retakesRemaining) {
            null => copy.quizUnlimitedRetakesLabel,
            0 => copy.quizNoRetakesLeftLabel,
            final remaining => copy.quizRetakesLeftLabel(remaining),
          },
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: NanoSpacing.sm),
        if (onRetake != null)
          FilledButton(
            onPressed: result.canRetake && !retaking ? onRetake : null,
            child: Text(copy.quizRetakeLabel),
          ),
        const SizedBox(height: NanoSpacing.sm),
        OutlinedButton(
          onPressed: onDone ?? () => Navigator.of(context).maybePop(),
          child: Text(copy.quizDoneButtonLabel),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.item,
    required this.copy,
    required this.locale,
    required this.junior,
  });

  final AttemptReviewItem item;
  final NanoCopy copy;
  final NanoAppLocale locale;
  final bool junior;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected = item.selectedLabelFor(locale);
    final correct = item.correctLabelFor(locale);
    return Semantics(
      // Correctness is announced in words; colour alone never carries it.
      label: item.wasCorrect ? copy.quizPassedLabel : copy.quizFailedLabel,
      child: Card(
        margin: EdgeInsets.zero,
        color: item.wasCorrect
            ? scheme.secondaryContainer
            : scheme.surfaceContainerHighest,
        child: Padding(
          padding: EdgeInsets.all(
            junior ? NanoSpacing.cardPaddingJunior : NanoSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    item.wasCorrect ? Icons.check_circle : Icons.info_outline,
                    size: junior ? 28 : 20,
                  ),
                  const SizedBox(width: NanoSpacing.xs),
                  Expanded(
                    child: Text(
                      copy.quizItemNumber(item.sortOrder),
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: NanoSpacing.xs),
              Text(
                item.stemFor(locale),
                style: junior
                    ? theme.textTheme.titleLarge
                    : theme.textTheme.titleMedium,
              ),
              const SizedBox(height: NanoSpacing.sm),
              Text(
                '${copy.quizYourAnswerLabel}: '
                '${selected ?? copy.quizUnansweredLabel}',
                style: theme.textTheme.bodyLarge,
              ),
              if (!item.wasCorrect && correct != null) ...[
                const SizedBox(height: NanoSpacing.xs),
                Text(
                  '${copy.correctOptionLabel}: $correct',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
              if (item.hasExplanation) ...[
                const SizedBox(height: NanoSpacing.sm),
                Text(
                  '${copy.quizWhyLabel}: ${item.explanationFor(locale)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
