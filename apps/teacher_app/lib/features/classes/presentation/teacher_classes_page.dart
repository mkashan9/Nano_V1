import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// TCH-02 My Classes: active scopes and assignment-guarded roster.
class TeacherClassesPage extends StatefulWidget {
  const TeacherClassesPage({
    super.key,
    required this.repository,
    this.initialAssignmentId,
  });

  final TeacherClassesRepository repository;
  final String? initialAssignmentId;

  @override
  State<TeacherClassesPage> createState() => _TeacherClassesPageState();
}

class _TeacherClassesPageState extends State<TeacherClassesPage> {
  NanoViewState _state = const NanoViewLoading();
  TeacherMyClasses? _mine;
  TeacherClassRoster? _roster;
  String? _selectedAssignmentId;
  var _loadingRoster = false;

  @override
  void initState() {
    super.initState();
    _selectedAssignmentId = widget.initialAssignmentId;
    _load();
  }

  @override
  void didUpdateWidget(covariant TeacherClassesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialAssignmentId != widget.initialAssignmentId) {
      _selectedAssignmentId = widget.initialAssignmentId;
      if (_selectedAssignmentId != null) {
        _loadRoster(_selectedAssignmentId!);
      } else {
        setState(() => _roster = null);
      }
    }
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final mine = await widget.repository.listMine();
      if (!mounted) return;
      setState(() {
        _mine = mine;
        _state = const NanoViewReady();
      });
      final selected = _selectedAssignmentId;
      if (selected != null && selected.isNotEmpty) {
        await _loadRoster(selected);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  Future<void> _loadRoster(String assignmentId) async {
    setState(() {
      _selectedAssignmentId = assignmentId;
      _loadingRoster = true;
    });
    try {
      final roster = await widget.repository.loadRoster(assignmentId);
      if (!mounted) return;
      setState(() {
        _roster = roster;
        _loadingRoster = false;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _roster = null;
        _loadingRoster = false;
        _state = const NanoViewError();
      });
    }
  }

  void _clearRoster() {
    setState(() {
      _selectedAssignmentId = null;
      _roster = null;
      _state = const NanoViewReady();
    });
    try {
      GoRouter.of(context).go('/classes');
    } catch (_) {
      // Widget tests may mount without a GoRouter.
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final theme = Theme.of(context);
    final mine = _mine;
    final roster = _roster;
    final showingRoster =
        _selectedAssignmentId != null && _selectedAssignmentId!.isNotEmpty;

    return NanoViewStateHost(
      state: _state,
      onRetry: showingRoster && _selectedAssignmentId != null
          ? () => _loadRoster(_selectedAssignmentId!)
          : _load,
      child: Scaffold(
        body: showingRoster
            ? _RosterBody(
                copy: copy,
                theme: theme,
                roster: roster,
                loading: _loadingRoster,
                onBack: _clearRoster,
              )
            : _ListBody(
                copy: copy,
                theme: theme,
                mine: mine,
                onOpen: (id) {
                  _loadRoster(id);
                  try {
                    GoRouter.of(context).go('/classes?assignment=$id');
                  } catch (_) {
                    // Widget tests may mount without a GoRouter.
                  }
                },
              ),
      ),
    );
  }
}

class _ListBody extends StatelessWidget {
  const _ListBody({
    required this.copy,
    required this.theme,
    required this.mine,
    required this.onOpen,
  });

  final NanoCopy copy;
  final ThemeData theme;
  final TeacherMyClasses? mine;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final assignments = mine?.assignments ?? const <TeacherAssignmentScope>[];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(copy.teacherClassesTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          copy.teacherClassesSubtitle,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        if (assignments.isEmpty)
          Text(copy.teacherClassesEmpty)
        else
          for (final scope in assignments)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(scope.scopeLabel),
                subtitle: Text(scope.subjectName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onOpen(scope.id),
              ),
            ),
      ],
    );
  }
}

class _RosterBody extends StatelessWidget {
  const _RosterBody({
    required this.copy,
    required this.theme,
    required this.roster,
    required this.loading,
    required this.onBack,
  });

  final NanoCopy copy;
  final ThemeData theme;
  final TeacherClassRoster? roster;
  final bool loading;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    if (loading && roster == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final data = roster;
    if (data == null) {
      return Center(child: Text(copy.teacherClassesRosterDenied));
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            label: Text(copy.teacherClassesBack),
          ),
        ),
        Text(data.scopeLabel, style: theme.textTheme.headlineSmall),
        Text(
          copy.teacherClassesRosterCount(data.studentCount),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        if (data.students.isEmpty)
          Text(copy.teacherClassesRosterEmpty)
        else
          for (final student in data.students)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(
                student.displayName.trim().isEmpty
                    ? copy.teacherClassesStudentFallback
                    : student.displayName,
              ),
              subtitle: Text(student.enrollmentStatus),
            ),
      ],
    );
  }
}
