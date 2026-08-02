import 'package:admin_web/app/csv_browser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// SCH-03 Teachers destination: list, create, suspend, CSV import.
class SchoolTeachersPage extends StatefulWidget {
  const SchoolTeachersPage({
    super.key,
    required this.repository,
  });

  final SchoolTeacherRepository repository;

  @override
  State<SchoolTeachersPage> createState() => _SchoolTeachersPageState();
}

class _SchoolTeachersPageState extends State<SchoolTeachersPage> {
  NanoViewState _state = const NanoViewLoading();
  List<SchoolTeacher> _teachers = const [];
  final _query = TextEditingController();
  final _csv = TextEditingController();
  TeacherImportPreview? _preview;
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
      final teachers = await widget.repository.list(query: _query.text);
      if (!mounted) return;
      setState(() {
        _teachers = teachers;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  Future<void> _createTeacher() async {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final name = TextEditingController();
    final email = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(copy.teachersCreateTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: InputDecoration(
                  labelText: copy.teachersNameLabel,
                ),
              ),
              TextField(
                controller: email,
                decoration: InputDecoration(
                  labelText: copy.teachersEmailLabel,
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
              child: Text(copy.teachersCreateAction),
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
        _teachers = result.teachers;
        _state = const NanoViewReady();
      });
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(copy.teachersTempPasswordTitle),
            content: SelectableText(result.tempPassword),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: result.tempPassword));
                  Navigator.pop(context);
                },
                child: Text(copy.teachersCopyPassword),
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

  Future<void> _toggleStatus(SchoolTeacher teacher) async {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final reason = TextEditingController();
    final next = teacher.isSuspended ? 'active' : 'suspended';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            next == 'suspended'
                ? copy.teachersSuspendTitle
                : copy.teachersRestoreTitle,
          ),
          content: TextField(
            controller: reason,
            decoration: InputDecoration(labelText: copy.teachersReasonLabel),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(copy.cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(copy.teachersConfirmAction),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final teachers = await widget.repository.setStatus(
        userId: teacher.id,
        status: next,
        reason: reason.text,
      );
      if (!mounted) return;
      setState(() {
        _teachers = teachers;
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
      final rows = TeacherImportCsv.parse(_csv.text);
      final preview = await widget.repository.previewImport(rows);
      if (!mounted) return;
      setState(() => _preview = preview);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            copy.teachersImportPreviewSummary(
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
      final rows = TeacherImportCsv.parse(_csv.text);
      final result = await widget.repository.commitImport(rows);
      if (!mounted) return;
      setState(() {
        _teachers = result.teachers;
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
              title: Text(copy.teachersTempPasswordTitle),
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
                  copy.teachersPageTitle,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: NanoSpacing.xs),
                Text(
                  copy.teachersPageSubtitle,
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
                          labelText: copy.teachersSearchHint,
                        ),
                        onSubmitted: (_) => _load(),
                      ),
                    ),
                    FilledButton(
                      onPressed: _busy ? null : _load,
                      child: Text(copy.retryLabel),
                    ),
                    FilledButton(
                      onPressed: _busy ? null : _createTeacher,
                      child: Text(copy.teachersCreateTitle),
                    ),
                  ],
                ),
                const SizedBox(height: NanoSpacing.lg),
                Text(
                  copy.teachersImportTitle,
                  style: theme.textTheme.titleMedium,
                ),
                Text(copy.teachersImportSubtitle),
                const SizedBox(height: NanoSpacing.sm),
                TextField(
                  controller: _csv,
                  minLines: 4,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: TeacherImportCsv.template.trim(),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: NanoSpacing.sm),
                Wrap(
                  spacing: NanoSpacing.sm,
                  runSpacing: NanoSpacing.sm,
                  children: [
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () {
                              downloadCsvFile(
                                filename: 'nano_teachers_template.csv',
                                contents: TeacherImportCsv.template,
                              );
                              _csv.text = TeacherImportCsv.template;
                              setState(() {});
                            },
                      child: Text(copy.teachersDownloadTemplate),
                    ),
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () async {
                              final text = await pickCsvFile();
                              if (!mounted || text == null) return;
                              setState(() {
                                _csv.text = text;
                                _preview = null;
                              });
                              await _previewImport();
                            },
                      child: Text(copy.teachersChooseCsv),
                    ),
                    OutlinedButton(
                      onPressed: _busy ? null : _previewImport,
                      child: Text(copy.teachersPreviewImport),
                    ),
                    FilledButton(
                      onPressed: _busy || !(preview?.canCommit ?? false)
                          ? null
                          : _commitImport,
                      child: Text(copy.teachersCommitImport),
                    ),
                    TextButton(
                      onPressed: () {
                        _csv.text = TeacherImportCsv.template;
                        setState(() {});
                      },
                      child: Text(copy.teachersLoadTemplate),
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
                for (final teacher in _teachers)
                  ListTile(
                    title: Text(teacher.displayName),
                    subtitle: Text(
                      '${teacher.email} · ${teacher.membershipStatus}',
                    ),
                    trailing: TextButton(
                      onPressed: _busy ? null : () => _toggleStatus(teacher),
                      child: Text(
                        teacher.isSuspended
                            ? copy.teachersRestoreTitle
                            : copy.teachersSuspendTitle,
                      ),
                    ),
                  ),
                if (_teachers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: NanoSpacing.md),
                    child: Text(copy.teachersEmpty),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
