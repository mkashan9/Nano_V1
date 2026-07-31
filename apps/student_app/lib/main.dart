import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/app/student_router.dart';

void main() {
  final config = EnvironmentConfig.fromEnvironment();
  runApp(NanoStudentApp(config: config));
}

class NanoStudentApp extends StatefulWidget {
  const NanoStudentApp({
    super.key,
    required this.config,
    this.initialPrincipal,
    this.initialLocation,
    this.initialLocale = NanoAppLocale.en,
    this.initialAccessibility = AccessibilityPreferences.defaults,
  });

  final EnvironmentConfig config;
  final SessionPrincipal? initialPrincipal;
  final String? initialLocation;
  final NanoAppLocale initialLocale;
  final AccessibilityPreferences initialAccessibility;

  @override
  State<NanoStudentApp> createState() => _NanoStudentAppState();
}

class _NanoStudentAppState extends State<NanoStudentApp> {
  late SessionPrincipal _principal;
  late GoRouter _router;
  late NanoAppLocale _locale;
  late AccessibilityPreferences _a11y;
  late final NanoFeedback _feedback;

  @override
  void initState() {
    super.initState();
    _principal = widget.initialPrincipal ?? SessionPrincipal.junior();
    _locale = widget.initialLocale;
    _a11y = widget.initialAccessibility;
    _feedback = NanoFeedback(preferences: _a11y);
    _router = _createRouter();
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
    );
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
    return NanoLocaleScope(
      locale: _locale,
      copy: copy,
      child: NanoAccessibilityScope(
        preferences: _a11y,
        feedback: _feedback,
        child: MaterialApp.router(
          key: ValueKey(
            '${_principal.role}-${_locale.tag}-${_a11y.reducedMotion}-'
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
