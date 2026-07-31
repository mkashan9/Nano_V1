import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:teacher_app/app/teacher_router.dart';

void main() {
  final config = EnvironmentConfig.fromEnvironment();
  runApp(NanoTeacherApp(config: config));
}

class NanoTeacherApp extends StatefulWidget {
  const NanoTeacherApp({
    super.key,
    required this.config,
    this.principal,
    this.initialLocation,
    this.initialLocale = NanoAppLocale.en,
  });

  final EnvironmentConfig config;
  final SessionPrincipal? principal;
  final String? initialLocation;
  final NanoAppLocale initialLocale;

  @override
  State<NanoTeacherApp> createState() => _NanoTeacherAppState();
}

class _NanoTeacherAppState extends State<NanoTeacherApp> {
  late NanoAppLocale _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.principal ?? SessionPrincipal.teacher();
    final copy = NanoCopy(_locale);
    final router = createTeacherRouter(
      config: widget.config,
      principal: session,
      initialLocation: widget.initialLocation,
      copy: copy,
    );
    return NanoLocaleScope(
      locale: _locale,
      copy: copy,
      child: MaterialApp.router(
        title: '${copy.appName} Teacher',
        theme: NanoTheme.teacher(localeTag: _locale.tag),
        locale: Locale(_locale.languageCode),
        supportedLocales: const [Locale('en'), Locale('ur')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    );
  }
}
