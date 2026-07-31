import 'package:flutter/material.dart';
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
  });

  final EnvironmentConfig config;
  final SessionPrincipal? initialPrincipal;
  final String? initialLocation;

  @override
  State<NanoStudentApp> createState() => _NanoStudentAppState();
}

class _NanoStudentAppState extends State<NanoStudentApp> {
  late SessionPrincipal _principal;
  late GoRouter _router;

  @override
  void initState() {
    super.initState();
    _principal = widget.initialPrincipal ?? SessionPrincipal.junior();
    _router = _createRouter();
  }

  GoRouter _createRouter() {
    return createStudentRouter(
      config: widget.config,
      principal: _principal,
      onPrincipalChanged: _setPrincipal,
      initialLocation: widget.initialLocation,
    );
  }

  void _setPrincipal(SessionPrincipal next) {
    setState(() {
      _principal = next;
      _router = _createRouter();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = _principal.role.usesJuniorPresentation
        ? NanoTheme.junior()
        : NanoTheme.senior();
    return MaterialApp.router(
      key: ValueKey(_principal.role),
      title: widget.config.appDisplayName,
      theme: theme,
      routerConfig: _router,
    );
  }
}
