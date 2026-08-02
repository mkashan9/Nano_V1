import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// MRK-01–MRK-04 Marks: drafts, grid, CSV import, publish, and corrections.
class TeacherMarksPage extends StatefulWidget {
  const TeacherMarksPage({
    super.key,
    required this.repository,
    this.initialAssignmentId,
  });

  final TeacherAssessmentRepository repository;
  final String? initialAssignmentId;

  @override
  State<TeacherMarksPage> createState() => _TeacherMarksPageState();
}

class _TeacherMarksPageState extends State<TeacherMarksPage> {
  NanoViewState _state = const NanoViewLoading();
  TeacherMyClasses? _mine;
  TeacherAssessmentList? _list;
  TeacherMarksGrid? _grid;
  String? _assignmentId;
  String? _editingId;
  String? _gridAssessmentId;
  final _category = TextEditingController(text: 'Quiz');
  final _name = TextEditingController();
  final _total = TextEditingController(text: '100');
  final _weight = TextEditingController();
  final _description = TextEditingController();
  final Map<String, TextEditingController> _scoreCtrls = {};
  final Map<String, TextEditingController> _remarkCtrls = {};
  final Map<String, MarksEntryStatus> _statusDraft = {};
  final _csv = TextEditingController();
  MarksImportPreview? _importPreview;
  String? _importKey;
  MarksCorrectionHistory? _history;
  final _reason = TextEditingController();
  late DateTime _date;
  var _saving = false;
  var _savingMarks = false;
  var _importBusy = false;
  var _publishing = false;
  var _correcting = false;
  String? _message;

  static const _categories = [
    'Quiz',
    'Homework',
    'Midterm',
    'Final',
    'Project',
    'Oral',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _date = DateTime.now().toUtc();
    _assignmentId = widget.initialAssignmentId;
    _bootstrap();
  }

  @override
  void dispose() {
    _category.dispose();
    _name.dispose();
    _total.dispose();
    _weight.dispose();
    _description.dispose();
    _csv.dispose();
    _reason.dispose();
    _disposeGridCtrls();
    super.dispose();
  }

  void _disposeGridCtrls() {
    for (final c in _scoreCtrls.values) {
      c.dispose();
    }
    for (final c in _remarkCtrls.values) {
      c.dispose();
    }
    _scoreCtrls.clear();
    _remarkCtrls.clear();
    _statusDraft.clear();
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
        await _loadList(selected);
      } else {
        setState(() => _state = const NanoViewReady());
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  Future<void> _loadList(String assignmentId) async {
    setState(() {
      _state = const NanoViewLoading();
      _message = null;
    });
    try {
      final list = await widget.repository.listForAssignment(assignmentId);
      if (!mounted) return;
      setState(() {
        _assignmentId = assignmentId;
        _list = list;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  void _resetForm() {
    _editingId = null;
    _category.text = 'Quiz';
    _name.clear();
    _total.text = '100';
    _weight.clear();
    _description.clear();
    _date = DateTime.now().toUtc();
  }

  void _edit(TeacherAssessment assessment) {
    setState(() {
      _editingId = assessment.id;
      _category.text = assessment.category;
      _name.text = assessment.name;
      _total.text = assessment.totalMarks.toString();
      _weight.text = assessment.weight?.toString() ?? '';
      _description.text = assessment.description;
      final parts = assessment.assessmentDate.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]) ?? _date.year;
        final m = int.tryParse(parts[1]) ?? _date.month;
        final d = int.tryParse(parts[2]) ?? _date.day;
        _date = DateTime.utc(y, m, d);
      }
      _message = null;
    });
  }

  void _closeGrid() {
    _disposeGridCtrls();
    setState(() {
      _grid = null;
      _gridAssessmentId = null;
      _importPreview = null;
      _importKey = null;
      _history = null;
      _csv.clear();
      _reason.clear();
    });
  }

  void _bindGrid(TeacherMarksGrid grid) {
    _disposeGridCtrls();
    for (final s in grid.roster) {
      final existing = grid.entryByStudent[s.id];
      _statusDraft[s.id] = existing?.status ?? MarksEntryStatus.scored;
      _scoreCtrls[s.id] = TextEditingController(
        text: existing?.obtainedMarks?.toString() ?? '',
      );
      _remarkCtrls[s.id] = TextEditingController(
        text: existing?.remarks ?? '',
      );
    }
  }

  Future<void> _openGrid(String assessmentId) async {
    setState(() {
      _state = const NanoViewLoading();
      _message = null;
    });
    try {
      final grid = await widget.repository.loadMarks(assessmentId);
      MarksCorrectionHistory? history;
      if (grid.isCorrectable) {
        history = await widget.repository.loadMarksHistory(assessmentId);
      }
      if (!mounted) return;
      _bindGrid(grid);
      setState(() {
        _grid = grid;
        _gridAssessmentId = assessmentId;
        _history = history;
        _importPreview = null;
        _importKey = null;
        _csv.clear();
        _reason.clear();
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  TeacherAssessmentDraftInput? _readInput(NanoCopy copy) {
    final total = double.tryParse(_total.text.trim());
    final weightRaw = _weight.text.trim();
    final weight = weightRaw.isEmpty ? null : double.tryParse(weightRaw);
    if (_category.text.trim().isEmpty ||
        _name.text.trim().isEmpty ||
        total == null ||
        total <= 0 ||
        (weightRaw.isNotEmpty && weight == null) ||
        (weight != null && weight < 0)) {
      setState(() => _message = copy.teacherMarksSaveFailed);
      return null;
    }
    return TeacherAssessmentDraftInput(
      category: _category.text,
      name: _name.text,
      assessmentDate: _dateIso,
      totalMarks: total,
      weight: weight,
      description: _description.text,
    );
  }

  Future<void> _save() async {
    final assignmentId = _assignmentId;
    if (assignmentId == null || _saving) return;
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final input = _readInput(copy);
    if (input == null) return;
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final list = _editingId == null
          ? await widget.repository.create(
              assignmentId: assignmentId,
              input: input,
            )
          : await widget.repository.update(
              assessmentId: _editingId!,
              input: input,
            );
      if (!mounted) return;
      setState(() {
        _list = list;
        _saving = false;
        _message = copy.teacherMarksSaved;
        _resetForm();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = copy.teacherMarksSaveFailed;
      });
    }
  }

  Future<void> _saveMarks() async {
    final assessmentId = _gridAssessmentId;
    final grid = _grid;
    if (assessmentId == null || grid == null || _savingMarks) return;
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final entries = <MarksEntryMark>[];
    for (final s in grid.roster) {
      final status = _statusDraft[s.id] ?? MarksEntryStatus.scored;
      double? obtained;
      if (status == MarksEntryStatus.scored) {
        obtained = double.tryParse(_scoreCtrls[s.id]?.text.trim() ?? '');
        if (obtained == null) {
          setState(() => _message = copy.teacherMarksGridSaveFailed);
          return;
        }
      }
      entries.add(
        MarksEntryMark(
          studentUserId: s.id,
          status: status,
          obtainedMarks: obtained,
          remarks: _remarkCtrls[s.id]?.text ?? '',
        ),
      );
    }
    setState(() {
      _savingMarks = true;
      _message = null;
    });
    try {
      final saved = await widget.repository.saveMarks(
        assessmentId: assessmentId,
        entries: entries,
        idempotencyKey:
            'marks-$assessmentId-${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      _bindGrid(saved);
      setState(() {
        _grid = saved;
        _savingMarks = false;
        _message = copy.teacherMarksGridSaved;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _savingMarks = false;
        _message = copy.teacherMarksGridSaveFailed;
      });
    }
  }

  Future<void> _loadMarksTemplate() async {
    final assessmentId = _gridAssessmentId;
    if (assessmentId == null || _importBusy) return;
    setState(() => _importBusy = true);
    try {
      final template = await widget.repository.loadMarksTemplate(assessmentId);
      if (!mounted) return;
      setState(() {
        _csv.text = template.csvText;
        _importPreview = null;
        _importBusy = false;
        _message = null;
      });
    } catch (_) {
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          const NanoCopy(NanoAppLocale.en);
      setState(() {
        _importBusy = false;
        _message = copy.teacherMarksImportFailed;
      });
    }
  }

  Future<void> _previewMarksImport() async {
    final assessmentId = _gridAssessmentId;
    if (assessmentId == null || _importBusy) return;
    setState(() {
      _importBusy = true;
      _message = null;
    });
    try {
      _importKey ??=
          'marks-import-$assessmentId-${DateTime.now().millisecondsSinceEpoch}';
      final preview = await widget.repository.previewMarksImport(
        assessmentId: assessmentId,
        idempotencyKey: _importKey!,
        rows: MarksImportCsv.parse(_csv.text),
      );
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          const NanoCopy(NanoAppLocale.en);
      setState(() {
        _importPreview = preview;
        _importBusy = false;
        _message = copy.teacherMarksImportPreviewSummary(
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
        _message = copy.teacherMarksImportFailed;
      });
    }
  }

  Future<void> _commitMarksImport() async {
    final assessmentId = _gridAssessmentId;
    final key = _importKey;
    if (assessmentId == null || key == null || _importBusy) return;
    if (!(_importPreview?.canCommit ?? false)) return;
    setState(() => _importBusy = true);
    try {
      final result = await widget.repository.commitMarksImport(
        assessmentId: assessmentId,
        idempotencyKey: key,
        rows: MarksImportCsv.parse(_csv.text),
      );
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          const NanoCopy(NanoAppLocale.en);
      _bindGrid(result.grid);
      setState(() {
        _grid = result.grid;
        _importPreview = result.preview;
        _importBusy = false;
        _message = copy.teacherMarksImportCommitted;
      });
    } catch (_) {
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          const NanoCopy(NanoAppLocale.en);
      setState(() {
        _importBusy = false;
        _message = copy.teacherMarksImportFailed;
      });
    }
  }

  Future<void> _publishMarks() async {
    final assessmentId = _gridAssessmentId;
    if (assessmentId == null || _publishing) return;
    setState(() {
      _publishing = true;
      _message = null;
    });
    try {
      final published = await widget.repository.publishMarks(
        assessmentId: assessmentId,
        idempotencyKey:
            'publish-$assessmentId-${DateTime.now().millisecondsSinceEpoch}',
      );
      final history =
          await widget.repository.loadMarksHistory(assessmentId);
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          const NanoCopy(NanoAppLocale.en);
      _bindGrid(published);
      setState(() {
        _grid = published;
        _history = history;
        _publishing = false;
      });
      final assignmentId = _assignmentId;
      if (assignmentId != null) {
        await _loadList(assignmentId);
      }
      if (!mounted) return;
      setState(() => _message = copy.teacherMarksPublished);
    } catch (_) {
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          const NanoCopy(NanoAppLocale.en);
      setState(() {
        _publishing = false;
        _message = copy.teacherMarksPublishFailed;
      });
    }
  }

  Future<void> _applyCorrection() async {
    final assessmentId = _gridAssessmentId;
    final grid = _grid;
    if (assessmentId == null || grid == null || _correcting) return;
    final reason = _reason.text.trim();
    if (reason.isEmpty) return;
    setState(() {
      _correcting = true;
      _message = null;
    });
    try {
      MarksCorrectionResult? last;
      for (final student in grid.roster) {
        final status =
            _statusDraft[student.id] ?? MarksEntryStatus.notSubmitted;
        final obtainedText = _scoreCtrls[student.id]?.text.trim() ?? '';
        final remarks = _remarkCtrls[student.id]?.text.trim() ?? '';
        final existing = grid.entryByStudent[student.id];
        final obtained = status == MarksEntryStatus.scored
            ? double.tryParse(obtainedText)
            : null;
        if (existing == null) continue;
        if (existing.status == status &&
            existing.obtainedMarks == obtained &&
            existing.remarks.trim() == remarks) {
          continue;
        }
        last = await widget.repository.correctMarks(
          assessmentId: assessmentId,
          studentUserId: student.id,
          newStatus: status,
          obtainedMarks: obtained,
          remarks: remarks,
          reason: reason,
        );
      }
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          const NanoCopy(NanoAppLocale.en);
      if (last == null) {
        setState(() {
          _correcting = false;
          _message = copy.teacherMarksCorrectFailed;
        });
        return;
      }
      _bindGrid(last.grid);
      setState(() {
        _grid = last!.grid;
        _history = last.history;
        _correcting = false;
        _reason.clear();
        _message = copy.teacherMarksCorrected;
      });
    } catch (_) {
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          const NanoCopy(NanoAppLocale.en);
      setState(() {
        _correcting = false;
        _message = copy.teacherMarksCorrectFailed;
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final theme = Theme.of(context);
    final mine = _mine;
    final list = _list;
    final grid = _grid;

    return NanoViewStateHost(
      state: _state,
      onRetry: _bootstrap,
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(copy.teacherMarksTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(copy.teacherMarksSubtitle, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            if (mine == null || mine.assignments.isEmpty)
              Text(copy.teacherMarksNoAssignments)
            else ...[
              DropdownButtonFormField<String>(
                value: _assignmentId,
                decoration: InputDecoration(
                  labelText: copy.teacherMarksAssignmentLabel,
                ),
                items: [
                  for (final a in mine.assignments)
                    DropdownMenuItem(
                      value: a.id,
                      child: Text(a.scopeLabel),
                    ),
                ],
                onChanged: (id) {
                  if (id != null) {
                    _resetForm();
                    _closeGrid();
                    _loadList(id);
                  }
                },
              ),
              if (list != null) ...[
                const SizedBox(height: 8),
                Text(list.scopeLabel, style: theme.textTheme.titleMedium),
                if (grid == null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _editingId == null
                        ? copy.teacherMarksCreateTitle
                        : copy.teacherMarksEditTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _categories.contains(_category.text)
                        ? _category.text
                        : 'Other',
                    decoration: InputDecoration(
                      labelText: copy.teacherMarksCategoryLabel,
                    ),
                    items: [
                      for (final c in _categories)
                        DropdownMenuItem(value: c, child: Text(c)),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _category.text = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _name,
                    decoration: InputDecoration(
                      labelText: copy.teacherMarksNameLabel,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(copy.teacherMarksDateLabel),
                    subtitle: Text(_dateIso),
                    trailing: IconButton(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                    ),
                  ),
                  TextField(
                    controller: _total,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: copy.teacherMarksTotalLabel,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _weight,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: copy.teacherMarksWeightLabel,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _description,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: copy.teacherMarksDescriptionLabel,
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        child: Text(
                          _editingId == null
                              ? copy.teacherMarksSaveDraft
                              : copy.teacherMarksUpdateDraft,
                        ),
                      ),
                      if (_editingId != null)
                        OutlinedButton(
                          onPressed:
                              _saving ? null : () => setState(_resetForm),
                          child: Text(copy.teacherMarksCancelEdit),
                        ),
                    ],
                  ),
                ],
                if (_message != null) ...[
                  const SizedBox(height: 8),
                  Text(_message!, style: theme.textTheme.bodyMedium),
                ],
                if (grid != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    copy.teacherMarksGridTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${grid.assessmentName} · ${grid.totalMarks}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    copy.teacherMarksGridSubtitle,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (grid.isDraft)
                        FilledButton(
                          onPressed: _savingMarks ? null : _saveMarks,
                          child: Text(copy.teacherMarksSaveGrid),
                        ),
                      if (grid.isDraft)
                        FilledButton.tonal(
                          onPressed: _publishing ||
                                  _savingMarks ||
                                  grid.entries.isEmpty
                              ? null
                              : _publishMarks,
                          child: Text(copy.teacherMarksPublishAction),
                        ),
                      OutlinedButton(
                        onPressed: _savingMarks || _publishing || _correcting
                            ? null
                            : _closeGrid,
                        child: Text(copy.teacherMarksCloseGrid),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (grid.roster.isEmpty)
                    Text(copy.teacherMarksGridEmpty)
                  else
                    for (final student in grid.roster)
                      _MarksRow(
                        name: student.displayName.trim().isEmpty
                            ? copy.teacherClassesStudentFallback
                            : student.displayName,
                        status: _statusDraft[student.id] ??
                            MarksEntryStatus.scored,
                        scoreController: _scoreCtrls[student.id]!,
                        remarkController: _remarkCtrls[student.id]!,
                        statusLabel: copy.teacherMarksEntryStatusLabel,
                        obtainedLabel: copy.teacherMarksObtainedLabel,
                        remarksLabel: copy.teacherMarksRemarksLabel,
                        onCycleStatus: () {
                          setState(() {
                            final current = _statusDraft[student.id] ??
                                MarksEntryStatus.scored;
                            _statusDraft[student.id] = current.next;
                          });
                        },
                      ),
                  if (grid.isCorrectable) ...[
                    const SizedBox(height: 24),
                    Text(
                      copy.teacherMarksCorrectTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      copy.teacherMarksCorrectSubtitle,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reason,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: copy.teacherMarksCorrectReasonLabel,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _correcting || _reason.text.trim().isEmpty
                          ? null
                          : _applyCorrection,
                      child: Text(copy.teacherMarksApplyCorrection),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      copy.teacherMarksHistoryTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_history == null || _history!.corrections.isEmpty)
                      Text(copy.teacherMarksHistoryEmpty)
                    else
                      for (final c in _history!.corrections.take(10))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            copy.teacherMarksHistoryLine(
                              name: c.displayName.trim().isEmpty
                                  ? copy.teacherClassesStudentFallback
                                  : c.displayName,
                              previous: copy.teacherMarksStatusValueLabel(
                                c.previousStatus,
                                c.previousObtainedMarks,
                              ),
                              next: copy.teacherMarksStatusValueLabel(
                                c.newStatus,
                                c.newObtainedMarks,
                              ),
                              reason: c.reason,
                            ),
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                  ],
                  if (grid.isDraft) ...[
                    const SizedBox(height: 24),
                    Text(
                      copy.teacherMarksImportTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      copy.teacherMarksImportSubtitle,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _csv,
                      minLines: 4,
                      maxLines: 8,
                      decoration: InputDecoration(
                        labelText: copy.teacherMarksImportCsvLabel,
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: _importBusy ? null : _loadMarksTemplate,
                          child: Text(copy.teacherMarksLoadTemplate),
                        ),
                        OutlinedButton(
                          onPressed: _csv.text.isEmpty
                              ? null
                              : () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: _csv.text),
                                  );
                                },
                          child: Text(copy.teacherMarksCopyCsv),
                        ),
                        OutlinedButton(
                          onPressed: _importBusy ? null : _previewMarksImport,
                          child: Text(copy.teacherMarksPreviewImport),
                        ),
                        FilledButton(
                          onPressed: _importBusy ||
                                  !(_importPreview?.canCommit ?? false)
                              ? null
                              : _commitMarksImport,
                          child: Text(copy.teacherMarksCommitImport),
                        ),
                      ],
                    ),
                    if (_importPreview != null &&
                        _importPreview!.failedRows.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      for (final fail in _importPreview!.failedRows.take(5))
                        Text(
                          copy.teacherMarksImportRowError(
                            fail.row,
                            fail.error,
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ],
                ] else ...[
                  const SizedBox(height: 24),
                  Text(
                    copy.teacherMarksListTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (list.assessments.isEmpty)
                    Text(copy.teacherMarksListEmpty)
                  else
                    for (final a in list.assessments)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(a.name),
                        subtitle: Text(
                          copy.teacherMarksListSubtitle(
                            a.category,
                            a.assessmentDate,
                            a.totalMarks,
                            a.status.wire,
                          ),
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            if (a.isDraft)
                              TextButton(
                                onPressed: () => _edit(a),
                                child: Text(copy.teacherMarksEditAction),
                              ),
                            TextButton(
                              onPressed: () => _openGrid(a.id),
                              child: Text(
                                a.isDraft
                                    ? copy.teacherMarksEnterAction
                                    : copy.teacherMarksOpenAction,
                              ),
                            ),
                          ],
                        ),
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

class _MarksRow extends StatelessWidget {
  const _MarksRow({
    required this.name,
    required this.status,
    required this.scoreController,
    required this.remarkController,
    required this.statusLabel,
    required this.obtainedLabel,
    required this.remarksLabel,
    required this.onCycleStatus,
  });

  final String name;
  final MarksEntryStatus status;
  final TextEditingController scoreController;
  final TextEditingController remarkController;
  final String Function(MarksEntryStatus) statusLabel;
  final String obtainedLabel;
  final String remarksLabel;
  final VoidCallback onCycleStatus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(name),
            subtitle: Text(statusLabel(status)),
            trailing: TextButton(
              onPressed: onCycleStatus,
              child: Text(statusLabel(status)),
            ),
          ),
          if (status == MarksEntryStatus.scored)
            TextField(
              controller: scoreController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: obtainedLabel),
            ),
          const SizedBox(height: 4),
          TextField(
            controller: remarkController,
            decoration: InputDecoration(labelText: remarksLabel),
          ),
        ],
      ),
    );
  }
}
