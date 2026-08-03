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
import 'package:student_app/features/learning/presentation/learning_catalog_page.dart';
import 'package:student_app/features/learning/presentation/learning_progress_page.dart';
import 'package:student_app/features/learning/presentation/subject_topics_page.dart';
import 'package:student_app/features/learning/presentation/topic_detail_page.dart';
import 'package:student_app/features/profile/presentation/junior_profile_page.dart';
import 'package:student_app/features/profile/presentation/senior_profile_page.dart';
import 'package:student_app/features/profile/presentation/student_profile_page.dart';
import 'package:student_app/features/flex/presentation/flex_home_page.dart';
import 'package:student_app/features/games/presentation/games_catalog_page.dart';
import 'package:student_app/features/communities/presentation/communities_hub_page.dart';
import 'package:student_app/features/notifications/presentation/notifications_inbox_page.dart';

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
    final junior = principal.usesJuniorPresentation;
    final items = [
      for (final d in destinations)
        NanoBottomNavItem(
          id: d.id,
          label: copy.studentNavLabel(
            d.id,
            junior: junior,
            independent: principal.role == AppRole.independentStudent,
          ),
          icon: nanoNavIcon(d.iconName),
        ),
    ];

    final index = navigationShell.currentIndex.clamp(0, items.length - 1);

    return NanoScaffold(
      padBody: false,
      appBar: AppBar(
        title: Text(config.appDisplayName),
        actions: [
          if (liveAuth && onSignOut != null)
            TextButton(onPressed: onSignOut, child: const Text('Sign out')),
          if (config.showDebugChrome)
            EnvironmentBadge(environment: config.environment),
        ],
      ),
      body: Column(
        children: [
          if (config.showDebugChrome)
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
                  ],
                ),
              ),
            ),
          Expanded(child: navigationShell),
          if (config.showDebugChrome)
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

class StudentCatalogTab extends StatelessWidget {
  const StudentCatalogTab({
    super.key,
    required this.principal,
    this.catalogRepository,
    this.progressRepository,
    this.checkpointRepository,
    this.insightsRepository,
    this.learnerQuizRepository,
    this.quizAttemptRepository,
    this.companionName,
    this.learnerDisplayName,
    this.shareCards,
  });

  final SessionPrincipal principal;
  final LearningCatalogRepository? catalogRepository;
  final LearningProgressRepository? progressRepository;
  final CheckpointRepository? checkpointRepository;
  final LearningInsightsRepository? insightsRepository;
  final LearnerQuizRepository? learnerQuizRepository;
  final QuizAttemptRepository? quizAttemptRepository;
  final String? companionName;
  final String? learnerDisplayName;
  final ShareCardRepository? shareCards;

  @override
  Widget build(BuildContext context) {
    final catalog = catalogRepository ?? FakeLearningCatalogRepository();
    return LearningCatalogPage(
      repository: catalog,
      progressRepository: progressRepository,
      checkpointRepository: checkpointRepository,
      insightsRepository: insightsRepository,
      learnerQuizRepository: learnerQuizRepository,
      quizAttemptRepository: quizAttemptRepository,
      companionName: companionName,
      learnerDisplayName: learnerDisplayName ?? principal.displayName,
      shareCards: shareCards,
      junior: principal.usesJuniorPresentation,
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
    this.quizAttemptRepository,
    this.inboxRepository,
    this.accessRepository,
    this.companionName,
    this.learnerDisplayName,
    this.shareCards,
    this.onOpenFlex,
  });

  final SessionPrincipal principal;
  final StudentHomeRepository? homeRepository;
  final LearningCatalogRepository? catalogRepository;
  final LearningProgressRepository? progressRepository;
  final CheckpointRepository? checkpointRepository;
  final LearningInsightsRepository? insightsRepository;
  final LearnerQuizRepository? learnerQuizRepository;
  final QuizAttemptRepository? quizAttemptRepository;
  final StudentNotificationInboxRepository? inboxRepository;
  final IndependentAccessRepository? accessRepository;
  final String? companionName;
  final String? learnerDisplayName;
  final ShareCardRepository? shareCards;
  final VoidCallback? onOpenFlex;

  void _openNotifications(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsInboxPage(
          repository:
              inboxRepository ?? FakeStudentNotificationInboxRepository(),
          principal: principal,
        ),
      ),
    );
  }

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
          quizAttemptRepository: quizAttemptRepository,
          companionName: companionName,
          learnerDisplayName: learnerDisplayName ?? principal.displayName,
          shareCards: shareCards,
          junior: principal.usesJuniorPresentation,
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
    final junior = principal.usesJuniorPresentation;
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
                quizAttemptRepository: quizAttemptRepository,
                companionName: companionName,
                learnerDisplayName: learnerDisplayName ?? principal.displayName,
                shareCards: shareCards,
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
    if (!principal.usesJuniorPresentation) {
      if (repository == null) {
        return const SeniorHomeFoundation();
      }
      return _IndependentAwareSeniorHome(
        repository: repository,
        principal: principal,
        accessRepository: accessRepository,
        companionName: companionName ?? 'Nori',
        onOpenFlex: onOpenFlex,
        onSubjectTap: (subject) => _openSubject(context, subject),
        onContinue: (_) => _continueLearning(context),
        onNotifications: () => _openNotifications(context),
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
      onNotifications: () => _openNotifications(context),
    );
  }
}

/// IND-02: loads independent entitlements so Home can show a calm access banner.
class _IndependentAwareSeniorHome extends StatefulWidget {
  const _IndependentAwareSeniorHome({
    required this.repository,
    required this.principal,
    required this.companionName,
    this.accessRepository,
    this.onOpenFlex,
    this.onSubjectTap,
    this.onContinue,
    this.onNotifications,
  });

  final StudentHomeRepository repository;
  final SessionPrincipal principal;
  final String companionName;
  final IndependentAccessRepository? accessRepository;
  final VoidCallback? onOpenFlex;
  final ValueChanged<LearningSubject>? onSubjectTap;
  final ValueChanged<ContinueLearningItem>? onContinue;
  final VoidCallback? onNotifications;

  @override
  State<_IndependentAwareSeniorHome> createState() =>
      _IndependentAwareSeniorHomeState();
}

class _IndependentAwareSeniorHomeState
    extends State<_IndependentAwareSeniorHome> {
  IndependentEntitlements? _access;

  @override
  void initState() {
    super.initState();
    _loadAccess();
  }

  Future<void> _loadAccess() async {
    if (widget.principal.role != AppRole.independentStudent) return;
    final repo =
        widget.accessRepository ?? FakeIndependentAccessRepository();
    try {
      final access = await repo.loadAccess(
        userId: widget.principal.userId ?? 'local',
      );
      if (!mounted) return;
      setState(() => _access = access);
    } catch (_) {
      // Home still renders; banner is optional.
    }
  }

  @override
  Widget build(BuildContext context) {
    final principal = widget.principal;
    return SeniorHomePage(
      repository: widget.repository,
      learnerName: principal.displayName.isEmpty
          ? StudentHomeFixtures.studentName
          : principal.displayName,
      userId: principal.userId ?? 'local',
      companionName: widget.companionName,
      flexEligible:
          NavCatalog.visibleFor(principal).any((dest) => dest.id == 'flex'),
      independent: principal.role == AppRole.independentStudent,
      accessEntitlements: _access,
      onOpenFlex: widget.onOpenFlex,
      onOpenSpotlight: (spotlight) {
        final resolved =
            DeepLinkResolver.resolve(principal, spotlight.deepLinkPath);
        context.go(resolved.location);
        if (resolved.fellBack && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${spotlight.deepLinkPath} is unavailable — opened Home instead',
              ),
            ),
          );
        }
      },
      onSubjectTap: widget.onSubjectTap,
      onContinue: widget.onContinue,
      onOpenUpdate: () {},
      onNotifications: widget.onNotifications,
    );
  }
}

class StudentGamesTab extends StatelessWidget {
  const StudentGamesTab({
    super.key,
    this.repository,
    this.sessionRepository,
    this.assetRepository,
    this.localStorageRepository,
    this.accessRepository,
    this.accessibility = AccessibilityPreferences.defaults,
    this.onAccessibilityChanged,
    this.independent = false,
    this.gradeLevel,
    this.junior = false,
  });

  final GameCatalogRepository? repository;
  final GameSessionRepository? sessionRepository;
  final GameAssetRepository? assetRepository;
  final GameLocalStorageRepository? localStorageRepository;
  final IndependentAccessRepository? accessRepository;
  final AccessibilityPreferences accessibility;
  final ValueChanged<AccessibilityPreferences>? onAccessibilityChanged;
  final bool independent;
  final int? gradeLevel;
  final bool junior;

  @override
  Widget build(BuildContext context) {
    if (!independent) {
      return GamesCatalogPage(
        repository: repository ?? FakeGameCatalogRepository(),
        sessionRepository: sessionRepository ?? FakeGameSessionRepository(),
        assetRepository: assetRepository ?? FakeGameAssetRepository(),
        localStorageRepository:
            localStorageRepository ?? FakeGameLocalStorageRepository(),
        accessibility: accessibility,
        onAccessibilityChanged: onAccessibilityChanged,
        independent: independent,
        gradeLevel: gradeLevel,
        junior: junior,
      );
    }
    return _AccessGatedGames(
      catalogRepository: repository,
      sessionRepository: sessionRepository,
      assetRepository: assetRepository,
      localStorageRepository: localStorageRepository,
      accessRepository: accessRepository,
      accessibility: accessibility,
      onAccessibilityChanged: onAccessibilityChanged,
      gradeLevel: gradeLevel,
      junior: junior,
    );
  }
}

class _AccessGatedGames extends StatefulWidget {
  const _AccessGatedGames({
    this.catalogRepository,
    this.sessionRepository,
    this.assetRepository,
    this.localStorageRepository,
    this.accessRepository,
    this.accessibility = AccessibilityPreferences.defaults,
    this.onAccessibilityChanged,
    this.gradeLevel,
    this.junior = false,
  });

  final GameCatalogRepository? catalogRepository;
  final GameSessionRepository? sessionRepository;
  final GameAssetRepository? assetRepository;
  final GameLocalStorageRepository? localStorageRepository;
  final IndependentAccessRepository? accessRepository;
  final AccessibilityPreferences accessibility;
  final ValueChanged<AccessibilityPreferences>? onAccessibilityChanged;
  final int? gradeLevel;
  final bool junior;

  @override
  State<_AccessGatedGames> createState() => _AccessGatedGamesState();
}

class _AccessGatedGamesState extends State<_AccessGatedGames> {
  NanoViewState _state = const NanoViewLoading();
  IndependentEntitlements? _access;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final repo =
          widget.accessRepository ?? FakeIndependentAccessRepository();
      final access = await repo.loadAccess(userId: 'local');
      if (!mounted) return;
      setState(() {
        _access = access;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final access = _access;
    return NanoViewStateHost(
      state: _state,
      onRetry: _load,
      child: access == null
          ? const SizedBox.shrink()
          : !access.allows(IndependentFeature.games)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(NanoSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          copy.accessGamesBlocked,
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: NanoSpacing.sm),
                        Text(
                          copy.accessLearningAllowed,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : GamesCatalogPage(
                  repository:
                      widget.catalogRepository ?? FakeGameCatalogRepository(),
                  sessionRepository: widget.sessionRepository ??
                      FakeGameSessionRepository(),
                  assetRepository:
                      widget.assetRepository ?? FakeGameAssetRepository(),
                  localStorageRepository: widget.localStorageRepository ??
                      FakeGameLocalStorageRepository(),
                  accessibility: widget.accessibility,
                  onAccessibilityChanged: widget.onAccessibilityChanged,
                  independent: true,
                  gradeLevel: widget.gradeLevel,
                  junior: widget.junior,
                ),
    );
  }
}

class StudentFlexTab extends StatelessWidget {
  const StudentFlexTab({
    super.key,
    this.repository,
    this.attendanceRepository,
    this.marksRepository,
    this.classroomRepository,
    this.flexEligible = true,
    this.initialSection,
  });

  final StudentFlexRepository? repository;
  final StudentAttendanceRepository? attendanceRepository;
  final StudentMarksRepository? marksRepository;
  final StudentClassroomRepository? classroomRepository;
  final bool flexEligible;
  final FlexHubSectionKind? initialSection;


  @override
  Widget build(BuildContext context) {
    return FlexHomePage(
      repository: repository ?? FakeStudentFlexRepository(),
      attendanceRepository: attendanceRepository,
      marksRepository: marksRepository,
      classroomRepository: classroomRepository,
      flexEligible: flexEligible,
      initialSection: initialSection,
    );
  }
}

class StudentCommunitiesTab extends StatelessWidget {
  const StudentCommunitiesTab({
    super.key,
    this.repository,
    this.messagingRepository,
  });

  final CommunityDiscoveryRepository? repository;
  final CommunityMessagingRepository? messagingRepository;

  @override
  Widget build(BuildContext context) {
    return CommunitiesHubPage(
      repository: repository ?? FakeCommunityDiscoveryRepository(),
      messagingRepository:
          messagingRepository ?? FakeCommunityMessagingRepository(),
    );
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
    this.shareCards,
    this.leagueRepository,
    this.socialIdentityRepository,
    this.friendGraphRepository,
    this.safetyReportRepository,
    this.accessRepository,
    this.schoolLinkRepository,
    this.onSchoolLinked,
    this.showQaTools = false,
    this.useVisualLayout = true,
  });

  final SessionPrincipal principal;
  final StudentProfileRepository? profileRepository;
  final LearningInsightsRepository? insightsRepository;
  final StudentPreferences? preferences;
  final ValueChanged<StudentPreferences>? onPreferencesChanged;
  final ValueChanged<AccessibilityPreferences>? onAccessibilityChanged;
  final VoidCallback? onSignOut;
  final NanoSyncController? syncController;
  final ShareCardRepository? shareCards;
  final LeagueRepository? leagueRepository;
  final SocialIdentityRepository? socialIdentityRepository;
  final FriendGraphRepository? friendGraphRepository;
  final SafetyReportRepository? safetyReportRepository;
  final IndependentAccessRepository? accessRepository;
  final SchoolLinkRepository? schoolLinkRepository;
  final ValueChanged<SessionPrincipal>? onSchoolLinked;
  final bool showQaTools;
  /// When true (default), senior Me uses VIS-08 visual layout.
  final bool useVisualLayout;

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
    if (principal.usesJuniorPresentation) {
      return JuniorProfilePage(
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
      );
    }
    final openAccessibility = onAccessibilityChanged == null
        ? null
        : () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AccessibilitySettingsPage(
                  onChanged: onAccessibilityChanged!,
                ),
              ),
            );
          };
    if (useVisualLayout) {
      return SeniorProfilePage(
        repository: repository,
        principal: principalForProfile,
        preferences: preferences ??
            StudentPreferences(userId: principalForProfile.userId!),
        onPreferencesChanged: onPreferencesChanged,
        onOpenAccessibility: openAccessibility,
      );
    }
    return StudentProfilePage(
      repository: repository,
      principal: principalForProfile,
      preferences: preferences ??
          StudentPreferences(userId: principalForProfile.userId!),
      onPreferencesChanged: onPreferencesChanged,
      shareCards: shareCards,
      leagueRepository: leagueRepository,
      socialIdentityRepository: socialIdentityRepository,
      friendGraphRepository: friendGraphRepository,
      safetyReportRepository: safetyReportRepository,
      accessRepository: accessRepository,
      schoolLinkRepository: schoolLinkRepository,
      onSchoolLinked: onSchoolLinked,
      showQaTools: showQaTools,
      onOpenAccessibility: openAccessibility,
      onOpenProgress: insightsRepository == null
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => LearningProgressPage(
                    repository: insightsRepository!,
                    junior: principal.usesJuniorPresentation,
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
