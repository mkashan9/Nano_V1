import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// ADM-02 Schools destination: list, create, status, first admin.
class SchoolsPage extends StatefulWidget {
  const SchoolsPage({
    super.key,
    required this.repository,
  });

  final SchoolAdminRepository repository;

  @override
  State<SchoolsPage> createState() => _SchoolsPageState();
}

class _SchoolsPageState extends State<SchoolsPage> {
  NanoViewState _state = const NanoViewLoading();
  List<ManagedSchool> _schools = const [];
  final _query = TextEditingController();
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final schools = await widget.repository.list(query: _query.text);
      if (!mounted) return;
      setState(() {
        _schools = schools;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  Future<void> _createSchool() async {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(copy.schoolsCreateTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: InputDecoration(
                  labelText: copy.schoolsCodeLabel,
                  hintText: 'ALPHA02',
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: copy.schoolsNameLabel),
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
              child: Text(copy.schoolsCreateAction),
            ),
          ],
        );
      },
    );
    if (created != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.repository.createSchool(
        code: codeController.text,
        name: nameController.text,
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      codeController.dispose();
      nameController.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeStatus(ManagedSchool school) async {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    var next = school.status;
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(copy.schoolsStatusTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<SchoolStatus>(
                    value: next,
                    items: [
                      for (final status in SchoolStatus.values)
                        DropdownMenuItem(
                          value: status,
                          child: Text(status.wireName),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setLocal(() => next = value);
                    },
                  ),
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      labelText: copy.schoolsReasonLabel,
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
                  child: Text(copy.schoolsSaveStatusAction),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.repository.setStatus(
        schoolId: school.id,
        status: next,
        reason: reasonController.text,
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      reasonController.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _assignAdmin(ManagedSchool school) async {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final userController = TextEditingController(
      text: TenancyFixtures.schoolAdminId,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(copy.schoolsAssignAdminTitle),
          content: TextField(
            controller: userController,
            decoration: InputDecoration(
              labelText: copy.schoolsAdminUserIdLabel,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(copy.cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(copy.schoolsAssignAdminAction),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.repository.assignFirstAdmin(
        schoolId: school.id,
        userId: userController.text.trim(),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      userController.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final theme = Theme.of(context);

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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        copy.schoolsPageTitle,
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _busy ? null : _createSchool,
                      icon: const Icon(Icons.add),
                      label: Text(copy.schoolsCreateAction),
                    ),
                  ],
                ),
                const SizedBox(height: NanoSpacing.xs),
                Text(
                  copy.schoolsPageSubtitle,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: NanoSpacing.md),
                TextField(
                  controller: _query,
                  decoration: InputDecoration(
                    hintText: copy.platformSchoolSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      onPressed: _busy ? null : _load,
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                  onSubmitted: (_) => _load(),
                ),
                const SizedBox(height: NanoSpacing.md),
                if (_schools.isEmpty)
                  Text(copy.platformSchoolsEmpty)
                else
                  for (final school in _schools)
                    Card(
                      margin: const EdgeInsets.only(bottom: NanoSpacing.sm),
                      child: ListTile(
                        leading: const Icon(Icons.apartment_outlined),
                        title: Text('${school.name} · ${school.code}'),
                        subtitle: Text(
                          '${school.status.wireName} · '
                          '${school.learnerCount} ${copy.platformMetricLearners.toLowerCase()} · '
                          '${school.hasSchoolAdmin ? copy.schoolsHasAdmin : copy.schoolsNeedsAdmin}',
                        ),
                        trailing: Wrap(
                          spacing: NanoSpacing.xs,
                          children: [
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _changeStatus(school),
                              child: Text(copy.schoolsStatusAction),
                            ),
                            if (!school.hasSchoolAdmin)
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => _assignAdmin(school),
                                child: Text(copy.schoolsAssignAdminAction),
                              ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
