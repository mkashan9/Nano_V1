import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/app/component_gallery_page.dart';
import 'package:student_app/app/diagnostics_page.dart';
import 'package:student_app/app/environment_badge.dart';
import 'package:student_app/features/home/presentation/junior_home_foundation.dart';
import 'package:student_app/features/home/presentation/responsive_preview_page.dart';
import 'package:student_app/features/home/presentation/senior_home_foundation.dart';

void main() {
  final config = EnvironmentConfig.fromEnvironment();
  runApp(NanoStudentApp(config: config));
}

class NanoStudentApp extends StatefulWidget {
  const NanoStudentApp({super.key, required this.config});

  final EnvironmentConfig config;

  @override
  State<NanoStudentApp> createState() => _NanoStudentAppState();
}

class _NanoStudentAppState extends State<NanoStudentApp> {
  bool senior = false;

  @override
  Widget build(BuildContext context) {
    final theme = senior ? NanoTheme.senior() : NanoTheme.junior();
    return MaterialApp(
      title: widget.config.appDisplayName,
      theme: theme,
      home: StudentHomePage(
        config: widget.config,
        senior: senior,
        onExperienceChanged: (value) => setState(() => senior = value),
      ),
    );
  }
}

class StudentHomePage extends StatelessWidget {
  const StudentHomePage({
    super.key,
    required this.config,
    required this.senior,
    required this.onExperienceChanged,
  });

  final EnvironmentConfig config;
  final bool senior;
  final ValueChanged<bool> onExperienceChanged;

  @override
  Widget build(BuildContext context) {
    return NanoScaffold(
      padBody: true,
      appBar: AppBar(
        title: Text(config.appDisplayName),
        actions: [
          if (config.environment.showDebugTools) ...[
            Row(
              children: [
                Text(senior ? 'Senior' : 'Junior'),
                Switch(value: senior, onChanged: onExperienceChanged),
              ],
            ),
            EnvironmentBadge(environment: config.environment),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: senior
                ? const SeniorHomeFoundation()
                : const JuniorHomeFoundation(),
          ),
          if (config.environment.showDebugTools)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: NanoSpacing.md),
                child: Wrap(
                  spacing: NanoSpacing.sm,
                  alignment: WrapAlignment.center,
                  children: [
                    if (config.isFeatureEnabled('diagnostics'))
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  DiagnosticsPage(config: config),
                            ),
                          );
                        },
                        child: const Text('Diagnostics'),
                      ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ComponentGalleryPage(),
                          ),
                        );
                      },
                      child: const Text('Gallery'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ResponsivePreviewPage(),
                          ),
                        );
                      },
                      child: const Text('Responsive preview'),
                    ),
                  ],
                ),
              ),
            ),
          if (kReleaseMode && config.environment.isProduction)
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}
