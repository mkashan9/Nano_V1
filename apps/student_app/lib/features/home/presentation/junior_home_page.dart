import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// Asset paths for VIS-01 Junior Home illustrations (student_app package).
abstract final class JuniorHomeVisualAssets {
  static const avatar = 'assets/visual/junior/junior_avatar_ali.png';
  static const continueHero =
      'assets/visual/junior/junior_continue_fox_hero.png';
  static const math = 'assets/visual/junior/junior_subject_math.png';
  static const english = 'assets/visual/junior/junior_subject_english.png';
  static const science = 'assets/visual/junior/junior_subject_science.png';
  static const stories = 'assets/visual/junior/junior_subject_stories.png';

  static ImageProvider? forSubject(String subjectId) {
    return switch (subjectId) {
      'subject-math' => const AssetImage(math),
      'english' => const AssetImage(english),
      'subject-science' => const AssetImage(science),
      'stories' => const AssetImage(stories),
      _ => null,
    };
  }
}

/// STU-03 Junior Home: what happened, what to do next, how it is going —
/// composed as a few large actions with minimal reading.
///
/// VIS-01 visual layout matches `UI_reference/kids/home.jpeg` by default.
/// Set [showCompanionStage] / [showMissions] for expanded handbook surfaces.
class JuniorHomePage extends StatefulWidget {
  const JuniorHomePage({
    super.key,
    required this.repository,
    required this.learnerName,
    this.userId = 'local',
    this.companionName = 'Nori',
    this.onContinue,
    this.onSubjectTap,
    this.onNotifications,
    this.showCompanionStage = false,
    this.showMissions = false,
    this.useVisualAssets = true,
  });

  final StudentHomeRepository repository;
  final String learnerName;
  final String userId;
  final String companionName;
  final ValueChanged<ContinueLearningItem>? onContinue;
  final ValueChanged<LearningSubject>? onSubjectTap;
  final VoidCallback? onNotifications;
  final bool showCompanionStage;
  final bool showMissions;
  final bool useVisualAssets;

  @override
  State<JuniorHomePage> createState() => _JuniorHomePageState();
}

class _JuniorHomePageState extends State<JuniorHomePage> {
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
        const NanoCopy(NanoAppLocale.en);
    final summary = _summary;
    return NanoViewStateHost(
      state: _state,
      onRetry: _load,
      child: summary == null
          ? const SizedBox.shrink()
          : _JuniorHomeContent(
              summary: summary,
              copy: copy,
              onContinue: widget.onContinue,
              onSubjectTap: widget.onSubjectTap,
              onNotifications: widget.onNotifications,
              showCompanionStage: widget.showCompanionStage,
              showMissions: widget.showMissions,
              useVisualAssets: widget.useVisualAssets,
            ),
    );
  }
}

class _JuniorHomeContent extends StatelessWidget {
  const _JuniorHomeContent({
    required this.summary,
    required this.copy,
    required this.showCompanionStage,
    required this.showMissions,
    required this.useVisualAssets,
    this.onContinue,
    this.onSubjectTap,
    this.onNotifications,
  });

  final StudentHomeSummary summary;
  final NanoCopy copy;
  final bool showCompanionStage;
  final bool showMissions;
  final bool useVisualAssets;
  final ValueChanged<ContinueLearningItem>? onContinue;
  final ValueChanged<LearningSubject>? onSubjectTap;
  final VoidCallback? onNotifications;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final continueItem = summary.continueItem;
    return NanoResponsiveBuilder(
      builder: (context, windowSize, _) {
        final columns = NanoResponsive.subjectColumnsFor(
          size: windowSize,
          junior: true,
        );
        return NanoMaxContentWidth(
          child: ListView(
            padding: const EdgeInsets.only(bottom: NanoSpacing.xxl),
            children: [
              const SizedBox(height: NanoSpacing.md),
              if (showCompanionStage)
                const CompanionSurfaceStage(
                  surface: CompanionSurface.home,
                  junior: true,
                  entryEvent: CompanionEvent.home,
                  seed: 1,
                ),
              JuniorHomeHeader(
                greeting: copy.greeting(summary.learnerName),
                badgeValue: summary.streakDays,
                avatar: useVisualAssets
                    ? const AssetImage(JuniorHomeVisualAssets.avatar)
                    : null,
                onAvatarTap: onNotifications,
              ),
              if (summary.notice == HomeNoticeKind.accessWarning) ...[
                const SizedBox(height: NanoSpacing.md),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: NanoSpacing.md),
                  child: NanoOfflineBanner(message: copy.accessWarning),
                ),
              ],
              if (summary.notice == HomeNoticeKind.streakGentle) ...[
                const SizedBox(height: NanoSpacing.md),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: NanoSpacing.md),
                  child: NanoOfflineBanner(message: copy.streakWelcomeBack),
                ),
              ],
              const SizedBox(height: NanoSpacing.lg),
              if (continueItem != null)
                JuniorContinueHeroCard(
                  eyebrow: copy.isUrdu ? copy.continueLearning : 'Continue Learning',
                  title: continueItem.title,
                  startLabel: copy.startLabel,
                  illustration: useVisualAssets
                      ? const AssetImage(JuniorHomeVisualAssets.continueHero)
                      : null,
                  onStart: onContinue == null
                      ? null
                      : () => onContinue!(continueItem),
                ),
              if (showMissions && summary.juniorMissions.isNotEmpty) ...[
                const SizedBox(height: NanoSpacing.lg),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: NanoSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          copy.todaysMission,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      XpChip(
                        xp: summary.missionXpAvailable,
                        label: copy.missionXpAvailable,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: NanoSpacing.sm),
                for (final mission in summary.juniorMissions)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: NanoSpacing.md,
                      vertical: NanoSpacing.xs,
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.flag_outlined),
                      title: Text(mission.title),
                      subtitle: Text(mission.subtitle),
                      trailing: Text(
                        mission.completed ? 'Done' : '+${mission.xpReward}',
                      ),
                    ),
                  ),
              ],
              if (summary.subjects.isNotEmpty) ...[
                const SizedBox(height: NanoSpacing.lg),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: NanoSpacing.md),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: summary.subjects.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns.clamp(2, 4),
                      mainAxisSpacing: NanoSpacing.md,
                      crossAxisSpacing: NanoSpacing.md,
                      childAspectRatio: 0.95,
                    ),
                    itemBuilder: (context, index) {
                      final subject = summary.subjects[index];
                      return JuniorSubjectWorldCard(
                        title: subject.title,
                        backgroundColor: Color(subject.worldColorValue),
                        illustration: useVisualAssets
                            ? JuniorHomeVisualAssets.forSubject(subject.id)
                            : null,
                        onTap: onSubjectTap == null
                            ? null
                            : () => onSubjectTap!(subject),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
