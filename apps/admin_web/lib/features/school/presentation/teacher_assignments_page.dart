import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// SCH-05 Assignments destination: matrix, coverage, workload.
class TeacherAssignmentsPage extends StatefulWidget {
  const TeacherAssignmentsPage({
    super.key,
    required this.repository,
  });

  final TeacherAssignmentRepository repository;

  @override
  State<TeacherAssignmentsPage> createState() => _TeacherAssignmentsPageState();
}

class _TeacherAssignmentsPageState extends State<TeacherAssignmentsPage> {
  NanoViewState _state = const NanoViewLoading();
  TeacherAssignmentMatrix? _matrix;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final matrix = await widget.repository.load();
      if (!mounted) return;
      setState(() {
        _matrix = matrix;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  Future<void> _assign() async {
    final matrix = _matrix;
    if (matrix == null) return;
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    String? teacherId =
        matrix.teachers.isEmpty ? null : matrix.teachers.first.id;
    String? classId = matrix.classes.isEmpty ? null : matrix.classes.first.id;
    String? subjectId =
        matrix.subjects.isEmpty ? null : matrix.subjects.first.id;
    String? sectionId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            final sections = [
              for (final s in matrix.sections)
                if (s.classId == classId) s,
            ];
            return AlertDialog(
              title: Text(copy.assignmentsCreateTitle),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: teacherId,
                      decoration: InputDecoration(
                        labelText: copy.assignmentsTeacherLabel,
                      ),
                      items: [
                        for (final t in matrix.teachers)
                          DropdownMenuItem(
                            value: t.id,
                            child: Text(t.displayName),
                          ),
                      ],
                      onChanged: (v) => setLocal(() => teacherId = v),
                    ),
                    DropdownButtonFormField<String>(
                      value: classId,
                      decoration: InputDecoration(
                        labelText: copy.assignmentsClassLabel,
                      ),
                      items: [
                        for (final c in matrix.classes)
                          DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ],
                      onChanged: (v) => setLocal(() {
                        classId = v;
                        sectionId = null;
                      }),
                    ),
                    DropdownButtonFormField<String>(
                      value: subjectId,
                      decoration: InputDecoration(
                        labelText: copy.assignmentsSubjectLabel,
                      ),
                      items: [
                        for (final s in matrix.subjects)
                          DropdownMenuItem(
                            value: s.id,
                            child: Text('${s.code} — ${s.name}'),
                          ),
                      ],
                      onChanged: (v) => setLocal(() => subjectId = v),
                    ),
                    DropdownButtonFormField<String?>(
                      value: sectionId,
                      decoration: InputDecoration(
                        labelText: copy.assignmentsSectionLabel,
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(copy.assignmentsSectionNone),
                        ),
                        for (final s in sections)
                          DropdownMenuItem<String?>(
                            value: s.id,
                            child: Text(s.name),
                          ),
                      ],
                      onChanged: (v) => setLocal(() => sectionId = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(copy.cancelLabel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(copy.assignmentsCreateAction),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok != true ||
        !mounted ||
        teacherId == null ||
        classId == null ||
        subjectId == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      final next = await widget.repository.assign(
        teacherUserId: teacherId!,
        classId: classId!,
        schoolSubjectId: subjectId!,
        sectionId: sectionId,
      );
      if (!mounted) return;
      setState(() {
        _matrix = next;
        _state = const NanoViewReady();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _end(TeacherAssignmentRow row) async {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(copy.assignmentsEndTitle),
          content: TextField(
            controller: reason,
            decoration: InputDecoration(labelText: copy.assignmentsReasonLabel),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(copy.cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(copy.assignmentsConfirmAction),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final next = await widget.repository.end(
        assignmentId: row.id,
        reason: reason.text,
      );
      if (!mounted) return;
      setState(() {
        _matrix = next;
        _state = const NanoViewReady();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      reason.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _replace(TeacherAssignmentRow row) async {
    final matrix = _matrix;
    if (matrix == null || row.isLegacyStub) return;
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final reason = TextEditingController();
    final others = [
      for (final t in matrix.teachers)
        if (t.id != row.teacherUserId) t,
    ];
    if (others.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(copy.assignmentsNeedAnotherTeacher)),
      );
      return;
    }
    String? teacherId = others.first.id;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(copy.assignmentsReplaceTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: teacherId,
                    decoration: InputDecoration(
                      labelText: copy.assignmentsTeacherLabel,
                    ),
                    items: [
                      for (final t in others)
                        DropdownMenuItem(
                          value: t.id,
                          child: Text(t.displayName),
                        ),
                    ],
                    onChanged: (v) => setLocal(() => teacherId = v),
                  ),
                  TextField(
                    controller: reason,
                    decoration: InputDecoration(
                      labelText: copy.assignmentsReasonLabel,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(copy.cancelLabel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(copy.assignmentsConfirmAction),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok != true || !mounted || teacherId == null) return;
    setState(() => _busy = true);
    try {
      final next = await widget.repository.replace(
        assignmentId: row.id,
        newTeacherUserId: teacherId!,
        reason: reason.text,
      );
      if (!mounted) return;
      setState(() {
        _matrix = next;
        _state = const NanoViewReady();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      reason.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final matrix = _matrix;
    final theme = Theme.of(context);

    return NanoViewStateHost(
      state: _state,
      onRetry: _load,
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      copy.assignmentsPageTitle,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      copy.assignmentsPageSubtitle,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _busy || matrix == null ? null : _assign,
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: Text(copy.assignmentsCreateAction),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (matrix != null) ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricChip(
                  label: copy.assignmentsActiveCount,
                  value: '${matrix.activeAssignments.length}',
                ),
                _MetricChip(
                  label: copy.assignmentsUncoveredCount,
                  value: '${matrix.uncovered.length}',
                ),
                _MetricChip(
                  label: copy.assignmentsConflictCount,
                  value: '${matrix.conflicts.length}',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              copy.assignmentsWorkloadTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (matrix.workload.isEmpty)
              Text(copy.assignmentsEmpty)
            else
              ...[
                for (final w in matrix.workload)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(w.displayName),
                    trailing: Text(copy.assignmentsWorkloadValue(w.activeCount)),
                  ),
              ],
            const SizedBox(height: 16),
            if (matrix.uncovered.isNotEmpty) ...[
              Text(
                copy.assignmentsUncoveredTitle,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final u in matrix.uncovered)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.warning_amber_outlined),
                  title: Text(u.label),
                ),
              const SizedBox(height: 16),
            ],
            if (matrix.conflicts.isNotEmpty) ...[
              Text(
                copy.assignmentsConflictsTitle,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final c in matrix.conflicts)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.group_outlined),
                  title: Text(c.label),
                  subtitle: Text(c.teacherNames),
                ),
              const SizedBox(height: 16),
            ],
            Text(
              copy.assignmentsListTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (matrix.assignments.isEmpty)
              Text(copy.assignmentsEmpty)
            else
              for (final row in matrix.assignments)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(row.teacherName),
                    subtitle: Text(
                      '${row.scopeLabel} · ${row.status}'
                      '${row.startsOn == null ? '' : ' · ${row.startsOn}'}',
                    ),
                    trailing: row.isActive
                        ? Wrap(
                            spacing: 4,
                            children: [
                              if (!row.isLegacyStub)
                                TextButton(
                                  onPressed: _busy ? null : () => _replace(row),
                                  child: Text(copy.assignmentsReplaceAction),
                                ),
                              TextButton(
                                onPressed: _busy ? null : () => _end(row),
                                child: Text(copy.assignmentsEndAction),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
          ],
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
