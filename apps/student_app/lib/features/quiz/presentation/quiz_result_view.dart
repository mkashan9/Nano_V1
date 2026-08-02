import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/share/presentation/social_share_sheet.dart';

/// QZ-06 results: the server score, a per-question review with explanations,
/// and the retake budget the server will honour.
///
/// Junior and Senior share the data and differ only in density and warmth,
/// so a learner cannot see a different verdict depending on the shell.
///
/// XP-06/SOC-04: privacy-safe score share via destination sheet.
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
    this.learnerDisplayName,
    this.shareCards,
  });

  final AttemptResult result;
  final NanoCopy copy;
  final NanoAppLocale locale;
  final bool junior;
  final String companionName;
  final bool retaking;
  final VoidCallback? onRetake;
  final VoidCallback? onDone;

  /// XP-06: used to build a first-name-only score card.
  final String? learnerDisplayName;

  /// When set, prefers the server `build_share_card` path.
  final ShareCardRepository? shareCards;

  Future<void> _shareScore(BuildContext context) async {
    final name = learnerDisplayName?.trim();
    if (name == null || name.isEmpty) return;
    try {
      final ShareCard card;
      if (shareCards != null) {
        card = await shareCards!.forQuizScore(
          scorePercent: result.scorePercent.round(),
          passed: result.passed,
        );
      } else {
        card = ShareCard.quizScore(
          displayName: name,
          scorePercent: result.scorePercent.round(),
          passed: result.passed,
        );
      }
      if (!context.mounted) return;
      final outcome = await showSocialShareSheet(
        context: context,
        card: card,
        copy: copy,
      );
      if (!context.mounted || outcome == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(shareOutcomeMessage(outcome, copy))),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not build share card')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canShare =
        learnerDisplayName != null && learnerDisplayName!.trim().isNotEmpty;
    return ListView(
      children: [
        // MED-12: the session companion, so cooldowns and the session budget
        // apply here the same way they do on home. CMP-03 previously kept
        // results on a throwaway runtime so a derived screen could not spend
        // the budget; that made results the one place a celebration never
        // counted, which was the opposite of the rule that mattered.
        CompanionSurfaceStage(
          surface: CompanionSurface.quiz,
          junior: junior,
          entryEvent: CompanionEvent.forOutcome(passed: result.passed),
          seed: result.attemptNumber - 1,
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
        if (canShare) ...[
          const SizedBox(height: NanoSpacing.sm),
          Align(
            alignment: junior ? Alignment.center : Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => _shareScore(context),
              icon: const Icon(Icons.ios_share_outlined),
              label: Text(copy.shareScoreLabel),
            ),
          ),
        ],
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
