import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// FBK-01 teacher structured feedback for roster students.
class TeacherFeedbackPage extends StatefulWidget {
  const TeacherFeedbackPage({
    super.key,
    required this.repository,
    this.initialAssignmentId,
  });

  final TeacherFeedbackRepository repository;
  final String? initialAssignmentId;

  @override
  State<TeacherFeedbackPage> createState() => _TeacherFeedbackPageState();
}

class _TeacherFeedbackPageState extends State<TeacherFeedbackPage> {
  NanoViewState _state = const NanoViewLoading();
  TeacherMyClasses? _mine;
  TeacherClassRoster? _roster;
  TeacherFeedbackList? _list;
  String? _assignmentId;
  String? _studentId;
  String? _editingId;
  FeedbackCategory _category = FeedbackCategory.effort;
  final _body = TextEditingController();
  var _publishNow = false;
  var _saving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _assignmentId = widget.initialAssignmentId;
    _bootstrap();
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  TeacherFeedbackNote? get _editingNote {
    final id = _editingId;
    final list = _list;
    if (id == null || list == null) return null;
    for (final note in list.notes) {
      if (note.id == id) return note;
    }
    return null;
  }

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
        await _loadAssignment(selected);
      } else {
        setState(() => _state = const NanoViewReady());
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  Future<void> _loadAssignment(String assignmentId) async {
    setState(() {
      _state = const NanoViewLoading();
      _message = null;
    });
    try {
      final roster = await widget.repository.loadRoster(assignmentId);
      final list = await widget.repository.listForAssignment(assignmentId);
      if (!mounted) return;
      final studentId = _studentId != null &&
              roster.students.any((s) => s.id == _studentId)
          ? _studentId
          : (roster.students.isEmpty ? null : roster.students.first.id);
      setState(() {
        _assignmentId = assignmentId;
        _roster = roster;
        _list = list;
        _studentId = studentId;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  void _resetForm() {
    _editingId = null;
    _category = FeedbackCategory.effort;
    _body.clear();
    _publishNow = false;
    final roster = _roster;
    _studentId =
        roster == null || roster.students.isEmpty ? null : roster.students.first.id;
  }

  void _startEdit(TeacherFeedbackNote note) {
    setState(() {
      _editingId = note.id;
      _studentId = note.studentUserId;
      _category = note.category;
      _body.text = note.body;
      _publishNow = false;
      _message = null;
    });
  }

  Future<void> _save() async {
    final assignmentId = _assignmentId;
    final studentId = _studentId;
    if (assignmentId == null || studentId == null) return;
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final input = TeacherFeedbackDraftInput(
        studentUserId: studentId,
        category: _category,
        body: _body.text,
        publishNow: _publishNow,
      );
      final editing = _editingId;
      final list = editing == null
          ? await widget.repository.create(
              assignmentId: assignmentId,
              input: input,
            )
          : await widget.repository.update(
              noteId: editing,
              input: input,
            );
      if (!mounted) return;
      setState(() {
        _list = list;
            _saving = false;
        _message = _publishNow ? 'Feedback published.' : 'Feedback saved.';
        _resetForm();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = e is StateError ? e.message : 'Could not save feedback.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mine = _mine;
    final roster = _roster;
    final list = _list;
    final editing = _editingNote;

    return NanoScaffold(
      padBody: true,
      body: NanoViewStateHost(
        state: _state,
        onRetry: _bootstrap,
        child: ListView(
          children: [
            Text('Feedback', style: theme.textTheme.headlineSmall),
            const SizedBox(height: NanoSpacing.xs),
            Text(
              'Structured notes for roster students. Guardians read later.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: NanoSpacing.md),
            if (mine != null && mine.assignments.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                value: _assignmentId,
                decoration: const InputDecoration(labelText: 'Class / subject'),
                items: [
                  for (final a in mine.assignments)
                    DropdownMenuItem(
                      value: a.id,
                      child: Text('${a.classLabel} · ${a.subjectCode}'),
                    ),
                ],
                onChanged: _saving
                    ? null
                    : (id) {
                        if (id == null) return;
                        _resetForm();
                        _loadAssignment(id);
                      },
              ),
              const SizedBox(height: NanoSpacing.md),
            ],
            if (roster != null && roster.students.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                value: _studentId,
                decoration: const InputDecoration(labelText: 'Student'),
                items: [
                  for (final s in roster.students)
                    DropdownMenuItem(
                      value: s.id,
                      child: Text(s.displayName),
                    ),
                ],
                onChanged: _saving || editing != null
                    ? null
                    : (id) => setState(() => _studentId = id),
              ),
              const SizedBox(height: NanoSpacing.sm),
              DropdownButtonFormField<FeedbackCategory>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final c in FeedbackCategory.values)
                    DropdownMenuItem(value: c, child: Text(c.label)),
                ],
                onChanged: _saving
                    ? null
                    : (c) {
                        if (c == null) return;
                        setState(() => _category = c);
                      },
              ),
              const SizedBox(height: NanoSpacing.sm),
              TextField(
                controller: _body,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  alignLabelWithHint: true,
                ),
                enabled: !_saving,
              ),
              const SizedBox(height: NanoSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Publish now'),
                value: _publishNow,
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _publishNow = v),
              ),
              const SizedBox(height: NanoSpacing.sm),
              Wrap(
                spacing: NanoSpacing.sm,
                runSpacing: NanoSpacing.sm,
                children: [
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(editing == null ? 'Save draft' : 'Update draft'),
                  ),
                  if (editing != null)
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => setState(_resetForm),
                      child: const Text('Cancel'),
                    ),
                ],
              ),
            ] else if (_state is NanoViewReady) ...[
              const Text('No students on this roster yet.'),
            ],
            if (_message != null) ...[
              const SizedBox(height: NanoSpacing.sm),
              Text(_message!, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: NanoSpacing.lg),
            Text('Notes', style: theme.textTheme.titleMedium),
            const SizedBox(height: NanoSpacing.sm),
            if (list == null || list.notes.isEmpty)
              const Text('No feedback notes yet.')
            else
              for (final note in list.notes)
                Card(
                  margin: const EdgeInsets.only(bottom: NanoSpacing.sm),
                  child: ListTile(
                    title: Text(
                      '${note.studentDisplayName} · ${note.category.label}',
                    ),
                    subtitle: Text(
                      '${note.status.wire} — ${note.body}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: note.isDraft
                        ? TextButton(
                            onPressed: _saving ? null : () => _startEdit(note),
                            child: const Text('Edit'),
                          )
                        : null,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
