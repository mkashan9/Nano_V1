import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/app/diagnostics_page.dart';
import 'package:student_app/app/environment_badge.dart';

void main() {
  final config = EnvironmentConfig.fromEnvironment();
  runApp(NanoStudentApp(config: config));
}

class NanoStudentApp extends StatelessWidget {
  const NanoStudentApp({super.key, required this.config});

  final EnvironmentConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: config.appDisplayName,
      theme: NanoTheme.light(),
      home: StudentHomePage(config: config),
    );
  }
}

class StudentHomePage extends StatelessWidget {
  const StudentHomePage({super.key, required this.config});

  final EnvironmentConfig config;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(config.appDisplayName),
        actions: [
          if (config.environment.showDebugTools)
            EnvironmentBadge(environment: config.environment),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to ${config.appDisplayName}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Student app foundation (${config.environment.name})'),
            if (config.environment.showDebugTools &&
                config.isFeatureEnabled('diagnostics')) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DiagnosticsPage(config: config),
                    ),
                  );
                },
                child: const Text('Open diagnostics'),
              ),
            ],
            if (kReleaseMode && config.environment.isProduction)
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
