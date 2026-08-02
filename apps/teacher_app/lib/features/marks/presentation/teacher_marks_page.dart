import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// MRK-01 Marks: create and edit draft assessments for assigned scopes.
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
  String? _assignmentId;
  String? _editingId;
  final _category = TextEditingController(text: 'Quiz');
  final _name = TextEditingController();
  final _total = TextEditingController(text: '100');
  final _weight = TextEditingController();
  final _description = TextEditingController();
  late DateTime _date;
  var _saving = false;
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

  TeacherAssessmentDraftInput? _readInput(NanoCopy copy) {
    final total = double.tryParse(_total.text.trim());
    final weightRaw = _weight.text.trim();
    final weight =
        weightRaw.isEmpty ? null : double.tryParse(weightRaw);
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
                    _loadList(id);
                  }
                },
              ),
              if (list != null) ...[
                const SizedBox(height: 8),
                Text(list.scopeLabel, style: theme.textTheme.titleMedium),
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
                        onPressed: _saving
                            ? null
                            : () => setState(_resetForm),
                        child: Text(copy.teacherMarksCancelEdit),
                      ),
                  ],
                ),
                if (_message != null) ...[
                  const SizedBox(height: 8),
                  Text(_message!, style: theme.textTheme.bodyMedium),
                ],
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
                      trailing: a.isDraft
                          ? TextButton(
                              onPressed: () => _edit(a),
                              child: Text(copy.teacherMarksEditAction),
                            )
                          : null,
                    ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
