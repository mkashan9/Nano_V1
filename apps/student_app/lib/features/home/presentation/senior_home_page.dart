import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/home/fixtures/senior_home_visual_fixtures.dart';
import 'package:student_app/features/home/visual/senior_home_visual_assets.dart';

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
    this.independent = false,
    this.accessEntitlements,
    this.onContinue,
    this.onSubjectTap,
    this.onOpenFlex,
    this.onOpenSpotlight,
    this.onOpenUpdate,
    this.onNotifications,
    this.useVisualLayout = true,
    this.useVisualAssets = true,
  });

  final StudentHomeRepository repository;
  final String learnerName;
  final String userId;
  final String companionName;

  /// Client-side guard on top of the server entitlement. Independent learners
  /// never reach the Flex card.
  final bool flexEligible;

  /// IND-01: independent home fills the Flex slot with a play/learn spotlight.
  final bool independent;

  /// IND-02: access tier drives the calm warning banner for independents.
  final IndependentEntitlements? accessEntitlements;
  final ValueChanged<ContinueLearningItem>? onContinue;
  final ValueChanged<LearningSubject>? onSubjectTap;
  final VoidCallback? onOpenFlex;
  final ValueChanged<IndependentSpotlight>? onOpenSpotlight;
  final VoidCallback? onOpenUpdate;
  final VoidCallback? onNotifications;

  /// VIS-05 reference layout. Set false to keep the STU-04 denser list chrome.
  final bool useVisualLayout;
  final bool useVisualAssets;

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
        independent: widget.independent,
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
              independent: widget.independent,
              accessEntitlements: widget.accessEntitlements,
              onContinue: widget.onContinue,
              onSubjectTap: widget.onSubjectTap,
              onOpenFlex: widget.onOpenFlex,
              onOpenSpotlight: widget.onOpenSpotlight,
              onOpenUpdate: widget.onOpenUpdate,
              onNotifications: widget.onNotifications,
              useVisualLayout: widget.useVisualLayout,
              useVisualAssets: widget.useVisualAssets,
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
    required this.independent,
    required this.useVisualLayout,
    required this.useVisualAssets,
    this.accessEntitlements,
    this.onContinue,
    this.onSubjectTap,
    this.onOpenFlex,
    this.onOpenSpotlight,
    this.onOpenUpdate,
    this.onNotifications,
  });

  final StudentHomeSummary summary;
  final NanoCopy copy;
  final VoidCallback onRetry;
  final bool flexEligible;
  final bool independent;
  final bool useVisualLayout;
  final bool useVisualAssets;
  final IndependentEntitlements? accessEntitlements;
  final ValueChanged<ContinueLearningItem>? onContinue;
  final ValueChanged<LearningSubject>? onSubjectTap;
  final VoidCallback? onOpenFlex;
  final ValueChanged<IndependentSpotlight>? onOpenSpotlight;
  final VoidCallback? onOpenUpdate;
  final VoidCallback? onNotifications;

  @override
  Widget build(BuildContext context) {
    if (useVisualLayout) {
      return _SeniorVisualHome(
        summary: summary,
        useVisualAssets: useVisualAssets,
        onContinue: onContinue,
        onNotifications: onNotifications,
      );
    }
    return _buildLegacy(context);
  }

  Widget _buildLegacy(BuildContext context) {
    final theme = Theme.of(context);
    final level = summary.level;
    final continueItem = summary.continueItem;
    final flex = summary.flex;
    final update = summary.latestUpdate;
    final spotlight = summary.independentSpotlight;
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
              if (summary.notice == HomeNoticeKind.accessWarning ||
                  (accessEntitlements?.showsAccessWarning ?? false)) ...[
                const SizedBox(height: NanoSpacing.md),
                NanoOfflineBanner(
                  message: accessEntitlements?.isReduced == true
                      ? copy.accessReducedWarning
                      : copy.accessWarning,
                ),
              ],
              if (summary.notice == HomeNoticeKind.streakGentle) ...[
                const SizedBox(height: NanoSpacing.md),
                NanoOfflineBanner(message: copy.streakWelcomeBack),
              ],
              const SizedBox(height: NanoSpacing.lg),
              if (!independent && update != null)
                TeacherTaskCard(
                  title: update.title,
                  subtitle: update.body,
                  onTap: onOpenUpdate,
                )
              else if (!independent && summary.failed(HomeSection.updates))
                _SectionNotice(
                  label: copy.latestUpdate,
                  copy: copy,
                  onRetry: onRetry,
                ),
              if (!independent &&
                  (update != null || summary.failed(HomeSection.updates)))
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
              ] else if (independent && spotlight != null) ...[
                const SizedBox(height: NanoSpacing.lg),
                TeacherTaskCard(
                  title: copy.independentSpotlightTag(spotlight.kind),
                  subtitle: '${spotlight.title} — ${spotlight.body}',
                  onTap: onOpenSpotlight == null
                      ? null
                      : () => onOpenSpotlight!(spotlight),
                ),
              ] else if (independent &&
                  summary.failed(HomeSection.independentSpotlight)) ...[
                const SizedBox(height: NanoSpacing.lg),
                _SectionNotice(
                  label: copy.independentSpotlightTitle,
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

class _SeniorVisualHome extends StatelessWidget {
  const _SeniorVisualHome({
    required this.summary,
    required this.useVisualAssets,
    this.onContinue,
    this.onNotifications,
  });

  final StudentHomeSummary summary;
  final bool useVisualAssets;
  final ValueChanged<ContinueLearningItem>? onContinue;
  final VoidCallback? onNotifications;

  @override
  Widget build(BuildContext context) {
    final continueItem = summary.continueItem;
    return ColoredBox(
      color: NanoColors.canvas,
      child: ListView(
        padding: const EdgeInsets.only(bottom: NanoSpacing.xxl),
        children: [
          const SizedBox(height: NanoSpacing.md),
          SeniorHomeHeader(
            headlinePrefix: SeniorHomeVisualFixtures.headlinePrefix,
            headlineAccent: SeniorHomeVisualFixtures.headlineAccent,
            streakDays: SeniorHomeVisualFixtures.streakDays,
            streakCaption: SeniorHomeVisualFixtures.streakCaption,
            rankTitle: SeniorHomeVisualFixtures.rankTitle,
            rankLabel: SeniorHomeVisualFixtures.rankLabel,
            avatar: useVisualAssets
                ? const AssetImage(SeniorHomeVisualAssets.avatar)
                : null,
            hasUnread: summary.unreadNotifications > 0,
            onNotifications: onNotifications,
          ),
          const SizedBox(height: NanoSpacing.lg),
          SeniorContinueHeroCard(
            eyebrow: SeniorHomeVisualFixtures.continueEyebrow,
            title: SeniorHomeVisualFixtures.continueTitle,
            projectTitle: SeniorHomeVisualFixtures.projectTitle,
            progress: SeniorHomeVisualFixtures.projectProgress,
            continueLabel: SeniorHomeVisualFixtures.continueLabel,
            illustration: useVisualAssets
                ? const AssetImage(SeniorHomeVisualAssets.continueHero)
                : null,
            onContinue: continueItem == null || onContinue == null
                ? null
                : () => onContinue!(continueItem),
          ),
          const SizedBox(height: NanoSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: NanoSpacing.md),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "Today's Mission",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFFB39DFF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: NanoSpacing.sm),
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: NanoSpacing.md),
              itemCount: SeniorHomeVisualFixtures.missions.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: NanoSpacing.sm),
              itemBuilder: (context, index) {
                final m = SeniorHomeVisualFixtures.missions[index];
                return SeniorMissionChipCard(
                  kindLabel: m.kind,
                  title: m.title,
                  xpLabel: 'Earn ${m.xp} XP',
                  progressLabel: m.progress,
                  accent: m.accent,
                  icon: m.icon,
                );
              },
            ),
          ),
          const SizedBox(height: NanoSpacing.lg),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: NanoSpacing.md),
            child: Text(
              'Builder Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: NanoSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: NanoSpacing.md),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: SeniorHomeVisualFixtures.dashboard.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: NanoSpacing.sm,
                crossAxisSpacing: NanoSpacing.sm,
                childAspectRatio: 1.55,
              ),
              itemBuilder: (context, index) {
                final s = SeniorHomeVisualFixtures.dashboard[index];
                final value = index == 0 ? '${summary.xp} XP' : s.value;
                return SeniorDashboardStatCard(
                  value: value,
                  label: s.label,
                  accent: s.accent,
                  icon: s.icon,
                );
              },
            ),
          ),
          const SizedBox(height: NanoSpacing.lg),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: NanoSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Continue Learning',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFFB39DFF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: NanoSpacing.sm),
          for (final item in SeniorHomeVisualFixtures.learning)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                NanoSpacing.md,
                0,
                NanoSpacing.md,
                NanoSpacing.sm,
              ),
              child: SeniorLearningRowCard(
                title: item.title,
                subjectTag: item.tag,
                progress: item.progress,
                difficultyLabel: item.difficulty,
                timeLabel: item.time,
                accent: item.accent,
                icon: item.icon,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: NanoSpacing.md),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Build Challenge',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                Text(
                  SeniorHomeVisualFixtures.challengeTimer,
                  style: const TextStyle(
                    color: Color(0xFFB39DFF),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: NanoSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: NanoSpacing.md),
            child: SeniorChallengeCard(
              badgeLabel: SeniorHomeVisualFixtures.challengeBadge,
              title: SeniorHomeVisualFixtures.challengeTitle,
              body: SeniorHomeVisualFixtures.challengeBody,
              rewardLabel: SeniorHomeVisualFixtures.challengeReward,
              illustration: useVisualAssets
                  ? const AssetImage(SeniorHomeVisualAssets.challengeCalc)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

// Legacy STU-04 helpers below.

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
