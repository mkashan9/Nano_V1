import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// ATT-01/ATT-02 Attendance: grid entry plus CSV/Excel-compatible import.
class TeacherAttendancePage extends StatefulWidget {
  const TeacherAttendancePage({
    super.key,
    required this.repository,
    this.initialAssignmentId,
  });

  final TeacherAttendanceRepository repository;
  final String? initialAssignmentId;

  @override
  State<TeacherAttendancePage> createState() => _TeacherAttendancePageState();
}

class _TeacherAttendancePageState extends State<TeacherAttendancePage> {
  NanoViewState _state = const NanoViewLoading();
  TeacherMyClasses? _mine;
  TeacherAttendanceGrid? _grid;
  String? _assignmentId;
  late DateTime _date;
  final Map<String, AttendanceEntryStatus> _draft = {};
  final _csv = TextEditingController();
  AttendanceImportPreview? _preview;
  var _submitting = false;
  var _importBusy = false;
  String? _message;
  String? _importKey;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now().toUtc();
    _assignmentId = widget.initialAssignmentId;
    _bootstrap();
  }

  @override
  void dispose() {
    _csv.dispose();
    super.dispose();
  }

  String get _dateIso =>
      '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  Future<void> _bootstrap() async {
    setState(() {
      _state = const NanoViewLoading();
      _message = null;
    });
    try {
      final mine = await widget.repository.listAssignments();
      if (!mounted) return;
      final selected = _assignmentId ??
          (mine.assignments.isEmpty ? null : mine.assignments.first.id);
      setState(() {
        _mine = mine;
        _assignmentId = selected;
      });
      if (selected != null) {
        await _loadGrid(selected);
      } else {
        setState(() => _state = const NanoViewReady());
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  Future<void> _loadGrid(String assignmentId) async {
    setState(() {
      _state = const NanoViewLoading();
      _message = null;
    });
    try {
      final grid = await widget.repository.load(
        assignmentId: assignmentId,
        sessionDate: _dateIso,
      );
      if (!mounted) return;
      setState(() {
        _assignmentId = assignmentId;
        _grid = grid;
        _draft
          ..clear()
          ..addAll({
            for (final s in grid.roster)
              s.id: grid.statusByStudent[s.id] ?? AttendanceEntryStatus.present,
          });
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  void _markAllPresent() {
    setState(() {
      for (final id in _draft.keys) {
        _draft[id] = AttendanceEntryStatus.present;
      }
    });
  }

  Future<void> _submit() async {
    final assignmentId = _assignmentId;
    if (assignmentId == null || _submitting) return;
    if (_grid?.isSubmitted ?? false) return;
    setState(() {
      _submitting = true;
      _message = null;
    });
    try {
      final key =
          'att-$assignmentId-$_dateIso-${DateTime.now().millisecondsSinceEpoch}';
      final grid = await widget.repository.submit(
        assignmentId: assignmentId,
        sessionDate: _dateIso,
        idempotencyKey: key,
        entries: [
          for (final e in _draft.entries)
            AttendanceEntryMark(studentUserId: e.key, status: e.value),
        ],
      );
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          const NanoCopy(NanoAppLocale.en);
      setState(() {
        _grid = grid;
        _draft
          ..clear()
          ..addAll(grid.statusByStudent);
        _submitting = false;
        _message = copy.teacherAttendanceSubmitted;
      });
    } catch (_) {
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          const NanoCopy(NanoAppLocale.en);
      setState(() {
        _submitting = false;
        _message = copy.teacherAttendanceSubmitFailed;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_date.year, _date.month, _date.day),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = DateTime.utc(picked.year, picked.month, picked.day);
      _preview = null;
      _importKey = null;
    });
    final id = _assignmentId;
    if (id != null) await _loadGrid(id);
  }

  Future<void> _loadTemplate() async {
    final assignmentId = _assignmentId;
    if (assignmentId == null || _importBusy) return;
    setState(() => _importBusy = true);
    try {
      final template = await widget.repository.loadTemplate(
        assignmentId: assignmentId,
        sessionDate: _dateIso,
      );
      if (!mounted) return;
      setState(() {
        _csv.text = template.csvText;
        _preview = null;
        _importBusy = false;
        _message = null;
      });
    } catch (_) {
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          const NanoCopy(NanoAppLocale.en);
      setState(() {
        _importBusy = false;
        _message = copy.teacherAttendanceImportFailed;
      });
    }
  }

  Future<void> _previewImport() async {
    final assignmentId = _assignmentId;
    if (assignmentId == null || _importBusy) return;
    setState(() {
      _importBusy = true;
      _message = null;
    });
    try {
      _importKey ??=
          'att-import-$assignmentId-$_dateIso-${DateTime.now().millisecondsSinceEpoch}';
      final preview = await widget.repository.previewImport(
        assignmentId: assignmentId,
        sessionDate: _dateIso,
        idempotencyKey: _importKey!,
        rows: AttendanceImportCsv.parse(_csv.text),
      );
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          const NanoCopy(NanoAppLocale.en);
      setState(() {
        _preview = preview;
        _importBusy = false;
        _message = copy.teacherAttendanceImportPreviewSummary(
          preview.okCount,
          preview.failCount,
        );
      });
    } catch (_) {
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          const NanoCopy(NanoAppLocale.en);
      setState(() {
        _importBusy = false;
        _message = copy.teacherAttendanceImportFailed;
      });
    }
  }

  Future<void> _commitImport() async {
    final assignmentId = _assignmentId;
    final key = _importKey;
    if (assignmentId == null || key == null || _importBusy) return;
    if (!(_preview?.canCommit ?? false)) return;
    setState(() => _importBusy = true);
    try {
      final result = await widget.repository.commitImport(
        assignmentId: assignmentId,
        sessionDate: _dateIso,
        idempotencyKey: key,
        rows: AttendanceImportCsv.parse(_csv.text),
      );
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          const NanoCopy(NanoAppLocale.en);
      setState(() {
        _grid = result.grid;
        _draft
          ..clear()
          ..addAll(result.grid.statusByStudent);
        _preview = result.preview;
        _importBusy = false;
        _message = copy.teacherAttendanceImportCommitted;
      });
    } catch (_) {
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          const NanoCopy(NanoAppLocale.en);
      setState(() {
        _importBusy = false;
        _message = copy.teacherAttendanceImportFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final theme = Theme.of(context);
    final mine = _mine;
    final grid = _grid;
    final submitted = grid?.isSubmitted ?? false;

    return NanoViewStateHost(
      state: _state,
      onRetry: _bootstrap,
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(copy.teacherAttendanceTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              copy.teacherAttendanceSubtitle,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (mine == null || mine.assignments.isEmpty)
              Text(copy.teacherAttendanceNoAssignments)
            else ...[
              DropdownButtonFormField<String>(
                value: _assignmentId,
                decoration: InputDecoration(
                  labelText: copy.teacherAttendanceAssignmentLabel,
                ),
                items: [
                  for (final a in mine.assignments)
                    DropdownMenuItem(
                      value: a.id,
                      child: Text(a.scopeLabel),
                    ),
                ],
                onChanged: submitted
                    ? null
                    : (id) {
                        if (id != null) _loadGrid(id);
                      },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(copy.teacherAttendanceDateLabel),
                subtitle: Text(_dateIso),
                trailing: IconButton(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                ),
              ),
              if (grid != null) ...[
                Text(grid.scopeLabel, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: submitted ? null : _markAllPresent,
                      child: Text(copy.teacherAttendanceMarkAllPresent),
                    ),
                    FilledButton(
                      onPressed: submitted || _submitting ? null : _submit,
                      child: Text(
                        submitted
                            ? copy.teacherAttendanceAlreadySubmitted
                            : copy.teacherAttendanceSubmit,
                      ),
                    ),
                  ],
                ),
                if (_message != null) ...[
                  const SizedBox(height: 8),
                  Text(_message!, style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: 16),
                if (grid.roster.isEmpty)
                  Text(copy.teacherAttendanceRosterEmpty)
                else
                  for (final student in grid.roster)
                    _AttendanceRow(
                      name: student.displayName.trim().isEmpty
                          ? copy.teacherClassesStudentFallback
                          : student.displayName,
                      status: _draft[student.id] ??
                          AttendanceEntryStatus.present,
                      enabled: !submitted,
                      labelFor: copy.teacherAttendanceStatusLabel,
                      onCycle: () {
                        setState(() {
                          final current = _draft[student.id] ??
                              AttendanceEntryStatus.present;
                          _draft[student.id] = current.next;
                        });
                      },
                    ),
                const SizedBox(height: 24),
                Text(
                  copy.teacherAttendanceImportTitle,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  copy.teacherAttendanceImportSubtitle,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _csv,
                  minLines: 4,
                  maxLines: 8,
                  enabled: !submitted,
                  decoration: InputDecoration(
                    labelText: copy.teacherAttendanceImportCsvLabel,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: submitted || _importBusy ? null : _loadTemplate,
                      child: Text(copy.teacherAttendanceLoadTemplate),
                    ),
                    OutlinedButton(
                      onPressed: submitted || _csv.text.isEmpty
                          ? null
                          : () async {
                              await Clipboard.setData(
                                ClipboardData(text: _csv.text),
                              );
                            },
                      child: Text(copy.teacherAttendanceCopyCsv),
                    ),
                    OutlinedButton(
                      onPressed:
                          submitted || _importBusy ? null : _previewImport,
                      child: Text(copy.teacherAttendancePreviewImport),
                    ),
                    FilledButton(
                      onPressed: submitted ||
                              _importBusy ||
                              !(_preview?.canCommit ?? false)
                          ? null
                          : _commitImport,
                      child: Text(copy.teacherAttendanceCommitImport),
                    ),
                  ],
                ),
                if (_preview != null && _preview!.failedRows.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final fail in _preview!.failedRows.take(5))
                    Text(
                      copy.teacherAttendanceImportRowError(
                        fail.row,
                        fail.error,
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({
    required this.name,
    required this.status,
    required this.enabled,
    required this.labelFor,
    required this.onCycle,
  });

  final String name;
  final AttendanceEntryStatus status;
  final bool enabled;
  final String Function(AttendanceEntryStatus) labelFor;
  final VoidCallback onCycle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(name),
      subtitle: Text(labelFor(status)),
      trailing: TextButton(
        onPressed: enabled ? onCycle : null,
        child: Text(labelFor(status)),
      ),
    );
  }
}
