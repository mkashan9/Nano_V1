import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/app/component_gallery_page.dart';
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
      theme: NanoTheme.junior(),
      home: StudentHomePage(config: config),
    );
  }
}

class StudentHomePage extends StatelessWidget {
  const StudentHomePage({super.key, required this.config});

  final EnvironmentConfig config;

  @override
  Widget build(BuildContext context) {
    return NanoScaffold(
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
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: NanoSpacing.xs),
            Text('Student app · ${config.environment.name}'),
            const SizedBox(height: NanoSpacing.lg),
            const CompanionSlot(size: 72),
            if (config.environment.showDebugTools) ...[
              const SizedBox(height: NanoSpacing.lg),
              if (config.isFeatureEnabled('diagnostics'))
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
              const SizedBox(height: NanoSpacing.sm),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ComponentGalleryPage(),
                    ),
                  );
                },
                child: const Text('Component gallery'),
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
