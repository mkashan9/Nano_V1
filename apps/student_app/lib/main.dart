import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_auth/nano_auth.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/app/student_router.dart';
import 'package:student_app/features/home/fixtures/student_home_fixtures.dart';

void main() {
  final config = EnvironmentConfig.fromEnvironment();
  AuthRepository? authRepository;
  OnboardingRepository? onboardingRepository;
  StudentPreferencesRepository? preferencesRepository;
  var requireAuth = false;
  if (config.supabaseUrl.isNotEmpty && config.supabaseAnonKey.isNotEmpty) {
    final client =
        NanoAuthClient.create(config.supabaseUrl, config.supabaseAnonKey);
    authRepository = SupabaseAuthRepository(
      client,
      allowedAccountKinds: const {
        'school_student',
        'independent_student',
      },
      appLabel: 'students',
    );
    onboardingRepository = SupabaseOnboardingRepository(client);
    preferencesRepository = SupabaseStudentPreferencesRepository(client);
    requireAuth = true;
  }
  runApp(
    NanoStudentApp(
      config: config,
      authRepository: authRepository,
      onboardingRepository: onboardingRepository,
      preferencesRepository: preferencesRepository,
      requireAuth: requireAuth,
    ),
  );
}

class NanoStudentApp extends StatefulWidget {
  const NanoStudentApp({
    super.key,
    required this.config,
    this.initialPrincipal,
    this.initialLocation,
    this.initialLocale = NanoAppLocale.en,
    this.initialAccessibility = AccessibilityPreferences.defaults,
    this.authRepository,
    this.onboardingRepository,
    this.preferencesRepository,
    this.homeRepository,
    this.profileRepository,
    this.syncController,
    this.requireAuth = false,
  });

  final EnvironmentConfig config;
  final SessionPrincipal? initialPrincipal;
  final String? initialLocation;
  final NanoAppLocale initialLocale;
  final AccessibilityPreferences initialAccessibility;
  final AuthRepository? authRepository;
  final OnboardingRepository? onboardingRepository;
  final StudentPreferencesRepository? preferencesRepository;
  final StudentHomeRepository? homeRepository;
  final StudentProfileRepository? profileRepository;
  final NanoSyncController? syncController;
  final bool requireAuth;

  @override
  State<NanoStudentApp> createState() => _NanoStudentAppState();
}

class _NanoStudentAppState extends State<NanoStudentApp> {
  late SessionPrincipal _principal;
  late GoRouter _router;
  late NanoAppLocale _locale;
  late AccessibilityPreferences _a11y;
  late final NanoFeedback _feedback;
  AuthBootstrap? _authBootstrap;
  OnboardingProgress? _onboarding;
  StudentPreferences? _preferences;
  late final StudentHomeRepository _homeRepository;
  late final StudentProfileRepository _profileRepository;
  late final NanoSyncController _syncController;
  var _restoring = false;

  @override
  void initState() {
    super.initState();
    _principal = widget.initialPrincipal ??
        (widget.requireAuth
            ? SessionPrincipal.junior(displayName: '')
            : SessionPrincipal.junior());
    _locale = widget.initialLocale;
    _a11y = widget.initialAccessibility;
    // Home and profile content stay on fixtures until LRN/XP modules land.
    _homeRepository = widget.homeRepository ??
        FakeStudentHomeRepository(
          subjects: StudentHomeFixtures.subjects,
          missions: StudentHomeFixtures.missions,
        );
    _profileRepository = widget.profileRepository ??
        FakeStudentProfileRepository(
          sessions: [
            SecurityFixtures.activeSession.copyWith(isCurrent: true),
            SecurityFixtures.revokedSession,
            DeviceSession(
              id: 'f3333333-3333-3333-3333-333333333333',
              userId: TenancyFixtures.aliAlphaId,
              schoolId: TenancyFixtures.alphaSchoolId,
              deviceLabel: 'iPad',
              lastSeenAt: DateTime.now().toUtc().subtract(
                    const Duration(hours: 5),
                  ),
            ),
          ],
        );
    _syncController = widget.syncController ?? NanoSyncController();
    _feedback = NanoFeedback(preferences: _a11y);
    _router = _createRouter();
    if (widget.requireAuth && widget.authRepository != null) {
      _restore();
    }
  }

  Future<void> _restore() async {
    setState(() => _restoring = true);
    try {
      final restored = await widget.authRepository!.restoreSession();
      if (!mounted || restored == null) return;
      setState(() {
        _authBootstrap = restored;
        _principal = restored.principal;
        _router = _createRouter();
      });
      await _loadOnboarding(restored.principal);
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  Future<void> _loadOnboarding(SessionPrincipal principal) async {
    final repo = widget.onboardingRepository;
    final userId = principal.userId;
    if (repo == null || userId == null) return;
    final progress = await repo.load(userId);
    final prefs = await widget.preferencesRepository?.load(userId);
    if (!mounted) return;
    setState(() {
      _onboarding = progress;
      if (prefs != null) {
        _applyPreferences(prefs);
      }
      _router = _createRouter();
    });
  }

  /// Server settings win over local defaults once a learner has saved them.
  void _applyPreferences(StudentPreferences prefs) {
    _preferences = prefs;
    _locale = prefs.locale;
    _a11y = prefs.accessibility;
    _feedback.updatePreferences(prefs.accessibility);
  }

  void _onOnboardingCompleted(
    OnboardingProgress progress,
    ExperienceTrack track,
  ) {
    final role = ExperiencePolicy.roleFor(
      track: track,
      independent: _principal.role == AppRole.independentStudent,
    );
    final upgraded = switch (role) {
      AppRole.juniorStudent =>
        SessionPrincipal.junior(displayName: _principal.displayName),
      AppRole.seniorStudent => SessionPrincipal.seniorSchool(
          displayName: _principal.displayName,
          flexEligible: _principal.schoolId != null,
        ),
      _ => SessionPrincipal.independent(displayName: _principal.displayName),
    }
        .copyWith(
      userId: _principal.userId,
      schoolId: _principal.schoolId,
      isAuthenticated: _principal.isAuthenticated,
    );
    setState(() {
      _onboarding = progress;
      _principal = upgraded;
      _router = _createRouter();
    });
  }

  GoRouter _createRouter() {
    return createStudentRouter(
      config: widget.config,
      principal: _principal,
      onPrincipalChanged: _setPrincipal,
      onLocaleChanged: _setLocale,
      onAccessibilityChanged: _setA11y,
      locale: _locale,
      accessibility: _a11y,
      initialLocation: widget.initialLocation,
      authRepository: widget.authRepository,
      requireAuth: widget.requireAuth,
      authBootstrap: _authBootstrap,
      onAuthBootstrap: (bootstrap) {
        setState(() {
          _authBootstrap = bootstrap;
          _principal = bootstrap.principal;
          _router = _createRouter();
        });
        _loadOnboarding(bootstrap.principal);
      },
      onSignedOut: _signOut,
      onboardingRepository: widget.onboardingRepository,
      onboardingProgress: _onboarding,
      onOnboardingChanged: (progress) => _onboarding = progress,
      onOnboardingCompleted: _onOnboardingCompleted,
      preferencesRepository: widget.preferencesRepository,
      preferences: _preferences,
      onPreferencesChanged: (prefs) => setState(() {
        _applyPreferences(prefs);
        _router = _createRouter();
      }),
      homeRepository: _homeRepository,
      profileRepository: _profileRepository,
      syncController: _syncController,
    );
  }

  Future<void> _signOut() async {
    // Clear private caches first so a failed network still leaves nothing
    // for the next person on this device (handbook PRF-01).
    _syncController.cache.clear();
    _syncController.queue.clear();
    await widget.authRepository?.signOut();
    if (!mounted) return;
    setState(() {
      _authBootstrap = null;
      _onboarding = null;
      _preferences = null;
      _locale = NanoAppLocale.en;
      _a11y = AccessibilityPreferences.defaults;
      _feedback.updatePreferences(_a11y);
      _principal = SessionPrincipal.junior(displayName: '');
      _router = _createRouter();
    });
  }

  void _setPrincipal(SessionPrincipal next) {
    setState(() {
      _principal = next;
      _router = _createRouter();
    });
  }

  void _setLocale(NanoAppLocale next) {
    setState(() {
      _locale = next;
      _router = _createRouter();
    });
    _persistPreferences(locale: next);
  }

  void _setA11y(AccessibilityPreferences next) {
    setState(() {
      _a11y = next;
      _feedback.updatePreferences(next);
    });
    _persistPreferences(accessibility: next);
  }

  /// Settings changed outside onboarding still belong to the learner's row.
  Future<void> _persistPreferences({
    NanoAppLocale? locale,
    AccessibilityPreferences? accessibility,
  }) async {
    final repo = widget.preferencesRepository;
    final userId = _principal.userId;
    if (repo == null || userId == null) return;
    final base = _preferences ?? StudentPreferences(userId: userId);
    final next = base.copyWith(locale: locale, accessibility: accessibility);
    _preferences = next;
    await repo.save(next);
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoCopy(_locale);
    final theme = _principal.role.usesJuniorPresentation
        ? NanoTheme.junior(localeTag: _locale.tag)
        : NanoTheme.senior(localeTag: _locale.tag);
    final flutterLocale = Locale(_locale.languageCode);
    if (_restoring) {
      return MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return NanoLocaleScope(
      locale: _locale,
      copy: copy,
      child: NanoAccessibilityScope(
        preferences: _a11y,
        feedback: _feedback,
        child: MaterialApp.router(
          key: ValueKey(
            '${_principal.role}-${_principal.isAuthenticated}-'
            '${_onboarding?.isComplete ?? false}-'
            '${_locale.tag}-${_a11y.reducedMotion}-'
            '${_a11y.classroomMode}-${_a11y.textScale}',
          ),
          title: copy.appName,
          theme: theme,
          locale: flutterLocale,
          supportedLocales: const [
            Locale('en'),
            Locale('ur'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            final scaled = mq.textScaler.scale(1) * _a11y.textScale;
            return MediaQuery(
              data: mq.copyWith(
                textScaler: TextScaler.linear(scaled),
                disableAnimations:
                    mq.disableAnimations || _a11y.effectiveReducedMotion,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          routerConfig: _router,
        ),
      ),
    );
  }
}
