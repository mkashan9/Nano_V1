import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// FLX-03 student marks: month list of published/corrected results.
class StudentMarksPage extends StatefulWidget {
  const StudentMarksPage({
    super.key,
    required this.repository,
    this.initialMonth,
  });

  final StudentMarksRepository repository;
  final DateTime? initialMonth;

  @override
  State<StudentMarksPage> createState() => _StudentMarksPageState();
}

class _StudentMarksPageState extends State<StudentMarksPage> {
  NanoViewState _state = const NanoViewLoading();
  StudentMarksSummary? _summary;
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
      appBar: AppBar(title: Text(copy.flexMarksTitle)),
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
                    copy.studentMarksSubtitle,
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
                      copy.studentMarksCounts(
                        summary.scoredCount,
                        summary.absentCount,
                      ),
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: NanoSpacing.md),
                    if (summary.results.isEmpty)
                      Text(copy.studentMarksEmpty)
                    else
                      for (final result in summary.results)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(result.name),
                          subtitle: Text(
                            [
                              result.dateIso,
                              if (result.subjectCode != null &&
                                  result.subjectCode!.isNotEmpty)
                                result.subjectCode!,
                              if (result.wasCorrected)
                                copy.studentMarksCorrectedBadge,
                            ].join(' · '),
                          ),
                          trailing: Text(
                            copy.teacherMarksStatusValueLabel(
                              result.entryStatus,
                              result.obtainedMarks,
                            ),
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
