import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_auth/nano_auth.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:teacher_app/app/teacher_router.dart';

void main() {
  final config = EnvironmentConfig.fromEnvironment();
  AuthRepository? authRepository;
  TeacherDashboardRepository? teacherDashboardRepository;
  TeacherClassesRepository? teacherClassesRepository;
  TeacherAttendanceRepository? teacherAttendanceRepository;
  var requireAuth = false;
  if (config.supabaseUrl.isNotEmpty && config.supabaseAnonKey.isNotEmpty) {
    final client =
        NanoAuthClient.create(config.supabaseUrl, config.supabaseAnonKey);
    authRepository = SupabaseAuthRepository(
      client,
      allowedAccountKinds: const {'teacher'},
      appLabel: 'teachers',
    );
    teacherDashboardRepository = SupabaseTeacherDashboardRepository(client);
    teacherClassesRepository = SupabaseTeacherClassesRepository(client);
    teacherAttendanceRepository = SupabaseTeacherAttendanceRepository(client);
    requireAuth = true;
  }
  runApp(
    NanoTeacherApp(
      config: config,
      authRepository: authRepository,
      teacherDashboardRepository: teacherDashboardRepository,
      teacherClassesRepository: teacherClassesRepository,
      teacherAttendanceRepository: teacherAttendanceRepository,
      requireAuth: requireAuth,
    ),
  );
}

class NanoTeacherApp extends StatefulWidget {
  const NanoTeacherApp({
    super.key,
    required this.config,
    this.principal,
    this.initialLocation,
    this.initialLocale = NanoAppLocale.en,
    this.authRepository,
    this.teacherDashboardRepository,
    this.teacherClassesRepository,
    this.teacherAttendanceRepository,
    this.requireAuth = false,
  });

  final EnvironmentConfig config;
  final SessionPrincipal? principal;
  final String? initialLocation;
  final NanoAppLocale initialLocale;
  final AuthRepository? authRepository;
  final TeacherDashboardRepository? teacherDashboardRepository;
  final TeacherClassesRepository? teacherClassesRepository;
  final TeacherAttendanceRepository? teacherAttendanceRepository;
  final bool requireAuth;

  @override
  State<NanoTeacherApp> createState() => _NanoTeacherAppState();
}

class _NanoTeacherAppState extends State<NanoTeacherApp> {
  late NanoAppLocale _locale;
  late SessionPrincipal _principal;
  late GoRouter _router;
  late TeacherDashboardRepository _teacherDashboardRepository;
  late TeacherClassesRepository _teacherClassesRepository;
  late TeacherAttendanceRepository _teacherAttendanceRepository;
  AuthBootstrap? _authBootstrap;
  var _restoring = false;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
    _principal = widget.principal ??
        (widget.requireAuth
            ? SessionPrincipal.teacher(displayName: '')
            : SessionPrincipal.teacher());
    _teacherDashboardRepository =
        widget.teacherDashboardRepository ?? FakeTeacherDashboardRepository();
    _teacherClassesRepository =
        widget.teacherClassesRepository ?? FakeTeacherClassesRepository();
    _teacherAttendanceRepository =
        widget.teacherAttendanceRepository ?? FakeTeacherAttendanceRepository();
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
    return createTeacherRouter(
      config: widget.config,
      principal: _principal,
      copy: copy,
      initialLocation: widget.initialLocation,
      authRepository: widget.authRepository,
      requireAuth: widget.requireAuth,
      authBootstrap: _authBootstrap,
      teacherDashboardRepository: _teacherDashboardRepository,
      teacherClassesRepository: _teacherClassesRepository,
      teacherAttendanceRepository: _teacherAttendanceRepository,
      onAuthBootstrap: (bootstrap) {
        setState(() {
          _authBootstrap = bootstrap;
          _principal = bootstrap.principal;
          _router = _createRouter();
        });
      },
      onPrincipalChanged: (next) {
        setState(() {
          _principal = next;
          _router = _createRouter();
        });
      },
      onSignedOut: _signOut,
    );
  }

  Future<void> _signOut() async {
    await widget.authRepository?.signOut();
    if (!mounted) return;
    setState(() {
      _authBootstrap = null;
      _principal = SessionPrincipal.teacher(displayName: '');
      _router = _createRouter();
    });
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoCopy(_locale);
    if (_restoring) {
      return MaterialApp(
        theme: NanoTheme.teacher(localeTag: _locale.tag),
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
          '${_principal.isAuthenticated}-${_principal.userId}-$_locale',
        ),
        title: '${copy.appName} Teacher',
        theme: NanoTheme.teacher(localeTag: _locale.tag),
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
