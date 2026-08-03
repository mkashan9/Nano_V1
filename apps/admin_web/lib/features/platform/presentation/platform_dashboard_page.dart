import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// ADM-01 Platform home: safe metrics, school directory search, audit preview.
class PlatformDashboardPage extends StatefulWidget {
  const PlatformDashboardPage({
    super.key,
    required this.repository,
  });

  final PlatformDashboardRepository repository;

  @override
  State<PlatformDashboardPage> createState() => _PlatformDashboardPageState();
}

class _PlatformDashboardPageState extends State<PlatformDashboardPage> {
  NanoViewState _state = const NanoViewLoading();
  PlatformDashboard? _dashboard;
  final _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final dashboard = await widget.repository.load(query: _query.text);
      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
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
    final dashboard = _dashboard;

    return NanoScaffold(
      padBody: true,
      body: NanoViewStateHost(
        state: _state,
        onRetry: _load,
        child: dashboard == null
            ? const SizedBox.shrink()
            : Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: ListView(
                    children: [
                      Text(
                        copy.platformDashboardTitle,
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: NanoSpacing.xs),
                      Text(
                        copy.platformDashboardSubtitle,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: NanoSpacing.lg),
                      Wrap(
                        spacing: NanoSpacing.md,
                        runSpacing: NanoSpacing.md,
                        children: [
                          SizedBox(
                            width: 200,
                            child: AdminMetricCard(
                              label: copy.platformMetricSchools,
                              value: '${dashboard.schoolCount}',
                              icon: Icons.apartment_outlined,
                            ),
                          ),
                          SizedBox(
                            width: 200,
                            child: AdminMetricCard(
                              label: copy.platformMetricActiveSchools,
                              value: '${dashboard.activeSchoolCount}',
                              icon: Icons.check_circle_outline,
                            ),
                          ),
                          SizedBox(
                            width: 200,
                            child: AdminMetricCard(
                              label: copy.platformMetricLearners,
                              value: '${dashboard.learnerCount}',
                              icon: Icons.school_outlined,
                            ),
                          ),
                          SizedBox(
                            width: 200,
                            child: AdminMetricCard(
                              label: copy.platformMetricStaff,
                              value: '${dashboard.staffCount}',
                              icon: Icons.badge_outlined,
                            ),
                          ),
                          SizedBox(
                            width: 200,
                            child: AdminMetricCard(
                              label: copy.platformMetricSuspended,
                              value: '${dashboard.suspendedProfileCount}',
                              icon: Icons.person_off_outlined,
                            ),
                          ),
                          SizedBox(
                            width: 200,
                            child: AdminMetricCard(
                              label: copy.platformMetricIncidents,
                              value: '${dashboard.openIncidentCount}',
                              icon: Icons.report_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: NanoSpacing.lg),
                      Text(
                        copy.platformShortcutsTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: NanoSpacing.sm),
                      Wrap(
                        spacing: NanoSpacing.sm,
                        children: [
                          OutlinedButton(
                            onPressed: () => context.go('/content'),
                            child: Text(copy.content),
                          ),
                          OutlinedButton(
                            onPressed: () => context.go('/moderation'),
                            child: Text(copy.moderation),
                          ),
                          OutlinedButton(
                            onPressed: () => context.go('/schools'),
                            child: Text(copy.schools),
                          ),
                          OutlinedButton(
                            onPressed: () => context.go('/audit'),
                            child: Text(copy.audit),
                          ),
                          OutlinedButton(
                            onPressed: () => context.go('/pilot'),
                            child: Text(copy.pilot),
                          ),
                        ],
                      ),
                      const SizedBox(height: NanoSpacing.lg),
                      Text(
                        copy.platformSchoolsTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: NanoSpacing.sm),
                      TextField(
                        controller: _query,
                        decoration: InputDecoration(
                          hintText: copy.platformSchoolSearchHint,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            tooltip: copy.retryLabel,
                            onPressed: _load,
                            icon: const Icon(Icons.refresh),
                          ),
                        ),
                        onSubmitted: (_) => _load(),
                      ),
                      const SizedBox(height: NanoSpacing.sm),
                      if (dashboard.schools.isEmpty)
                        Text(
                          copy.platformSchoolsEmpty,
                          style: theme.textTheme.bodyMedium,
                        )
                      else
                        for (final school in dashboard.schools)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.apartment_outlined),
                            title: Text(school.name),
                            subtitle: Text(
                              '${school.code} · ${school.status} · '
                              '${school.learnerCount} ${copy.platformMetricLearners.toLowerCase()} · '
                              '${school.staffCount} ${copy.platformMetricStaff.toLowerCase()}',
                            ),
                          ),
                      const SizedBox(height: NanoSpacing.lg),
                      Text(
                        copy.platformAuditTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: NanoSpacing.sm),
                      if (dashboard.recentAudit.isEmpty)
                        Text(
                          copy.platformAuditEmpty,
                          style: theme.textTheme.bodyMedium,
                        )
                      else
                        for (final entry in dashboard.recentAudit)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.history),
                            title: Text('${entry.action} · ${entry.targetType}'),
                            subtitle: Text(
                              [
                                if (entry.schoolCode != null) entry.schoolCode!,
                                entry.createdAt.toIso8601String(),
                              ].join(' · '),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
