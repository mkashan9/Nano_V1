import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// STU-04 Senior Home: level and XP, streak, latest update, what to continue,
/// Today's Plan, and a Flex summary for school-eligible learners.
///
/// Sections load as one summary but fail independently, so a broken source
/// shows an inline notice instead of blanking the screen.
class SeniorHomePage extends StatefulWidget {
  const SeniorHomePage({
    super.key,
    required this.repository,
    required this.learnerName,
    this.userId = 'local',
    this.companionName = 'Nori',
    this.flexEligible = false,
    this.onContinue,
    this.onSubjectTap,
    this.onOpenFlex,
    this.onOpenUpdate,
    this.onNotifications,
  });

  final StudentHomeRepository repository;
  final String learnerName;
  final String userId;
  final String companionName;

  /// Client-side guard on top of the server entitlement. Independent learners
  /// never reach the Flex card.
  final bool flexEligible;
  final ValueChanged<ContinueLearningItem>? onContinue;
  final ValueChanged<LearningSubject>? onSubjectTap;
  final VoidCallback? onOpenFlex;
  final VoidCallback? onOpenUpdate;
  final VoidCallback? onNotifications;

  @override
  State<SeniorHomePage> createState() => _SeniorHomePageState();
}

class _SeniorHomePageState extends State<SeniorHomePage> {
  NanoViewState _state = const NanoViewLoading();
  StudentHomeSummary? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final summary = await widget.repository.loadHome(
        userId: widget.userId,
        learnerName: widget.learnerName,
        companionName: widget.companionName,
        flexEligible: widget.flexEligible,
      );
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _state = _stateFor(summary);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  NanoViewState _stateFor(StudentHomeSummary summary) {
    if (summary.notice == HomeNoticeKind.maintenance) {
      return const NanoViewMaintenance();
    }
    if (!summary.hasContent) {
      return const NanoViewEmpty();
    }
    return summary.fromCache
        ? NanoViewOffline(lastUpdatedLabel: summary.freshnessLabel)
        : const NanoViewReady();
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        NanoCopy(NanoAppLocale.en);
    final summary = _summary;
    return NanoViewStateHost(
      state: _state,
      onRetry: _load,
      child: summary == null
          ? const SizedBox.shrink()
          : _SeniorHomeContent(
              summary: summary,
              copy: copy,
              onRetry: _load,
              flexEligible: widget.flexEligible,
              onContinue: widget.onContinue,
              onSubjectTap: widget.onSubjectTap,
              onOpenFlex: widget.onOpenFlex,
              onOpenUpdate: widget.onOpenUpdate,
              onNotifications: widget.onNotifications,
            ),
    );
  }
}

class _SeniorHomeContent extends StatelessWidget {
  const _SeniorHomeContent({
    required this.summary,
    required this.copy,
    required this.onRetry,
    required this.flexEligible,
    this.onContinue,
    this.onSubjectTap,
    this.onOpenFlex,
    this.onOpenUpdate,
    this.onNotifications,
  });

  final StudentHomeSummary summary;
  final NanoCopy copy;
  final VoidCallback onRetry;
  final bool flexEligible;
  final ValueChanged<ContinueLearningItem>? onContinue;
  final ValueChanged<LearningSubject>? onSubjectTap;
  final VoidCallback? onOpenFlex;
  final VoidCallback? onOpenUpdate;
  final VoidCallback? onNotifications;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = summary.level;
    final continueItem = summary.continueItem;
    final flex = summary.flex;
    final update = summary.latestUpdate;
    return NanoResponsiveBuilder(
      builder: (context, windowSize, _) {
        final columns = NanoResponsive.subjectColumnsFor(
          size: windowSize,
          junior: false,
        );
        return NanoMaxContentWidth(
          maxWidth: windowSize == NanoWindowSize.desktop ? 960 : 720,
          child: ListView(
            padding: const EdgeInsets.only(bottom: NanoSpacing.xxl),
            children: [
              const SizedBox(height: NanoSpacing.md),
              // CMP-03: Senior keeps the companion small and beside the header.
              // Seed 1 for the same reason as Junior: the personalised greeting
              // cannot be recorded, so home uses the one that can (ADR-0008).
              const CompanionSurfaceStage(
                surface: CompanionSurface.home,
                junior: false,
                entryEvent: CompanionEvent.home,
                seed: 1,
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          copy.greeting(summary.learnerName),
                          style: theme.textTheme.titleLarge,
                        ),
                        Text(
                          '${copy.levelLabel(level.level)} · '
                          '${summary.streakDays} ${copy.streakLabel}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  XpChip(xp: summary.xp),
                  if (onNotifications != null)
                    IconButton(
                      onPressed: onNotifications,
                      tooltip: copy.notificationsLabel,
                      icon: Badge(
                        isLabelVisible: summary.unreadNotifications > 0,
                        label: Text('${summary.unreadNotifications}'),
                        child: const Icon(Icons.notifications_outlined),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: NanoSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(NanoRadii.pill),
                child: LinearProgressIndicator(
                  value: level.fraction,
                  minHeight: 8,
                  semanticsLabel: copy.levelLabel(level.level),
                ),
              ),
              const SizedBox(height: NanoSpacing.xs),
              Text(
                copy.xpToNextLevel(level.xpToNextLevel),
                style: theme.textTheme.bodySmall,
              ),
              if (summary.notice == HomeNoticeKind.accessWarning) ...[
                const SizedBox(height: NanoSpacing.md),
                NanoOfflineBanner(message: copy.accessWarning),
              ],
              const SizedBox(height: NanoSpacing.lg),
              if (update != null)
                TeacherTaskCard(
                  title: update.title,
                  subtitle: update.body,
                  onTap: onOpenUpdate,
                )
              else if (summary.failed(HomeSection.updates))
                _SectionNotice(
                  label: copy.latestUpdate,
                  copy: copy,
                  onRetry: onRetry,
                ),
              const SizedBox(height: NanoSpacing.lg),
              if (continueItem != null)
                SeniorProgressCard(
                  title: continueItem.title,
                  tag: copy.continueBuilding,
                  progress: continueItem.progress,
                  meta: copy.percentDone(continueItem.percentComplete),
                  onTap: onContinue == null
                      ? null
                      : () => onContinue!(continueItem),
                )
              else if (summary.failed(HomeSection.continueLearning))
                _SectionNotice(
                  label: copy.continueLearning,
                  copy: copy,
                  onRetry: onRetry,
                ),
              if (flexEligible && flex != null) ...[
                const SizedBox(height: NanoSpacing.lg),
                TeacherTaskCard(
                  title: copy.flexTitle,
                  subtitle: [
                    copy.flexOpenTasks(flex.openTasks),
                    if (flex.nextDueLabel != null) flex.nextDueLabel!,
                  ].join(' · '),
                  onTap: onOpenFlex,
                ),
              ] else if (flexEligible && summary.failed(HomeSection.flex)) ...[
                const SizedBox(height: NanoSpacing.lg),
                _SectionNotice(
                  label: copy.flexTitle,
                  copy: copy,
                  onRetry: onRetry,
                ),
              ],
              const SizedBox(height: NanoSpacing.lg),
              Text(copy.todaysPlan, style: theme.textTheme.titleLarge),
              const SizedBox(height: NanoSpacing.sm),
              if (summary.plan.isNotEmpty)
                for (final item in summary.plan)
                  Padding(
                    padding: const EdgeInsets.only(bottom: NanoSpacing.sm),
                    child: TeacherTaskCard(
                      title: item.title,
                      subtitle: item.completed
                          ? '${item.subtitle} · Done'
                          : '${item.subtitle} · +${item.xpReward} XP',
                    ),
                  )
              else if (summary.failed(HomeSection.missions))
                _SectionNotice(
                  label: copy.todaysPlan,
                  copy: copy,
                  onRetry: onRetry,
                )
              else
                Text(copy.planEmpty, style: theme.textTheme.bodyMedium),
              const SizedBox(height: NanoSpacing.md),
              Text(copy.subjects, style: theme.textTheme.titleLarge),
              const SizedBox(height: NanoSpacing.sm),
              if (summary.subjects.isEmpty &&
                  summary.failed(HomeSection.subjects))
                _SectionNotice(
                  label: copy.subjects,
                  copy: copy,
                  onRetry: onRetry,
                )
              else if (columns == 1)
                for (final subject in summary.subjects)
                  Padding(
                    padding: const EdgeInsets.only(bottom: NanoSpacing.sm),
                    child: _SubjectCard(
                      subject: subject,
                      onSubjectTap: onSubjectTap,
                    ),
                  )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: summary.subjects.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: NanoSpacing.listGapSenior,
                    crossAxisSpacing: NanoSpacing.listGapSenior,
                    childAspectRatio: 1.6,
                  ),
                  itemBuilder: (context, index) => _SubjectCard(
                    subject: summary.subjects[index],
                    onSubjectTap: onSubjectTap,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject, this.onSubjectTap});

  final LearningSubject subject;
  final ValueChanged<LearningSubject>? onSubjectTap;

  @override
  Widget build(BuildContext context) {
    return SeniorProgressCard(
      title: subject.title,
      tag: subject.tag,
      progress: subject.progress,
      meta: subject.estimatedMinutes == null
          ? null
          : '${subject.estimatedMinutes} min',
      onTap: onSubjectTap == null ? null : () => onSubjectTap!(subject),
    );
  }
}

/// Inline replacement for one failed section.
class _SectionNotice extends StatelessWidget {
  const _SectionNotice({
    required this.label,
    required this.copy,
    required this.onRetry,
  });

  final String label;
  final NanoCopy copy;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(NanoSpacing.md),
        decoration: BoxDecoration(
          color: NanoColors.canvasElevated,
          borderRadius: BorderRadius.circular(NanoRadii.senior),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_outlined, size: 20),
            const SizedBox(width: NanoSpacing.sm),
            Expanded(child: Text('$label — ${copy.sectionUnavailable}')),
            TextButton(onPressed: onRetry, child: Text(copy.retryLabel)),
          ],
        ),
      ),
    );
  }
}
