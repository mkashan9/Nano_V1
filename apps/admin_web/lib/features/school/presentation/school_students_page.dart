import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// SCH-04 Students destination: list, create, suspend, CSV import.
class SchoolStudentsPage extends StatefulWidget {
  const SchoolStudentsPage({
    super.key,
    required this.repository,
  });

  final SchoolStudentRepository repository;

  @override
  State<SchoolStudentsPage> createState() => _SchoolStudentsPageState();
}

class _SchoolStudentsPageState extends State<SchoolStudentsPage> {
  NanoViewState _state = const NanoViewLoading();
  List<SchoolStudent> _students = const [];
  final _query = TextEditingController();
  final _csv = TextEditingController();
  StudentImportPreview? _preview;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    _csv.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final students = await widget.repository.list(query: _query.text);
      if (!mounted) return;
      setState(() {
        _students = students;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  Future<void> _createStudent() async {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final name = TextEditingController();
    final email = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(copy.studentsCreateTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: InputDecoration(
                  labelText: copy.studentsNameLabel,
                ),
              ),
              TextField(
                controller: email,
                decoration: InputDecoration(
                  labelText: copy.studentsEmailLabel,
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
              child: Text(copy.studentsCreateAction),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final result = await widget.repository.create(
        displayName: name.text,
        email: email.text,
      );
      if (!mounted) return;
      setState(() {
        _students = result.students;
        _state = const NanoViewReady();
      });
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(copy.studentsTempPasswordTitle),
            content: SelectableText(result.tempPassword),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: result.tempPassword));
                  Navigator.pop(context);
                },
                child: Text(copy.studentsCopyPassword),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      name.dispose();
      email.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleStatus(SchoolStudent student) async {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final reason = TextEditingController();
    final next = student.isSuspended ? 'active' : 'suspended';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            next == 'suspended'
                ? copy.studentsSuspendTitle
                : copy.studentsRestoreTitle,
          ),
          content: TextField(
            controller: reason,
            decoration: InputDecoration(labelText: copy.studentsReasonLabel),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(copy.cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(copy.studentsConfirmAction),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final students = await widget.repository.setStatus(
        userId: student.id,
        status: next,
        reason: reason.text,
      );
      if (!mounted) return;
      setState(() {
        _students = students;
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

  Future<void> _previewImport() async {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    setState(() => _busy = true);
    try {
      final rows = StudentImportCsv.parse(_csv.text);
      final preview = await widget.repository.previewImport(rows);
      if (!mounted) return;
      setState(() => _preview = preview);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            copy.studentsImportPreviewSummary(
              preview.okCount,
              preview.failCount,
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _commitImport() async {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    setState(() => _busy = true);
    try {
      final rows = StudentImportCsv.parse(_csv.text);
      final result = await widget.repository.commitImport(rows);
      if (!mounted) return;
      setState(() {
        _students = result.students;
        _preview = result.preview;
        _state = const NanoViewReady();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      if (result.committed && result.created.isNotEmpty) {
        final passwords = result.created
            .map((row) => '${row['email']}: ${row['temp_password']}')
            .join('\n');
        await showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(copy.studentsTempPasswordTitle),
              content: SizedBox(
                width: 420,
                child: SelectableText(passwords),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(copy.cancelLabel),
                ),
              ],
            );
          },
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final theme = Theme.of(context);
    final preview = _preview;

    return NanoScaffold(
      padBody: true,
      body: NanoViewStateHost(
        state: _state,
        onRetry: _load,
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: ListView(
              children: [
                Text(
                  copy.studentsPageTitle,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: NanoSpacing.xs),
                Text(
                  copy.studentsPageSubtitle,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: NanoSpacing.md),
                Wrap(
                  spacing: NanoSpacing.sm,
                  runSpacing: NanoSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 260,
                      child: TextField(
                        controller: _query,
                        decoration: InputDecoration(
                          labelText: copy.studentsSearchHint,
                        ),
                        onSubmitted: (_) => _load(),
                      ),
                    ),
                    FilledButton(
                      onPressed: _busy ? null : _load,
                      child: Text(copy.retryLabel),
                    ),
                    FilledButton(
                      onPressed: _busy ? null : _createStudent,
                      child: Text(copy.studentsCreateTitle),
                    ),
                  ],
                ),
                const SizedBox(height: NanoSpacing.lg),
                Text(
                  copy.studentsImportTitle,
                  style: theme.textTheme.titleMedium,
                ),
                Text(copy.studentsImportSubtitle),
                const SizedBox(height: NanoSpacing.sm),
                TextField(
                  controller: _csv,
                  minLines: 4,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: StudentImportCsv.template.trim(),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: NanoSpacing.sm),
                Wrap(
                  spacing: NanoSpacing.sm,
                  children: [
                    OutlinedButton(
                      onPressed: _busy ? null : _previewImport,
                      child: Text(copy.studentsPreviewImport),
                    ),
                    FilledButton(
                      onPressed: _busy || !(preview?.canCommit ?? false)
                          ? null
                          : _commitImport,
                      child: Text(copy.studentsCommitImport),
                    ),
                    TextButton(
                      onPressed: () {
                        _csv.text = StudentImportCsv.template;
                        setState(() {});
                      },
                      child: Text(copy.studentsLoadTemplate),
                    ),
                  ],
                ),
                if (preview != null && preview.failedRows.isNotEmpty) ...[
                  const SizedBox(height: NanoSpacing.sm),
                  for (final fail in preview.failedRows)
                    Text(
                      'Row ${fail.row}: ${fail.email} — ${fail.error}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                ],
                const SizedBox(height: NanoSpacing.lg),
                for (final student in _students)
                  ListTile(
                    title: Text(student.displayName),
                    subtitle: Text(
                      [
                        student.email,
                        if ((student.className ?? '').isNotEmpty)
                          student.className!,
                        student.membershipStatus,
                      ].join(' · '),
                    ),
                    trailing: TextButton(
                      onPressed: _busy ? null : () => _toggleStatus(student),
                      child: Text(
                        student.isSuspended
                            ? copy.studentsRestoreTitle
                            : copy.studentsSuspendTitle,
                      ),
                    ),
                  ),
                if (_students.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: NanoSpacing.md),
                    child: Text(copy.studentsEmpty),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

