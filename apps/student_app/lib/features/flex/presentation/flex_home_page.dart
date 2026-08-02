import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

import '../../../app/nav_placeholder_page.dart';
import 'student_attendance_page.dart';
import 'student_marks_page.dart';
import 'student_classroom_page.dart';

/// FLX Flex hub: attendance / marks / classroom entry points.
class FlexHomePage extends StatefulWidget {
  const FlexHomePage({
    super.key,
    required this.repository,
    required this.flexEligible,
    this.initialSection,
  });

  final StudentFlexRepository repository;
  final bool flexEligible;
  final FlexHubSectionKind? initialSection;

  @override
  State<FlexHomePage> createState() => _FlexHomePageState();
}

class _FlexHomePageState extends State<FlexHomePage> {
  NanoViewState _state = const NanoViewLoading();
  FlexHubSummary? _hub;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final hub = await widget.repository.loadHub(
        flexEligible: widget.flexEligible,
      );
      if (!mounted) return;
      setState(() {
        _hub = hub;
        _state = const NanoViewReady();
      });
      final initial = widget.initialSection;
      if (initial != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _openSection(initial);
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  void _openSection(FlexHubSectionKind kind) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    if (kind == FlexHubSectionKind.attendance) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StudentAttendancePage(
            repository: FakeStudentAttendanceRepository(),
          ),
        ),
      );
      return;
    }
    if (kind == FlexHubSectionKind.marks) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StudentMarksPage(
            repository: FakeStudentMarksRepository(),
          ),
        ),
      );
      return;
    }
    if (kind == FlexHubSectionKind.classroom) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StudentClassroomPage(
            repository: FakeStudentClassroomRepository(),
          ),
        ),
      );
      return;
    }
    final title = switch (kind) {
      FlexHubSectionKind.attendance => copy.flexAttendanceTitle,
      FlexHubSectionKind.marks => copy.flexMarksTitle,
      FlexHubSectionKind.classroom => copy.flexClassroomTitle,
    };
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NavPlaceholderPage(
          title: title,
          subtitle: copy.flexSectionComingSoon,
        ),
      ),
    );
  }

  String _subtitleFor(FlexHubSection section, NanoCopy copy) {
    final base = switch (section.kind) {
      FlexHubSectionKind.attendance => copy.flexAttendanceSubtitle,
      FlexHubSectionKind.marks => copy.flexMarksSubtitle,
      FlexHubSectionKind.classroom => copy.flexClassroomSubtitle,
    };
    if (!section.hasWork) return base;
    final open = copy.flexSectionOpen(section.openCount);
    final due = section.nextDueLabel;
    if (due == null || due.isEmpty) return '$base · $open';
    return '$base · $open · $due';
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final theme = Theme.of(context);
    final hub = _hub;

    if (!widget.flexEligible) {
      return NanoScaffold(
        padBody: true,
        body: Center(child: Text(copy.flexIndependentBlocked)),
      );
    }

    return NanoViewStateHost(
      state: _state,
      onRetry: _load,
      child: NanoScaffold(
        padBody: true,
        body: NanoResponsiveBuilder(
          builder: (context, windowSize, _) {
            return NanoMaxContentWidth(
              maxWidth: windowSize == NanoWindowSize.desktop ? 960 : 720,
              child: ListView(
                children: [
                  Text(copy.flexTitle, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: NanoSpacing.xs),
                  Text(copy.flexSubtitle, style: theme.textTheme.bodyMedium),
                  if (hub != null) ...[
                    const SizedBox(height: NanoSpacing.sm),
                    Text(
                      copy.flexOpenTasks(hub.openTasks),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: NanoSpacing.md),
                    for (final section in hub.sections) ...[
                      TeacherTaskCard(
                        title: switch (section.kind) {
                          FlexHubSectionKind.attendance =>
                            copy.flexAttendanceTitle,
                          FlexHubSectionKind.marks => copy.flexMarksTitle,
                          FlexHubSectionKind.classroom =>
                            copy.flexClassroomTitle,
                        },
                        subtitle: _subtitleFor(section, copy),
                        onTap: () => _openSection(section.kind),
                      ),
                      const SizedBox(height: NanoSpacing.sm),
                    ],
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
