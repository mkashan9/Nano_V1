import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// TCH-01 Dashboard: assigned scopes and pending stubs for the signed-in teacher.
class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({
    super.key,
    required this.repository,
  });

  final TeacherDashboardRepository repository;

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  NanoViewState _state = const NanoViewLoading();
  TeacherDashboard? _dashboard;

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

    return NanoViewStateHost(
      state: _state,
      onRetry: _load,
      child: dashboard == null
          ? const SizedBox.shrink()
          : Scaffold(
              body: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  copy.teacherDashboardTitle,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  copy.teacherDashboardGreeting(dashboard.teacherName),
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  copy.teacherDashboardSchool(
                    dashboard.schoolName,
                    dashboard.schoolCode,
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricChip(
                      label: copy.teacherDashboardAssignments,
                      value: '${dashboard.activeAssignmentCount}',
                    ),
                    _MetricChip(
                      label: copy.teacherDashboardPending,
                      value: '${dashboard.pendingTotal}',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  copy.teacherDashboardPendingTitle,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(copy.teacherDashboardPendingAttendance),
                  trailing: Text('${dashboard.pendingAttendanceCount}'),
                  onTap: () => context.go('/attendance'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(copy.teacherDashboardPendingDrafts),
                  trailing: Text('${dashboard.draftAssessmentCount}'),
                  onTap: () => context.go('/marks'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(copy.teacherDashboardPendingMarks),
                  trailing: Text('${dashboard.unpublishedMarksCount}'),
                  onTap: () => context.go('/marks'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(copy.teacherDashboardPendingClassroom),
                  trailing: Text('${dashboard.recentClassroomCount}'),
                  onTap: () => context.go('/classroom'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        copy.teacherDashboardScopeTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/classes'),
                      child: Text(copy.teacherDashboardOpenClasses),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (dashboard.assignments.isEmpty)
                  Text(copy.teacherDashboardScopeEmpty)
                else
                  for (final scope in dashboard.assignments)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(scope.scopeLabel),
                        subtitle: Text(scope.subjectName),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/classes'),
                      ),
                    ),
              ],
            ),
          ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
