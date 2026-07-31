import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:admin_web/app/admin_router.dart';

void main() {
  final config = EnvironmentConfig.fromEnvironment();
  runApp(NanoAdminApp(config: config));
}

class NanoAdminApp extends StatefulWidget {
  const NanoAdminApp({
    super.key,
    required this.config,
    this.initialPrincipal,
    this.initialLocation,
  });

  final EnvironmentConfig config;
  final SessionPrincipal? initialPrincipal;
  final String? initialLocation;

  @override
  State<NanoAdminApp> createState() => _NanoAdminAppState();
}

class _NanoAdminAppState extends State<NanoAdminApp> {
  late SessionPrincipal _principal;
  late GoRouter _router;

  @override
  void initState() {
    super.initState();
    _principal = widget.initialPrincipal ?? SessionPrincipal.schoolAdmin();
    _router = _createRouter();
  }

  GoRouter _createRouter() {
    return createAdminRouter(
      config: widget.config,
      principal: _principal,
      onPrincipalChanged: (next) {
        setState(() {
          _principal = next;
          _router = _createRouter();
        });
      },
      initialLocation: widget.initialLocation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _principal.role == AppRole.superadmin
        ? NanoTheme.superadmin()
        : NanoTheme.schoolAdmin();
    return MaterialApp.router(
      key: ValueKey(_principal.role),
      title: '${widget.config.appDisplayName} Admin',
      theme: theme,
      routerConfig: _router,
    );
  }
}
