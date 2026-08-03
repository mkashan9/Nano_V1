import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:teacher_app/features/attendance/presentation/teacher_attendance_page.dart';
import 'package:teacher_app/features/classroom/presentation/teacher_classroom_page.dart';
import 'package:teacher_app/features/classes/presentation/teacher_classes_page.dart';
import 'package:teacher_app/features/feedback/presentation/teacher_feedback_page.dart';
import 'package:teacher_app/features/home/presentation/teacher_dashboard_page.dart';
import 'package:teacher_app/features/marks/presentation/teacher_marks_page.dart';

class TeacherShell extends StatelessWidget {
  const TeacherShell({
    super.key,
    required this.config,
    required this.principal,
    required this.navigationShell,
    required this.copy,
    this.onSignOut,
    this.liveAuth = false,
    this.teacherDashboardRepository,
    this.teacherClassesRepository,
    this.teacherAttendanceRepository,
    this.teacherAssessmentRepository,
    this.teacherClassroomRepository,
    this.teacherFeedbackRepository,
  });

  final EnvironmentConfig config;
  final SessionPrincipal principal;
  final StatefulNavigationShell navigationShell;
  final NanoCopy copy;
  final VoidCallback? onSignOut;
  final bool liveAuth;
  final TeacherDashboardRepository? teacherDashboardRepository;
  final TeacherClassesRepository? teacherClassesRepository;
  final TeacherAttendanceRepository? teacherAttendanceRepository;
  final TeacherAssessmentRepository? teacherAssessmentRepository;
  final TeacherClassroomRepository? teacherClassroomRepository;
  final TeacherFeedbackRepository? teacherFeedbackRepository;

  @override
  Widget build(BuildContext context) {
    final destinations = NavCatalog.visibleFor(principal);
    final items = [
      for (final d in destinations)
        NanoBottomNavItem(
          id: d.id,
          label: copy.navLabel(d.id),
          icon: nanoNavIcon(d.iconName),
        ),
    ];
    final index = navigationShell.currentIndex.clamp(0, items.length - 1);

    return NanoScaffold(
      padBody: false,
      appBar: AppBar(
        title: Text('${config.appDisplayName} Teacher'),
        actions: [
          if (liveAuth && onSignOut != null)
            TextButton(onPressed: onSignOut, child: const Text('Sign out')),
          if (config.showDebugChrome)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Chip(label: Text(config.environment.name.toUpperCase())),
            ),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: NanoBottomNav(
        items: items,
        selectedIndex: index,
        onSelect: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class TeacherDestinationPage extends StatelessWidget {
  const TeacherDestinationPage({
    super.key,
    required this.destination,
    this.teacherDashboardRepository,
    this.teacherClassesRepository,
    this.teacherAttendanceRepository,
    this.teacherAssessmentRepository,
    this.teacherClassroomRepository,
    this.teacherFeedbackRepository,
    this.assignmentId,
  });

  final NavDestination destination;
  final TeacherDashboardRepository? teacherDashboardRepository;
  final TeacherClassesRepository? teacherClassesRepository;
  final TeacherAttendanceRepository? teacherAttendanceRepository;
  final TeacherAssessmentRepository? teacherAssessmentRepository;
  final TeacherClassroomRepository? teacherClassroomRepository;
  final TeacherFeedbackRepository? teacherFeedbackRepository;
  final String? assignmentId;

  @override
  Widget build(BuildContext context) {
    if (destination.id == 'dashboard' && teacherDashboardRepository != null) {
      return TeacherDashboardPage(repository: teacherDashboardRepository!);
    }

    if (destination.id == 'classes' && teacherClassesRepository != null) {
      return TeacherClassesPage(
        repository: teacherClassesRepository!,
        initialAssignmentId: assignmentId,
      );
    }

    if (destination.id == 'attendance' &&
        teacherAttendanceRepository != null) {
      return TeacherAttendancePage(
        repository: teacherAttendanceRepository!,
        initialAssignmentId: assignmentId,
      );
    }

    if (destination.id == 'marks' && teacherAssessmentRepository != null) {
      return TeacherMarksPage(
        repository: teacherAssessmentRepository!,
        initialAssignmentId: assignmentId,
      );
    }

    if (destination.id == 'classroom' &&
        teacherClassroomRepository != null) {
      return TeacherClassroomPage(
        repository: teacherClassroomRepository!,
        initialAssignmentId: assignmentId,
      );
    }

    if (destination.id == 'feedback' && teacherFeedbackRepository != null) {
      return TeacherFeedbackPage(
        repository: teacherFeedbackRepository!,
        initialAssignmentId: assignmentId,
      );
    }

    return NanoScaffold(
      padBody: true,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              destination.label,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: NanoSpacing.sm),
            const Text('Teacher shell foundation — workflows arrive later.'),
          ],
        ),
      ),
    );
  }
}
