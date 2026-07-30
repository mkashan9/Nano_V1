import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  final config = EnvironmentConfig.fromEnvironment();
  runApp(NanoAdminApp(config: config));
}

class NanoAdminApp extends StatelessWidget {
  const NanoAdminApp({super.key, required this.config});

  final EnvironmentConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '${config.appDisplayName} Admin',
      theme: NanoTheme.light(),
      home: Scaffold(
        appBar: AppBar(
          title: Text('${config.appDisplayName} Admin'),
          actions: [
            if (config.environment.showDebugTools)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Chip(label: Text(config.environment.name.toUpperCase())),
              ),
          ],
        ),
        body: const Center(
          child: Text(
            'Admin web foundation (school + superadmin shells later)',
          ),
        ),
      ),
    );
  }
}
