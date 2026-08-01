import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/app/component_gallery_page.dart';
import 'package:student_app/app/states_preview_page.dart';
import 'package:student_app/app/sync_preview_page.dart';
import 'package:student_app/app/locale_preview_page.dart';
import 'package:student_app/app/accessibility_settings_page.dart';
import 'package:student_app/app/supabase_health_page.dart';
import 'package:student_app/app/diagnostics_page.dart';
import 'package:student_app/app/environment_badge.dart';
import 'package:student_app/app/nav_placeholder_page.dart';
import 'package:nano_data/nano_data.dart';
import 'package:student_app/features/home/fixtures/student_home_fixtures.dart';
import 'package:student_app/features/home/presentation/junior_home_foundation.dart';
import 'package:student_app/features/home/presentation/junior_home_page.dart';
import 'package:student_app/features/home/presentation/responsive_preview_page.dart';
import 'package:student_app/features/home/presentation/senior_home_foundation.dart';
import 'package:student_app/features/home/presentation/senior_home_page.dart';
import 'package:student_app/features/learning/presentation/learning_progress_page.dart';
import 'package:student_app/features/learning/presentation/subject_topics_page.dart';
import 'package:student_app/features/learning/presentation/topic_detail_page.dart';
import 'package:student_app/features/profile/presentation/student_profile_page.dart';

class StudentShell extends StatelessWidget {
  const StudentShell({
    super.key,
    required this.config,
    required this.principal,
    required this.navigationShell,
    required this.onPrincipalChanged,
    required this.onLocaleChanged,
    required this.onAccessibilityChanged,
    required this.locale,
    required this.accessibility,
    this.onSignOut,
    this.liveAuth = false,
  });

  final EnvironmentConfig config;
  final SessionPrincipal principal;
  final StatefulNavigationShell navigationShell;
  final ValueChanged<SessionPrincipal> onPrincipalChanged;
  final ValueChanged<NanoAppLocale> onLocaleChanged;
  final ValueChanged<AccessibilityPreferences> onAccessibilityChanged;
  final NanoAppLocale locale;
  final AccessibilityPreferences accessibility;
  final VoidCallback? onSignOut;
  final bool liveAuth;

  @override
  Widget build(BuildContext context) {
    final destinations = NavCatalog.visibleFor(principal);
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        NanoCopy(NanoAppLocale.en);
    final junior = principal.role.usesJuniorPresentation;
    final items = [
      for (final d in destinations)
        NanoBottomNavItem(
          id: d.id,
          label: copy.studentNavLabel(d.id, junior: junior),
          icon: nanoNavIcon(d.iconName),
        ),
    ];

    final index = navigationShell.currentIndex.clamp(0, items.length - 1);

    return NanoScaffold(
      padBody: false,
      appBar: AppBar(
        title: Text(config.appDisplayName),
        actions: [
          if (config.environment.showDebugTools)
            EnvironmentBadge(environment: config.environment),
        ],
      ),
      body: Column(
        children: [
          if (config.environment.showDebugTools)
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: NanoSpacing.sm,
                  vertical: NanoSpacing.xs,
                ),
                child: Row(
                  children: [
                    DropdownButtonHideUnderline(
                      child: DropdownButton<NanoAppLocale>(
                        value: locale,
                        items: const [
                          DropdownMenuItem(
                            value: NanoAppLocale.en,
                            child: Text('EN'),
                          ),
                          DropdownMenuItem(
                            value: NanoAppLocale.ur,
                            child: Text('UR'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) onLocaleChanged(value);
                        },
                      ),
                    ),
                    const SizedBox(width: NanoSpacing.sm),
                    if (!liveAuth)
                      DropdownButtonHideUnderline(
                        child: DropdownButton<AppRole>(
                          value: principal.role,
                          items: const [
                            DropdownMenuItem(
                              value: AppRole.juniorStudent,
                              child: Text('Junior'),
                            ),
                            DropdownMenuItem(
                              value: AppRole.seniorStudent,
                              child: Text('Senior'),
                            ),
                            DropdownMenuItem(
                              value: AppRole.independentStudent,
                              child: Text('Independent'),
                            ),
                          ],
                          onChanged: (role) {
                            if (role == null) return;
                            final next = switch (role) {
                              AppRole.juniorStudent =>
                                SessionPrincipal.junior(),
                              AppRole.seniorStudent =>
                                SessionPrincipal.seniorSchool(),
                              AppRole.independentStudent =>
                                SessionPrincipal.independent(),
                              _ => principal,
                            };
                            onPrincipalChanged(next);
                          },
                        ),
                      ),
                    if (liveAuth && onSignOut != null) ...[
                      const SizedBox(width: NanoSpacing.sm),
                      TextButton(onPressed: onSignOut, child: const Text('Sign out')),
                    ],
                  ],
                ),
              ),
            ),
          Expanded(child: navigationShell),
          if (config.environment.showDebugTools)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: NanoSpacing.sm),
                child: Wrap(
                  spacing: NanoSpacing.sm,
                  alignment: WrapAlignment.center,
                  children: [
                    if (config.isFeatureEnabled('diagnostics'))
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  DiagnosticsPage(config: config),
                            ),
                          );
                        },
                        child: const Text('Diagnostics'),
                      ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ComponentGalleryPage(),
                          ),
                        );
                      },
                      child: const Text('Gallery'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const StatesPreviewPage(),
                          ),
                        );
                      },
                      child: const Text('UI states'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SyncPreviewPage(),
                          ),
                        );
                      },
                      child: const Text('Offline'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const LocalePreviewPage(),
                          ),
                        );
                      },
                      child: const Text('Locale'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => AccessibilitySettingsPage(
                              onChanged: onAccessibilityChanged,
                            ),
                          ),
                        );
                      },
                      child: const Text('A11y'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                SupabaseHealthPage(config: config),
                          ),
                        );
                      },
                      child: const Text('DB health'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ResponsivePreviewPage(),
                          ),
                        );
                      },
                      child: const Text('Responsive preview'),
                    ),
                    TextButton(
                      onPressed: () {
                        // Simulate a notification deep link to Flex.
                        final resolved =
                            DeepLinkResolver.resolve(principal, '/flex');
                        context.go(resolved.location);
                        if (resolved.fellBack && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Flex unavailable — opened Home instead',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Deep link: Flex'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
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

class StudentLearningTab extends StatelessWidget {
  const StudentLearningTab({
    super.key,
    required this.principal,
    this.homeRepository,
    this.catalogRepository,
    this.progressRepository,
    this.checkpointRepository,
    this.insightsRepository,
    this.learnerQuizRepository,
    this.companionName,
    this.onOpenFlex,
  });

  final SessionPrincipal principal;
  final StudentHomeRepository? homeRepository;
  final LearningCatalogRepository? catalogRepository;
  final LearningProgressRepository? progressRepository;
  final CheckpointRepository? checkpointRepository;
  final LearningInsightsRepository? insightsRepository;
  final LearnerQuizRepository? learnerQuizRepository;
  final String? companionName;
  final VoidCallback? onOpenFlex;

  void _openSubject(BuildContext context, LearningSubject subject) {
    final catalog = catalogRepository;
    if (catalog == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SubjectTopicsPage(
          repository: catalog,
          subjectId: subject.id,
          progressRepository: progressRepository,
          checkpointRepository: checkpointRepository,
          learnerQuizRepository: learnerQuizRepository,
          companionName: companionName,
          junior: principal.role.usesJuniorPresentation,
        ),
      ),
    );
  }

  /// Continue Learning follows the server's own recommendation rather than a
  /// client guess, and falls back to the progress screen when the suggested
  /// topic cannot be resolved from the catalog.
  Future<void> _continueLearning(BuildContext context) async {
    final insights = insightsRepository;
    if (insights == null) return;
    final junior = principal.role.usesJuniorPresentation;
    NextUpSuggestion? suggestion;
    try {
      suggestion = (await insights.loadInsights()).recommendation;
    } catch (_) {
      suggestion = null;
    }
    if (!context.mounted) return;

    final catalog = catalogRepository;
    final progress = progressRepository;
    if (suggestion != null && catalog != null && progress != null) {
      try {
        final loaded = await catalog.loadCatalog();
        final topic = loaded.subjects
            .expand((subject) => subject.topics)
            .where((item) => item.topicVersionId == suggestion!.topicVersionId)
            .firstOrNull;
        if (!context.mounted) return;
        if (topic != null) {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TopicDetailPage(
                topic: topic,
                progressRepository: progress,
                checkpointRepository: checkpointRepository,
                learnerQuizRepository: learnerQuizRepository,
                companionName: companionName,
                junior: junior,
              ),
            ),
          );
          return;
        }
      } catch (_) {
        // Fall through to the progress screen below.
      }
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LearningProgressPage(
          repository: insights,
          junior: junior,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = homeRepository;
    if (!principal.role.usesJuniorPresentation) {
      if (repository == null) {
        return const SeniorHomeFoundation();
      }
      return SeniorHomePage(
        repository: repository,
        learnerName: principal.displayName.isEmpty
            ? StudentHomeFixtures.studentName
            : principal.displayName,
        userId: principal.userId ?? 'local',
        companionName: companionName ?? 'Nori',
        flexEligible: NavCatalog.visibleFor(principal)
            .any((dest) => dest.id == 'flex'),
        onOpenFlex: onOpenFlex,
        onSubjectTap: (subject) => _openSubject(context, subject),
        onContinue: (_) => _continueLearning(context),
        onOpenUpdate: () {},
        onNotifications: () {},
      );
    }
    if (repository == null) {
      // Static preview until a data source is supplied (FND-03 foundation).
      return const JuniorHomeFoundation();
    }
    return JuniorHomePage(
      repository: repository,
      learnerName: principal.displayName.isEmpty
          ? StudentHomeFixtures.studentName
          : principal.displayName,
      userId: principal.userId ?? 'local',
      companionName: companionName ?? 'Nori',
      onSubjectTap: (subject) => _openSubject(context, subject),
      onContinue: (_) => _continueLearning(context),
      onNotifications: () {},
    );
  }
}

class StudentGamesTab extends StatelessWidget {
  const StudentGamesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const NavPlaceholderPage(title: 'Games');
  }
}

class StudentFlexTab extends StatelessWidget {
  const StudentFlexTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const NavPlaceholderPage(
      title: 'Flex',
      subtitle: 'School-eligible students only. Independent students never see this tab.',
    );
  }
}

class StudentCommunitiesTab extends StatelessWidget {
  const StudentCommunitiesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const NavPlaceholderPage(title: 'Communities');
  }
}

class StudentProfileTab extends StatelessWidget {
  const StudentProfileTab({
    super.key,
    required this.principal,
    this.profileRepository,
    this.insightsRepository,
    this.preferences,
    this.onPreferencesChanged,
    this.onAccessibilityChanged,
    this.onSignOut,
    this.syncController,
  });

  final SessionPrincipal principal;
  final StudentProfileRepository? profileRepository;
  final LearningInsightsRepository? insightsRepository;
  final StudentPreferences? preferences;
  final ValueChanged<StudentPreferences>? onPreferencesChanged;
  final ValueChanged<AccessibilityPreferences>? onAccessibilityChanged;
  final VoidCallback? onSignOut;
  final NanoSyncController? syncController;

  @override
  Widget build(BuildContext context) {
    final repository = profileRepository;
    if (repository == null) {
      final authLine = principal.isAuthenticated
          ? 'Signed in · ${principal.userId ?? '—'}'
          : 'Preview persona';
      return NavPlaceholderPage(
        title: 'Profile',
        subtitle:
            '${principal.displayName} · ${principal.role.label}\n$authLine',
      );
    }
    // Preview personas have no auth userId; the fake repository still needs one.
    final principalForProfile = principal.userId == null
        ? principal.copyWith(userId: TenancyFixtures.aliAlphaId)
        : principal;
    return StudentProfilePage(
      repository: repository,
      principal: principalForProfile,
      preferences: preferences ??
          StudentPreferences(userId: principalForProfile.userId!),
      onPreferencesChanged: onPreferencesChanged,
      onOpenAccessibility: onAccessibilityChanged == null
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AccessibilitySettingsPage(
                    onChanged: onAccessibilityChanged!,
                  ),
                ),
              );
            },
      onOpenProgress: insightsRepository == null
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => LearningProgressPage(
                    repository: insightsRepository!,
                    junior: principal.role.usesJuniorPresentation,
                  ),
                ),
              );
            },
      onSignOut: onSignOut == null
          ? null
          : () async {
              onSignOut!();
            },
      syncController: syncController,
    );
  }
}
