import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// SCH-07 Reports destination: privacy-safe school operational summary.
class SchoolReportsPage extends StatefulWidget {
  const SchoolReportsPage({
    super.key,
    required this.repository,
  });

  final SchoolReportsRepository repository;

  @override
  State<SchoolReportsPage> createState() => _SchoolReportsPageState();
}

class _SchoolReportsPageState extends State<SchoolReportsPage> {
  NanoViewState _state = const NanoViewLoading();
  SchoolReportsSummary? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final summary = await widget.repository.load();
      if (!mounted) return;
      setState(() {
        _summary = summary;
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
    final summary = _summary;

    return NanoViewStateHost(
      state: _state,
      onRetry: _load,
      child: Scaffold(
        body: summary == null
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    copy.reportsPageTitle,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    copy.reportsPageSubtitle,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (summary.generatedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      copy.reportsGeneratedAt(
                        summary.generatedAt!.toUtc().toIso8601String(),
                      ),
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _MetricCard(
                        label: copy.reportsLearners,
                        value: '${summary.learnerCount}',
                      ),
                      _MetricCard(
                        label: copy.reportsTeachers,
                        value: '${summary.teacherCount}',
                      ),
                      _MetricCard(
                        label: copy.reportsClasses,
                        value: '${summary.classCount}',
                      ),
                      _MetricCard(
                        label: copy.reportsSubjects,
                        value: '${summary.subjectCount}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    copy.reportsCoverageTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(copy.reportsActiveAssignments),
                    trailing: Text('${summary.activeAssignmentCount}'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(copy.reportsUncovered),
                    trailing: Text('${summary.uncoveredClassSubjectCount}'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(copy.reportsTeachersAssigned),
                    trailing: Text('${summary.teachersWithAssignmentCount}'),
                  ),
                  if (summary.hasCoverageGap)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        copy.reportsCoverageGapHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    copy.reportsEnrollmentTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(copy.reportsStudentsWithClass),
                    trailing: Text('${summary.studentsWithClassCount}'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(copy.reportsStudentsWithoutClass),
                    trailing: Text('${summary.studentsWithoutClassCount}'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    copy.reportsResultsTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(copy.reportsOpenPeriods),
                    trailing: Text('${summary.openPeriodCount}'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(copy.reportsClosedPeriods),
                    trailing: Text('${summary.closedPeriodCount}'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(copy.reportsPassingPercent),
                    trailing: Text(
                      '${summary.passingPercent.toStringAsFixed(0)}%',
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(copy.reportsAttendanceMode),
                    trailing: Text(summary.attendanceMode),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    copy.reportsWorkloadTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (summary.teacherWorkload.isEmpty)
                    Text(copy.reportsWorkloadEmpty)
                  else
                    for (final row in summary.teacherWorkload)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(row.displayName),
                        trailing: Text(
                          copy.reportsWorkloadValue(row.activeCount),
                        ),
                      ),
                ],
              ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          Text(value, style: theme.textTheme.titleLarge),
        ],
      ),
    );
  }
}
