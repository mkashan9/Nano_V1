import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// FLX-02 student attendance: month summary + day list (read-only).
class StudentAttendancePage extends StatefulWidget {
  const StudentAttendancePage({
    super.key,
    required this.repository,
    this.initialMonth,
  });

  final StudentAttendanceRepository repository;
  final DateTime? initialMonth;

  @override
  State<StudentAttendancePage> createState() => _StudentAttendancePageState();
}

class _StudentAttendancePageState extends State<StudentAttendancePage> {
  NanoViewState _state = const NanoViewLoading();
  StudentAttendanceSummary? _summary;
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialMonth ?? DateTime.utc(2026, 8, 1);
    _month = DateTime.utc(seed.year, seed.month, 1);
    _load();
  }

  DateTime get _from => _month;
  DateTime get _to {
    final next = DateTime.utc(_month.year, _month.month + 1, 1);
    return next.subtract(const Duration(days: 1));
  }

  String get _monthLabel {
    final mm = _month.month.toString().padLeft(2, '0');
    return '${_month.year}-$mm';
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final summary = await widget.repository.loadMine(from: _from, to: _to);
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

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime.utc(_month.year, _month.month + delta, 1);
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final theme = Theme.of(context);
    final summary = _summary;

    return NanoScaffold(
      padBody: true,
      appBar: AppBar(title: Text(copy.flexAttendanceTitle)),
      body: NanoViewStateHost(
        state: _state,
        onRetry: _load,
        child: NanoResponsiveBuilder(
          builder: (context, windowSize, _) {
            return NanoMaxContentWidth(
              maxWidth: windowSize == NanoWindowSize.desktop ? 960 : 720,
              child: ListView(
                children: [
                  Text(
                    copy.studentAttendanceSubtitle,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: NanoSpacing.md),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _shiftMonth(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Text(
                          _monthLabel,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _shiftMonth(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  if (summary != null) ...[
                    const SizedBox(height: NanoSpacing.sm),
                    Text(
                      copy.studentAttendanceCounts(
                        summary.presentCount,
                        summary.absentCount,
                        summary.lateCount,
                      ),
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: NanoSpacing.md),
                    if (summary.days.isEmpty)
                      Text(copy.studentAttendanceEmpty)
                    else
                      for (final day in summary.days)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(day.dateIso),
                          subtitle: Text(
                            [
                              if (day.classLabel != null &&
                                  day.classLabel!.isNotEmpty)
                                day.classLabel!,
                              if (day.subjectCode != null &&
                                  day.subjectCode!.isNotEmpty)
                                day.subjectCode!,
                            ].join(' · '),
                          ),
                          trailing: Text(
                            copy.teacherAttendanceStatusLabel(day.status),
                          ),
                        ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
