import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// STU-03 Junior Home: what happened, what to do next, how it is going —
/// composed as a few large actions with minimal reading.
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
  });

  final StudentHomeRepository repository;
  final String learnerName;
  final String userId;
  final String companionName;
  final ValueChanged<ContinueLearningItem>? onContinue;
  final ValueChanged<LearningSubject>? onSubjectTap;
  final VoidCallback? onNotifications;

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
    // Cached data still shows content, with a timestamp above it.
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
          : _JuniorHomeContent(
              summary: summary,
              copy: copy,
              onContinue: widget.onContinue,
              onSubjectTap: widget.onSubjectTap,
              onNotifications: widget.onNotifications,
            ),
    );
  }
}

class _JuniorHomeContent extends StatelessWidget {
  const _JuniorHomeContent({
    required this.summary,
    required this.copy,
    this.onContinue,
    this.onSubjectTap,
    this.onNotifications,
  });

  final StudentHomeSummary summary;
  final NanoCopy copy;
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
              // CMP-03: Junior leads with the companion above the greeting.
              const CompanionSurfaceStage(
                surface: CompanionSurface.home,
                junior: true,
                entryEvent: CompanionEvent.home,
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          copy.greeting(summary.learnerName),
                          style: theme.textTheme.headlineMedium,
                        ),
                        Text(
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
              if (summary.notice == HomeNoticeKind.accessWarning) ...[
                const SizedBox(height: NanoSpacing.md),
                NanoOfflineBanner(message: copy.accessWarning),
              ],
              const SizedBox(height: NanoSpacing.lg),
              if (continueItem != null)
                JuniorActionCard(
                  title: continueItem.title,
                  subtitle:
                      '${copy.keepGoing} · ${copy.percentDone(continueItem.percentComplete)}',
                  backgroundColor: NanoColors.worldStories,
                  onTap: onContinue == null
                      ? null
                      : () => onContinue!(continueItem),
                ),
              if (summary.juniorMissions.isNotEmpty) ...[
                const SizedBox(height: NanoSpacing.lg),
                Row(
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
                const SizedBox(height: NanoSpacing.sm),
                for (final mission in summary.juniorMissions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: NanoSpacing.sm),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.flag_outlined),
                      title: Text(mission.title),
                      subtitle: Text(mission.subtitle),
                      trailing: Text('+${mission.xpReward}'),
                    ),
                  ),
              ],
              if (summary.subjects.isNotEmpty) ...[
                const SizedBox(height: NanoSpacing.md),
                Text(copy.subjects, style: theme.textTheme.titleLarge),
                const SizedBox(height: NanoSpacing.sm),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: summary.subjects.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: NanoSpacing.sm,
                    crossAxisSpacing: NanoSpacing.sm,
                    childAspectRatio: 1.05,
                  ),
                  itemBuilder: (context, index) {
                    final subject = summary.subjects[index];
                    return JuniorActionCard(
                      title: subject.title,
                      subtitle: subject.shortPrompt,
                      backgroundColor: Color(subject.worldColorValue),
                      onTap: onSubjectTap == null
                          ? null
                          : () => onSubjectTap!(subject),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
