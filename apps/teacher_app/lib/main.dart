import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:teacher_app/app/teacher_router.dart';

void main() {
  final config = EnvironmentConfig.fromEnvironment();
  runApp(NanoTeacherApp(config: config));
}

class NanoTeacherApp extends StatelessWidget {
  const NanoTeacherApp({
    super.key,
    required this.config,
    this.principal,
    this.initialLocation,
  });

  final EnvironmentConfig config;
  final SessionPrincipal? principal;
  final String? initialLocation;

  @override
  Widget build(BuildContext context) {
    final session = principal ?? SessionPrincipal.teacher();
    final router = createTeacherRouter(
      config: config,
      principal: session,
      initialLocation: initialLocation,
    );
    return MaterialApp.router(
      title: '${config.appDisplayName} Teacher',
      theme: NanoTheme.teacher(),
      routerConfig: router,
    );
  }
}
