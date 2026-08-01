import 'package:admin_web/features/content/presentation/content_hub_page.dart';
import 'package:admin_web/features/moderation/presentation/asset_review_page.dart';
import 'package:admin_web/features/platform/presentation/platform_dashboard_page.dart';
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
    this.assetReviewRepository,
    this.platformDashboardRepository,
    this.schoolAdminRepository,
    this.platformUserRepository,
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
  final AssetReviewRepository? assetReviewRepository;
  final PlatformDashboardRepository? platformDashboardRepository;
  final SchoolAdminRepository? schoolAdminRepository;
  final PlatformUserRepository? platformUserRepository;

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
    this.assetReviewRepository,
    this.platformDashboardRepository,
    this.schoolAdminRepository,
    this.platformUserRepository,
  });

  final NavDestination destination;
  final SessionPrincipal principal;
  final QuestionBankRepository? questionBankRepository;
  final TopicQuizRepository? topicQuizRepository;
  final LearningContentRepository? learningContentRepository;
  final AssetReviewRepository? assetReviewRepository;
  final PlatformDashboardRepository? platformDashboardRepository;
  final SchoolAdminRepository? schoolAdminRepository;
  final PlatformUserRepository? platformUserRepository;

  @override
  Widget build(BuildContext context) {
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

    // MED-05. The role check is a courtesy for the preview shell; the server
    // refuses a non-admin regardless of which screen they reach.
    if (destination.id == 'moderation' &&
        principal.role == AppRole.superadmin &&
        assetReviewRepository != null) {
      return AssetReviewPage(repository: assetReviewRepository!);
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
