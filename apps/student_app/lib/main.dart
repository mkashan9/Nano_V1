import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_auth/nano_auth.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/app/student_router.dart';
import 'package:supabase/supabase.dart';

void main() {
  final config = EnvironmentConfig.fromEnvironment();
  AuthRepository? authRepository;
  var requireAuth = false;
  if (config.supabaseUrl.isNotEmpty && config.supabaseAnonKey.isNotEmpty) {
    authRepository = SupabaseAuthRepository(
      SupabaseClient(config.supabaseUrl, config.supabaseAnonKey),
      allowedAccountKinds: const {
        'school_student',
        'independent_student',
      },
      appLabel: 'students',
    );
    requireAuth = true;
  }
  runApp(
    NanoStudentApp(
      config: config,
      authRepository: authRepository,
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
    this.requireAuth = false,
  });

  final EnvironmentConfig config;
  final SessionPrincipal? initialPrincipal;
  final String? initialLocation;
  final NanoAppLocale initialLocale;
  final AccessibilityPreferences initialAccessibility;
  final AuthRepository? authRepository;
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
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
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
      },
      onSignedOut: _signOut,
    );
  }

  Future<void> _signOut() async {
    await widget.authRepository?.signOut();
    if (!mounted) return;
    setState(() {
      _authBootstrap = null;
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
  }

  void _setA11y(AccessibilityPreferences next) {
    setState(() {
      _a11y = next;
      _feedback.updatePreferences(next);
    });
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
