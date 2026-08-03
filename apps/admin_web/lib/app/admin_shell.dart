import 'package:admin_web/features/analytics/presentation/platform_analytics_page.dart';
import 'package:admin_web/features/content/presentation/content_hub_page.dart';
import 'package:admin_web/features/games/presentation/game_admin_page.dart';
import 'package:admin_web/features/gamification/presentation/gamification_admin_page.dart';
import 'package:admin_web/features/moderation/presentation/moderation_hub_page.dart';
import 'package:admin_web/features/notifications/presentation/notification_admin_page.dart';
import 'package:admin_web/features/parent/presentation/parent_guidance_admin_page.dart';
import 'package:admin_web/features/platform/presentation/community_controls_page.dart';
import 'package:admin_web/features/platform/presentation/platform_dashboard_page.dart';
import 'package:admin_web/features/school/presentation/academic_structure_page.dart';
import 'package:admin_web/features/school/presentation/school_branding_settings_page.dart';
import 'package:admin_web/features/school/presentation/school_overview_page.dart';
import 'package:admin_web/features/school/presentation/school_reports_page.dart';
import 'package:admin_web/features/school/presentation/school_settings_page.dart';
import 'package:admin_web/features/school/presentation/school_students_page.dart';
import 'package:admin_web/features/school/presentation/school_teachers_page.dart';
import 'package:admin_web/features/school/presentation/teacher_assignments_page.dart';
import 'package:admin_web/features/schools/presentation/schools_page.dart';
import 'package:admin_web/features/users/presentation/users_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:nano_data/nano_data.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.config,
    required this.principal,
    required this.navigationShell,
    required this.onPrincipalChanged,
    required this.copy,
    this.onSignOut,
    this.liveAuth = false,
    this.questionBankRepository,
    this.topicQuizRepository,
    this.learningContentRepository,
    this.gamificationAdminRepository,
    this.gameAdminRepository,
    this.notificationAdminRepository,
    this.weeklyGuidanceAdminRepository,
    this.assetReviewRepository,
    this.moderationQueueRepository,
    this.platformDashboardRepository,
    this.platformAnalyticsRepository,
    this.schoolDashboardRepository,
    this.academicStructureRepository,
    this.schoolTeacherRepository,
    this.schoolStudentRepository,
    this.teacherAssignmentRepository,
    this.schoolMarksPolicyRepository,
    this.schoolReportsRepository,
    this.schoolAdminRepository,
    this.platformUserRepository,
    this.communityControlsRepository,
  });

  final EnvironmentConfig config;
  final SessionPrincipal principal;
  final StatefulNavigationShell navigationShell;
  final ValueChanged<SessionPrincipal> onPrincipalChanged;
  final NanoCopy copy;
  final VoidCallback? onSignOut;
  final bool liveAuth;
  final QuestionBankRepository? questionBankRepository;
  final TopicQuizRepository? topicQuizRepository;
  final LearningContentRepository? learningContentRepository;
  final GamificationAdminRepository? gamificationAdminRepository;
  final GameAdminRepository? gameAdminRepository;
  final NotificationAdminRepository? notificationAdminRepository;
  final WeeklyGuidanceAdminRepository? weeklyGuidanceAdminRepository;
  final AssetReviewRepository? assetReviewRepository;
  final ModerationQueueRepository? moderationQueueRepository;
  final PlatformDashboardRepository? platformDashboardRepository;
  final PlatformAnalyticsRepository? platformAnalyticsRepository;
  final SchoolDashboardRepository? schoolDashboardRepository;
  final AcademicStructureRepository? academicStructureRepository;
  final SchoolTeacherRepository? schoolTeacherRepository;
  final SchoolStudentRepository? schoolStudentRepository;
  final TeacherAssignmentRepository? teacherAssignmentRepository;
  final SchoolMarksPolicyRepository? schoolMarksPolicyRepository;
  final SchoolReportsRepository? schoolReportsRepository;
  final SchoolAdminRepository? schoolAdminRepository;
  final PlatformUserRepository? platformUserRepository;
  final CommunityControlsRepository? communityControlsRepository;

  @override
  Widget build(BuildContext context) {
    final destinations = NavCatalog.visibleFor(principal);
    final items = [
      for (final d in destinations)
        NanoSideRailItem(
          id: d.id,
          label: copy.navLabel(d.id),
          icon: nanoNavIcon(d.iconName),
        ),
    ];
    final index = navigationShell.currentIndex.clamp(0, items.length - 1);
    final title = principal.role == AppRole.superadmin
        ? '${config.appDisplayName} Superadmin'
        : '${config.appDisplayName} School';

    return Scaffold(
      body: Row(
        children: [
          NanoSideRail(
            title: title,
            items: items,
            selectedIndex: index,
            onSelect: (i) => navigationShell.goBranch(
              i,
              initialLocation: i == navigationShell.currentIndex,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                if (config.environment.showDebugTools)
                  Material(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: NanoSpacing.md,
                        vertical: NanoSpacing.sm,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (!liveAuth) ...[
                              Text(
                                'Shell',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(width: NanoSpacing.sm),
                              SegmentedButton<AppRole>(
                                segments: const [
                                  ButtonSegment(
                                    value: AppRole.schoolAdmin,
                                    label: Text('School'),
                                  ),
                                  ButtonSegment(
                                    value: AppRole.superadmin,
                                    label: Text('Superadmin'),
                                  ),
                                ],
                                selected: {principal.role},
                                onSelectionChanged: (roles) {
                                  final role = roles.first;
                                  onPrincipalChanged(
                                    role == AppRole.superadmin
                                        ? SessionPrincipal.superadmin()
                                        : SessionPrincipal.schoolAdmin(),
                                  );
                                },
                              ),
                              const SizedBox(width: NanoSpacing.md),
                            ],
                            if (liveAuth && onSignOut != null) ...[
                              TextButton(
                                onPressed: onSignOut,
                                child: const Text('Sign out'),
                              ),
                              const SizedBox(width: NanoSpacing.md),
                            ],
                            Chip(
                              label: Text(
                                config.environment.name.toUpperCase(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Expanded(child: navigationShell),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminDestinationPage extends StatelessWidget {
  const AdminDestinationPage({
    super.key,
    required this.destination,
    required this.principal,
    this.questionBankRepository,
    this.topicQuizRepository,
    this.learningContentRepository,
    this.gamificationAdminRepository,
    this.gameAdminRepository,
    this.notificationAdminRepository,
    this.weeklyGuidanceAdminRepository,
    this.assetReviewRepository,
    this.moderationQueueRepository,
    this.platformDashboardRepository,
    this.platformAnalyticsRepository,
    this.schoolDashboardRepository,
    this.academicStructureRepository,
    this.schoolTeacherRepository,
    this.schoolStudentRepository,
    this.teacherAssignmentRepository,
    this.schoolMarksPolicyRepository,
    this.schoolReportsRepository,
    this.schoolAdminRepository,
    this.platformUserRepository,
    this.communityControlsRepository,
  });

  final NavDestination destination;
  final SessionPrincipal principal;
  final QuestionBankRepository? questionBankRepository;
  final TopicQuizRepository? topicQuizRepository;
  final LearningContentRepository? learningContentRepository;
  final GamificationAdminRepository? gamificationAdminRepository;
  final GameAdminRepository? gameAdminRepository;
  final NotificationAdminRepository? notificationAdminRepository;
  final WeeklyGuidanceAdminRepository? weeklyGuidanceAdminRepository;
  final AssetReviewRepository? assetReviewRepository;
  final ModerationQueueRepository? moderationQueueRepository;
  final PlatformDashboardRepository? platformDashboardRepository;
  final PlatformAnalyticsRepository? platformAnalyticsRepository;
  final SchoolDashboardRepository? schoolDashboardRepository;
  final AcademicStructureRepository? academicStructureRepository;
  final SchoolTeacherRepository? schoolTeacherRepository;
  final SchoolStudentRepository? schoolStudentRepository;
  final TeacherAssignmentRepository? teacherAssignmentRepository;
  final SchoolMarksPolicyRepository? schoolMarksPolicyRepository;
  final SchoolReportsRepository? schoolReportsRepository;
  final SchoolAdminRepository? schoolAdminRepository;
  final PlatformUserRepository? platformUserRepository;
  final CommunityControlsRepository? communityControlsRepository;

  @override
  Widget build(BuildContext context) {
    if (destination.id == 'overview' &&
        principal.role == AppRole.schoolAdmin &&
        schoolDashboardRepository != null) {
      return SchoolOverviewPage(repository: schoolDashboardRepository!);
    }

    if (destination.id == 'settings' &&
        principal.role == AppRole.schoolAdmin &&
        schoolDashboardRepository != null &&
        schoolMarksPolicyRepository != null) {
      return SchoolSettingsPage(
        dashboardRepository: schoolDashboardRepository!,
        marksPolicyRepository: schoolMarksPolicyRepository!,
      );
    }

    if (destination.id == 'settings' &&
        principal.role == AppRole.schoolAdmin &&
        schoolDashboardRepository != null) {
      return SchoolBrandingSettingsPage(
        repository: schoolDashboardRepository!,
      );
    }

    if (destination.id == 'classes' &&
        principal.role == AppRole.schoolAdmin &&
        academicStructureRepository != null) {
      return AcademicStructurePage(
        repository: academicStructureRepository!,
      );
    }

    if (destination.id == 'teachers' &&
        principal.role == AppRole.schoolAdmin &&
        schoolTeacherRepository != null) {
      return SchoolTeachersPage(repository: schoolTeacherRepository!);
    }

    if (destination.id == 'students' &&
        principal.role == AppRole.schoolAdmin &&
        schoolStudentRepository != null) {
      return SchoolStudentsPage(repository: schoolStudentRepository!);
    }

    if (destination.id == 'assignments' &&
        principal.role == AppRole.schoolAdmin &&
        teacherAssignmentRepository != null) {
      return TeacherAssignmentsPage(repository: teacherAssignmentRepository!);
    }

    if (destination.id == 'reports' &&
        principal.role == AppRole.schoolAdmin &&
        schoolReportsRepository != null) {
      return SchoolReportsPage(repository: schoolReportsRepository!);
    }

    // ADM-01: Platform home absorbs the previous stub without replacing
    // Content or Moderation.
    if (destination.id == 'platform' &&
        principal.role == AppRole.superadmin &&
        platformDashboardRepository != null) {
      return PlatformDashboardPage(
        repository: platformDashboardRepository!,
      );
    }

    if (destination.id == 'schools' &&
        principal.role == AppRole.superadmin &&
        schoolAdminRepository != null) {
      return SchoolsPage(repository: schoolAdminRepository!);
    }

    if (destination.id == 'users' &&
        principal.role == AppRole.superadmin &&
        platformUserRepository != null) {
      return UsersPage(repository: platformUserRepository!);
    }

    if (destination.id == 'content' &&
        principal.role == AppRole.superadmin &&
        questionBankRepository != null &&
        topicQuizRepository != null &&
        learningContentRepository != null) {
      return ContentHubPage(
        questionBankRepository: questionBankRepository!,
        topicQuizRepository: topicQuizRepository!,
        learningContentRepository: learningContentRepository!,
      );
    }

    if (destination.id == 'gamification' &&
        principal.role == AppRole.superadmin &&
        gamificationAdminRepository != null) {
      return GamificationAdminPage(
        repository: gamificationAdminRepository!,
      );
    }

    if (destination.id == 'gameAdmin' &&
        principal.role == AppRole.superadmin &&
        gameAdminRepository != null) {
      return GameAdminPage(repository: gameAdminRepository!);
    }

    if (destination.id == 'notifications' &&
        principal.role == AppRole.superadmin &&
        notificationAdminRepository != null) {
      return NotificationAdminPage(
        repository: notificationAdminRepository!,
      );
    }

    if (destination.id == 'parentGuidance' &&
        principal.role == AppRole.superadmin &&
        weeklyGuidanceAdminRepository != null) {
      return ParentGuidanceAdminPage(
        repository: weeklyGuidanceAdminRepository!,
      );
    }

    if (destination.id == 'analytics' &&
        principal.role == AppRole.superadmin &&
        platformAnalyticsRepository != null) {
      return PlatformAnalyticsPage(
        repository: platformAnalyticsRepository!,
      );
    }

    // MED-05 + SAFE-02. Server refuses non-admins regardless of shell role.
    if (destination.id == 'moderation' &&
        principal.role == AppRole.superadmin &&
        (assetReviewRepository != null ||
            moderationQueueRepository != null)) {
      return ModerationHubPage(
        assetReviewRepository: assetReviewRepository,
        moderationQueueRepository: moderationQueueRepository,
      );
    }

    if (destination.id == 'communityControls' &&
        principal.role == AppRole.superadmin &&
        communityControlsRepository != null) {
      return CommunityControlsPage(
        repository: communityControlsRepository!,
      );
    }

    final authLine = principal.isAuthenticated
        ? 'Signed in · ${principal.userId ?? '—'}'
        : 'Preview persona';
    return NanoScaffold(
      padBody: true,
      body: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                destination.label,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: NanoSpacing.sm),
              Text(
                '${principal.role.label} shell · path ${destination.path}',
              ),
              const SizedBox(height: NanoSpacing.sm),
              Text(authLine),
              const SizedBox(height: NanoSpacing.md),
              const Text(
                'Permission-filtered foundation. Bulk workflows arrive in later modules.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
