import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// ADM-08 Analytics hub: safe platform aggregates and 7-day activity.
class PlatformAnalyticsPage extends StatefulWidget {
  const PlatformAnalyticsPage({
    super.key,
    required this.repository,
  });

  final PlatformAnalyticsRepository repository;

  @override
  State<PlatformAnalyticsPage> createState() => _PlatformAnalyticsPageState();
}

class _PlatformAnalyticsPageState extends State<PlatformAnalyticsPage> {
  NanoViewState _state = const NanoViewLoading();
  PlatformAnalytics? _analytics;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final analytics = await widget.repository.load();
      if (!mounted) return;
      setState(() {
        _analytics = analytics;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final theme = Theme.of(context);
    final analytics = _analytics;

    return NanoScaffold(
      padBody: true,
      body: NanoViewStateHost(
        state: _state,
        onRetry: _load,
        child: analytics == null
            ? const SizedBox.shrink()
            : Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: ListView(
                    children: [
                      Text(
                        copy.analyticsPageTitle,
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: NanoSpacing.xs),
                      Text(
                        copy.analyticsPageSubtitle,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: NanoSpacing.lg),
                      Text(
                        copy.analyticsHealthTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: NanoSpacing.sm),
                      Wrap(
                        spacing: NanoSpacing.md,
                        runSpacing: NanoSpacing.md,
                        children: [
                          _metric(
                            copy.analyticsActiveSchools,
                            analytics.activeSchoolCount,
                            Icons.apartment_outlined,
                          ),
                          _metric(
                            copy.analyticsSuspendedSchools,
                            analytics.suspendedSchoolCount,
                            Icons.block_outlined,
                          ),
                          _metric(
                            copy.analyticsActiveLearners,
                            analytics.activeLearnerCount,
                            Icons.school_outlined,
                          ),
                          _metric(
                            copy.analyticsIndependentLearners,
                            analytics.independentLearnerCount,
                            Icons.person_outline,
                          ),
                          _metric(
                            copy.analyticsOpenIncidents,
                            analytics.openIncidentCount,
                            Icons.report_outlined,
                          ),
                          _metric(
                            copy.analyticsAssetsReview,
                            analytics.assetsAwaitingReview,
                            Icons.gavel_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: NanoSpacing.lg),
                      Text(
                        copy.analyticsCatalogTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: NanoSpacing.sm),
                      Wrap(
                        spacing: NanoSpacing.md,
                        runSpacing: NanoSpacing.md,
                        children: [
                          _metric(
                            copy.analyticsPublishedSubjects,
                            analytics.publishedSubjectCount,
                            Icons.library_books_outlined,
                          ),
                          _metric(
                            copy.analyticsPublishedTopics,
                            analytics.publishedTopicCount,
                            Icons.menu_book_outlined,
                          ),
                          _metric(
                            copy.analyticsLiveGames,
                            analytics.liveGameCount,
                            Icons.sports_esports_outlined,
                          ),
                          _metric(
                            copy.analyticsLiveNotifications,
                            analytics.publishedNotificationCount,
                            Icons.notifications_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: NanoSpacing.lg),
                      Text(
                        copy.analyticsActivityTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: NanoSpacing.sm),
                      Wrap(
                        spacing: NanoSpacing.md,
                        runSpacing: NanoSpacing.md,
                        children: [
                          _metric(
                            copy.analyticsTopicCompletions,
                            analytics.topicCompletions7d,
                            Icons.check_circle_outline,
                          ),
                          _metric(
                            copy.analyticsXpAwards,
                            analytics.xpAwards7d,
                            Icons.emoji_events_outlined,
                          ),
                          _metric(
                            copy.analyticsQuizPasses,
                            analytics.quizPasses7d,
                            Icons.quiz_outlined,
                          ),
                          _metric(
                            copy.analyticsAuditEvents,
                            analytics.auditEvents7d,
                            Icons.history_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: NanoSpacing.lg),
                      Text(
                        copy.analyticsActionsTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: NanoSpacing.sm),
                      if (analytics.actionBreakdown7d.isEmpty)
                        Text(copy.analyticsActionsEmpty)
                      else
                        for (final row in analytics.actionBreakdown7d)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(row.action),
                            trailing: Text('${row.eventCount}'),
                          ),
                      const SizedBox(height: NanoSpacing.lg),
                      Wrap(
                        spacing: NanoSpacing.sm,
                        children: [
                          OutlinedButton(
                            onPressed: () => context.go('/'),
                            child: Text(copy.platform),
                          ),
                          OutlinedButton(
                            onPressed: () => context.go('/moderation'),
                            child: Text(copy.moderation),
                          ),
                          OutlinedButton(
                            onPressed: _load,
                            child: Text(copy.tryAgain),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _metric(String label, int value, IconData icon) {
    return SizedBox(
      width: 200,
      child: AdminMetricCard(
        label: label,
        value: '$value',
        icon: icon,
      ),
    );
  }
}
