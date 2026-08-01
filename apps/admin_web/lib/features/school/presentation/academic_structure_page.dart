import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// SCH-02 Classes destination: grades → classes → sections + subjects.
class AcademicStructurePage extends StatefulWidget {
  const AcademicStructurePage({
    super.key,
    required this.repository,
  });

  final AcademicStructureRepository repository;

  @override
  State<AcademicStructurePage> createState() => _AcademicStructurePageState();
}

class _AcademicStructurePageState extends State<AcademicStructurePage> {
  NanoViewState _state = const NanoViewLoading();
  AcademicStructure? _structure;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final structure = await widget.repository.load();
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          const NanoCopy(NanoAppLocale.en);
      setState(() {
        _structure = structure;
        _state = structure.activeClasses.isEmpty &&
                structure.activeGrades.isEmpty
            ? NanoViewEmpty(message: copy.classesEmpty)
            : const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          const NanoCopy(NanoAppLocale.en);
      setState(() => _state = NanoViewError(message: copy.classesLoadError));
    }
  }

  Future<void> _run(Future<AcademicStructure> Function() action) async {
    setState(() => _busy = true);
    try {
      final structure = await action();
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          const NanoCopy(NanoAppLocale.en);
      setState(() {
        _structure = structure;
        _state = structure.activeClasses.isEmpty &&
                structure.activeGrades.isEmpty
            ? NanoViewEmpty(message: copy.classesEmpty)
            : const NanoViewReady();
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

  Future<void> _createGrade() async {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final name = TextEditingController();
    final ok = await _prompt(
      title: copy.classesCreateGradeTitle,
      fields: [
        TextField(
          controller: name,
          decoration: InputDecoration(labelText: copy.classesGradeNameLabel),
        ),
      ],
      confirmLabel: copy.classesCreateAction,
      cancelLabel: copy.cancelLabel,
    );
    if (ok != true || !mounted) return;
    await _run(() => widget.repository.createGradeLevel(name: name.text));
    name.dispose();
  }

  Future<void> _createClass() async {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final structure = _structure;
    if (structure == null || structure.activeGrades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(copy.classesNeedGradeFirst)),
      );
      return;
    }
    var gradeId = structure.activeGrades.first.id;
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(copy.classesCreateClassTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: gradeId,
                    decoration: InputDecoration(
                      labelText: copy.classesGradeNameLabel,
                    ),
                    items: [
                      for (final g in structure.activeGrades)
                        DropdownMenuItem(value: g.id, child: Text(g.name)),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setLocal(() => gradeId = value);
                    },
                  ),
                  TextField(
                    controller: name,
                    decoration: InputDecoration(
                      labelText: copy.classesClassNameLabel,
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
                  child: Text(copy.classesCreateAction),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok != true || !mounted) return;
    await _run(
      () => widget.repository.createClass(
        gradeLevelId: gradeId,
        name: name.text,
      ),
    );
    name.dispose();
  }

  Future<void> _createSection(SchoolClassRow schoolClass) async {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final name = TextEditingController();
    final ok = await _prompt(
      title: copy.classesCreateSectionTitle,
      fields: [
        TextField(
          controller: name,
          decoration: InputDecoration(labelText: copy.classesSectionNameLabel),
        ),
      ],
      confirmLabel: copy.classesCreateAction,
      cancelLabel: copy.cancelLabel,
    );
    if (ok != true || !mounted) return;
    await _run(
      () => widget.repository.createSection(
        classId: schoolClass.id,
        name: name.text,
      ),
    );
    name.dispose();
  }

  Future<void> _createSubject() async {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final name = TextEditingController();
    final code = TextEditingController();
    final ok = await _prompt(
      title: copy.classesCreateSubjectTitle,
      fields: [
        TextField(
          controller: name,
          decoration: InputDecoration(labelText: copy.classesSubjectNameLabel),
        ),
        TextField(
          controller: code,
          decoration: InputDecoration(labelText: copy.classesSubjectCodeLabel),
          textCapitalization: TextCapitalization.characters,
        ),
      ],
      confirmLabel: copy.classesCreateAction,
      cancelLabel: copy.cancelLabel,
    );
    if (ok != true || !mounted) return;
    await _run(
      () => widget.repository.createSubject(
        name: name.text,
        code: code.text,
      ),
    );
    name.dispose();
    code.dispose();
  }

  Future<void> _assignSubject(SchoolClassRow schoolClass) async {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final structure = _structure;
    final subjects =
        structure?.subjects.where((s) => s.isActive).toList() ?? const [];
    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(copy.classesNeedSubjectFirst)),
      );
      return;
    }
    var subjectId = subjects.first.id;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(copy.classesAssignSubjectTitle),
              content: DropdownButtonFormField<String>(
                value: subjectId,
                items: [
                  for (final s in subjects)
                    DropdownMenuItem(
                      value: s.id,
                      child: Text('${s.name} (${s.code})'),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setLocal(() => subjectId = value);
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(copy.cancelLabel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(copy.classesAssignAction),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok != true || !mounted) return;
    await _run(
      () => widget.repository.assignSubject(
        classId: schoolClass.id,
        schoolSubjectId: subjectId,
      ),
    );
  }

  Future<bool?> _prompt({
    required String title,
    required List<Widget> fields,
    required String confirmLabel,
    required String cancelLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Column(mainAxisSize: MainAxisSize.min, children: fields),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final structure = _structure;
    final theme = Theme.of(context);

    return NanoScaffold(
      padBody: true,
      body: NanoViewStateHost(
        state: _state,
        onRetry: _load,
        child: structure == null
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.all(NanoSpacing.lg),
                children: [
                  Text(
                    copy.classesPageTitle,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: NanoSpacing.xs),
                  Text(
                    copy.classesPageSubtitle,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: NanoSpacing.md),
                  Wrap(
                    spacing: NanoSpacing.sm,
                    runSpacing: NanoSpacing.sm,
                    children: [
                      FilledButton(
                        onPressed: _busy ? null : _createGrade,
                        child: Text(copy.classesCreateGradeTitle),
                      ),
                      OutlinedButton(
                        onPressed: _busy ? null : _createClass,
                        child: Text(copy.classesCreateClassTitle),
                      ),
                      OutlinedButton(
                        onPressed: _busy ? null : _createSubject,
                        child: Text(copy.classesCreateSubjectTitle),
                      ),
                      TextButton(
                        onPressed: _busy ? null : _load,
                        child: Text(copy.retryLabel),
                      ),
                    ],
                  ),
                  if (structure.mappingIssues.isNotEmpty) ...[
                    const SizedBox(height: NanoSpacing.md),
                    Text(
                      copy.classesMappingIssuesTitle,
                      style: theme.textTheme.titleSmall,
                    ),
                    for (final issue in structure.mappingIssues)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.warning_amber_outlined),
                        title: Text(
                          copy.classesMissingSubjects(issue.className),
                        ),
                      ),
                  ],
                  const SizedBox(height: NanoSpacing.lg),
                  Text(
                    copy.classesGradesHeading,
                    style: theme.textTheme.titleMedium,
                  ),
                  for (final grade in structure.gradeLevels)
                    ListTile(
                      title: Text(grade.name),
                      subtitle: Text(grade.status),
                      trailing: grade.isActive
                          ? TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _run(
                                        () => widget.repository.archive(
                                          kind:
                                              AcademicStructureKind.gradeLevel,
                                          id: grade.id,
                                        ),
                                      ),
                              child: Text(copy.classesArchiveAction),
                            )
                          : null,
                    ),
                  const SizedBox(height: NanoSpacing.md),
                  Text(
                    copy.classesClassesHeading,
                    style: theme.textTheme.titleMedium,
                  ),
                  for (final schoolClass in structure.classes) ...[
                    ListTile(
                      title: Text(schoolClass.name),
                      subtitle: Text(
                        [
                          () {
                            for (final g in structure.gradeLevels) {
                              if (g.id == schoolClass.gradeLevelId) {
                                return g.name;
                              }
                            }
                            return schoolClass.gradeLevelId;
                          }(),
                          schoolClass.status,
                        ].join(' · '),
                      ),
                      trailing: schoolClass.isActive
                          ? Wrap(
                              spacing: NanoSpacing.xs,
                              children: [
                                TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _createSection(schoolClass),
                                  child: Text(copy.classesCreateSectionTitle),
                                ),
                                TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _assignSubject(schoolClass),
                                  child: Text(copy.classesAssignAction),
                                ),
                                TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _run(
                                            () => widget.repository.archive(
                                              kind: AcademicStructureKind
                                                  .classUnit,
                                              id: schoolClass.id,
                                            ),
                                          ),
                                  child: Text(copy.classesArchiveAction),
                                ),
                              ],
                            )
                          : null,
                    ),
                    for (final section in structure.sections
                        .where((s) => s.classId == schoolClass.id))
                      Padding(
                        padding: const EdgeInsets.only(left: NanoSpacing.xl),
                        child: ListTile(
                          dense: true,
                          title: Text(section.name),
                          subtitle: Text(section.status),
                          trailing: section.isActive
                              ? TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _run(
                                            () => widget.repository.archive(
                                              kind:
                                                  AcademicStructureKind.section,
                                              id: section.id,
                                            ),
                                          ),
                                  child: Text(copy.classesArchiveAction),
                                )
                              : null,
                        ),
                      ),
                  ],
                  const SizedBox(height: NanoSpacing.md),
                  Text(
                    copy.classesSubjectsHeading,
                    style: theme.textTheme.titleMedium,
                  ),
                  for (final subject in structure.subjects)
                    ListTile(
                      title: Text('${subject.name} (${subject.code})'),
                      subtitle: Text(subject.status),
                      trailing: subject.isActive
                          ? TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _run(
                                        () => widget.repository.archive(
                                          kind: AcademicStructureKind
                                              .schoolSubject,
                                          id: subject.id,
                                        ),
                                      ),
                              child: Text(copy.classesArchiveAction),
                            )
                          : null,
                    ),
                ],
              ),
      ),
    );
  }
}
