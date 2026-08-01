import 'package:admin_web/app/admin_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_auth/nano_auth.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  final config = EnvironmentConfig.fromEnvironment();
  AuthRepository? authRepository;
  AssetReviewRepository? assetReviewRepository;
  PlatformDashboardRepository? platformDashboardRepository;
  SchoolAdminRepository? schoolAdminRepository;
  PlatformUserRepository? platformUserRepository;
  LearningContentRepository? learningContentRepository;
  GamificationAdminRepository? gamificationAdminRepository;
  GameAdminRepository? gameAdminRepository;
  var requireAuth = false;
  if (config.supabaseUrl.isNotEmpty && config.supabaseAnonKey.isNotEmpty) {
    // One client, so the review calls carry the signed-in reviewer's token.
    // Publication is a named decision; an anonymous one would be worthless.
    final client =
        NanoAuthClient.create(config.supabaseUrl, config.supabaseAnonKey);
    authRepository = SupabaseAuthRepository(
      client,
      allowedAccountKinds: const {'school_staff', 'platform'},
      appLabel: 'admins',
    );
    assetReviewRepository = SupabaseAssetReviewRepository(client);
    platformDashboardRepository = SupabasePlatformDashboardRepository(client);
    schoolAdminRepository = SupabaseSchoolAdminRepository(client);
    platformUserRepository = SupabasePlatformUserRepository(client);
    learningContentRepository = SupabaseLearningContentRepository(client);
    gamificationAdminRepository = SupabaseGamificationAdminRepository(client);
    gameAdminRepository = SupabaseGameAdminRepository(client);
    requireAuth = true;
  }
  runApp(
    NanoAdminApp(
      config: config,
      authRepository: authRepository,
      assetReviewRepository: assetReviewRepository,
      platformDashboardRepository: platformDashboardRepository,
      schoolAdminRepository: schoolAdminRepository,
      platformUserRepository: platformUserRepository,
      learningContentRepository: learningContentRepository,
      gamificationAdminRepository: gamificationAdminRepository,
      gameAdminRepository: gameAdminRepository,
      requireAuth: requireAuth,
    ),
  );
}

class NanoAdminApp extends StatefulWidget {
  const NanoAdminApp({
    super.key,
    required this.config,
    this.initialPrincipal,
    this.initialLocation,
    this.initialLocale = NanoAppLocale.en,
    this.authRepository,
    this.requireAuth = false,
    this.questionBankRepository,
    this.topicQuizRepository,
    this.assetReviewRepository,
    this.platformDashboardRepository,
    this.schoolAdminRepository,
    this.platformUserRepository,
    this.learningContentRepository,
    this.gamificationAdminRepository,
    this.gameAdminRepository,
  });

  final EnvironmentConfig config;
  final SessionPrincipal? initialPrincipal;
  final String? initialLocation;
  final NanoAppLocale initialLocale;
  final AuthRepository? authRepository;
  final bool requireAuth;
  final QuestionBankRepository? questionBankRepository;
  final TopicQuizRepository? topicQuizRepository;
  final AssetReviewRepository? assetReviewRepository;
  final PlatformDashboardRepository? platformDashboardRepository;
  final SchoolAdminRepository? schoolAdminRepository;
  final PlatformUserRepository? platformUserRepository;
  final LearningContentRepository? learningContentRepository;
  final GamificationAdminRepository? gamificationAdminRepository;
  final GameAdminRepository? gameAdminRepository;

  @override
  State<NanoAdminApp> createState() => _NanoAdminAppState();
}

class _NanoAdminAppState extends State<NanoAdminApp> {
  late SessionPrincipal _principal;
  late GoRouter _router;
  late NanoAppLocale _locale;
  late final QuestionBankRepository _questionBankRepository;
  late final TopicQuizRepository _topicQuizRepository;
  late final AssetReviewRepository _assetReviewRepository;
  late final PlatformDashboardRepository _platformDashboardRepository;
  late final SchoolAdminRepository _schoolAdminRepository;
  late final PlatformUserRepository _platformUserRepository;
  late final LearningContentRepository _learningContentRepository;
  late final GamificationAdminRepository _gamificationAdminRepository;
  late final GameAdminRepository _gameAdminRepository;
  AuthBootstrap? _authBootstrap;
  var _restoring = false;

  @override
  void initState() {
    super.initState();
    _principal = widget.initialPrincipal ??
        (widget.requireAuth
            ? SessionPrincipal.schoolAdmin(displayName: '')
            : SessionPrincipal.schoolAdmin());
    _locale = widget.initialLocale;
    _questionBankRepository =
        widget.questionBankRepository ?? FakeQuestionBankRepository();
    _topicQuizRepository =
        widget.topicQuizRepository ?? FakeTopicQuizRepository();
    // The preview shell gets a fake queue so the screen can be worked on
    // without keys; nothing it approves leaves the process.
    _assetReviewRepository =
        widget.assetReviewRepository ?? FakeAssetReviewRepository();
    _platformDashboardRepository =
        widget.platformDashboardRepository ?? FakePlatformDashboardRepository();
    _schoolAdminRepository =
        widget.schoolAdminRepository ?? FakeSchoolAdminRepository();
    _platformUserRepository =
        widget.platformUserRepository ?? FakePlatformUserRepository();
    _learningContentRepository =
        widget.learningContentRepository ?? FakeLearningContentRepository();
    _gamificationAdminRepository =
        widget.gamificationAdminRepository ?? FakeGamificationAdminRepository();
    _gameAdminRepository =
        widget.gameAdminRepository ?? FakeGameAdminRepository();
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
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  GoRouter _createRouter() {
    final copy = NanoCopy(_locale);
    return createAdminRouter(
      config: widget.config,
      principal: _principal,
      copy: copy,
      onPrincipalChanged: (next) {
        setState(() {
          _principal = next;
          _router = _createRouter();
        });
      },
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
      },
      onSignedOut: _signOut,
      questionBankRepository: _questionBankRepository,
      topicQuizRepository: _topicQuizRepository,
      assetReviewRepository: _assetReviewRepository,
      platformDashboardRepository: _platformDashboardRepository,
      schoolAdminRepository: _schoolAdminRepository,
      platformUserRepository: _platformUserRepository,
      learningContentRepository: _learningContentRepository,
      gamificationAdminRepository: _gamificationAdminRepository,
      gameAdminRepository: _gameAdminRepository,
    );
  }

  Future<void> _signOut() async {
    await widget.authRepository?.signOut();
    if (!mounted) return;
    setState(() {
      _authBootstrap = null;
      _principal = SessionPrincipal.schoolAdmin(displayName: '');
      _router = _createRouter();
    });
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoCopy(_locale);
    final theme = _principal.role == AppRole.superadmin
        ? NanoTheme.superadmin(localeTag: _locale.tag)
        : NanoTheme.schoolAdmin(localeTag: _locale.tag);
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
      child: MaterialApp.router(
        key: ValueKey(
          '${_principal.role}-${_principal.isAuthenticated}-${_locale.tag}',
        ),
        title: '${copy.appName} Admin',
        theme: theme,
        locale: Locale(_locale.languageCode),
        supportedLocales: const [Locale('en'), Locale('ur')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: _router,
      ),
    );
  }
}
