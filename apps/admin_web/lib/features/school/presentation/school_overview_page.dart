import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// SCH-01 school Overview: metrics, branding snapshot, setup progress.
class SchoolOverviewPage extends StatefulWidget {
  const SchoolOverviewPage({
    super.key,
    required this.repository,
  });

  final SchoolDashboardRepository repository;

  @override
  State<SchoolOverviewPage> createState() => _SchoolOverviewPageState();
}

class _SchoolOverviewPageState extends State<SchoolOverviewPage> {
  NanoViewState _state = const NanoViewLoading();
  SchoolDashboard? _dashboard;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final dashboard = await widget.repository.load();
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
                        dashboard.displayName,
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: NanoSpacing.xs),
                      Text(
                        '${dashboard.code} · ${dashboard.status}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: NanoSpacing.lg),
                      Wrap(
                        spacing: NanoSpacing.md,
                        runSpacing: NanoSpacing.md,
                        children: [
                          _metric(
                            copy.schoolMetricLearners,
                            dashboard.learnerCount,
                            Icons.school_outlined,
                          ),
                          _metric(
                            copy.schoolMetricTeachers,
                            dashboard.teacherCount,
                            Icons.badge_outlined,
                          ),
                          _metric(
                            copy.schoolMetricStaff,
                            dashboard.staffCount,
                            Icons.groups_outlined,
                          ),
                          _metric(
                            copy.schoolMetricClasses,
                            dashboard.classCount,
                            Icons.class_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: NanoSpacing.lg),
                      Text(
                        copy.schoolSetupTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: NanoSpacing.sm),
                      Text(
                        copy.schoolSetupProgress(dashboard.setupStepsDone, 4),
                      ),
                      const SizedBox(height: NanoSpacing.sm),
                      _setupRow(
                        copy.schoolSetupAdmin,
                        dashboard.setup.hasAdmin,
                      ),
                      _setupRow(
                        copy.schoolSetupBranding,
                        dashboard.setup.brandingReady,
                      ),
                      _setupRow(
                        copy.schoolSetupContact,
                        dashboard.setup.contactReady,
                      ),
                      _setupRow(
                        copy.schoolSetupYear,
                        dashboard.setup.academicYearReady,
                      ),
                      const SizedBox(height: NanoSpacing.lg),
                      Text(
                        copy.schoolBrandingTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: NanoSpacing.sm),
                      Wrap(
                        spacing: NanoSpacing.sm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _swatch(dashboard.primaryColor),
                          _swatch(dashboard.secondaryColor),
                          Text(dashboard.academicYearLabel.isEmpty
                              ? copy.schoolYearMissing
                              : dashboard.academicYearLabel),
                        ],
                      ),
                      const SizedBox(height: NanoSpacing.lg),
                      Wrap(
                        spacing: NanoSpacing.sm,
                        children: [
                          FilledButton(
                            onPressed: () => context.go('/settings'),
                            child: Text(copy.schoolEditBranding),
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

  Widget _setupRow(String label, bool done) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        done ? Icons.check_circle : Icons.radio_button_unchecked,
      ),
      title: Text(label),
    );
  }

  Widget _swatch(String hex) {
    final color = Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black26),
      ),
    );
  }
}
