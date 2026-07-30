"""Wire Nano apps to shared packages and diagnostics shell."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(r"d:\nano")


STUDENT_MAIN = r'''import 'package:flutter/foundation.dart';
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
'''

DIAGNOSTICS = r'''import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nano_domain/nano_domain.dart';

class DiagnosticsPage extends StatelessWidget {
  const DiagnosticsPage({super.key, required this.config});

  final EnvironmentConfig config;

  @override
  Widget build(BuildContext context) {
    assert(
      !config.environment.isProduction,
      'Diagnostics must not ship in production builds.',
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('App'),
            subtitle: Text(config.appDisplayName),
          ),
          ListTile(
            title: const Text('Environment'),
            subtitle: Text(config.environment.name),
          ),
          ListTile(
            title: const Text('Supabase URL set'),
            subtitle: Text(config.supabaseUrl.isEmpty ? 'no' : 'yes'),
          ),
          ListTile(
            title: const Text('Anon key set'),
            subtitle: Text(config.supabaseAnonKey.isEmpty ? 'no' : 'yes'),
          ),
          ListTile(
            title: const Text('Build mode'),
            subtitle: Text(kReleaseMode ? 'release' : 'debug/profile'),
          ),
          ListTile(
            title: const Text('Feature flags'),
            subtitle: Text(config.featureFlags.toString()),
          ),
        ],
      ),
    );
  }
}
'''

BADGE = r'''import 'package:flutter/material.dart';
import 'package:nano_domain/nano_domain.dart';

class EnvironmentBadge extends StatelessWidget {
  const EnvironmentBadge({super.key, required this.environment});

  final NanoEnvironment environment;

  @override
  Widget build(BuildContext context) {
    final label = switch (environment) {
      NanoEnvironment.development => 'DEV',
      NanoEnvironment.staging => 'STG',
      NanoEnvironment.production => 'PROD',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Chip(
        label: Text(label),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
'''

TEACHER_MAIN = r'''import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  final config = EnvironmentConfig.fromEnvironment();
  runApp(NanoTeacherApp(config: config));
}

class NanoTeacherApp extends StatelessWidget {
  const NanoTeacherApp({super.key, required this.config});

  final EnvironmentConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '${config.appDisplayName} Teacher',
      theme: NanoTheme.light(),
      home: Scaffold(
        appBar: AppBar(
          title: Text('${config.appDisplayName} Teacher'),
          actions: [
            if (config.environment.showDebugTools)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Chip(label: Text(config.environment.name.toUpperCase())),
              ),
          ],
        ),
        body: const Center(child: Text('Teacher app foundation')),
      ),
    );
  }
}
'''

ADMIN_MAIN = r'''import 'package:flutter/material.dart';
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
          child: Text('Admin web foundation (school + superadmin shells later)'),
        ),
      ),
    );
  }
}
'''


def patch_app_pubspec(app: str, extra_deps: str) -> None:
    path = ROOT / "apps" / app / "pubspec.yaml"
    text = path.read_text(encoding="utf-8")
    if "nano_domain" in text:
        return
    needle = "dependencies:\n  flutter:\n    sdk: flutter"
    replacement = f"""dependencies:
  flutter:
    sdk: flutter
{extra_deps}"""
    if needle not in text:
        raise SystemExit(f"Could not patch {path}")
    path.write_text(text.replace(needle, replacement, 1), encoding="utf-8")


def main() -> None:
    # Fix nano_domain pubspec for pure dart test
    (ROOT / "packages/nano_domain/pubspec.yaml").write_text(
        """name: nano_domain
description: Nano shared domain models and environment contracts
publish_to: none
version: 0.1.0

environment:
  sdk: ^3.12.2

dependencies: {}

dev_dependencies:
  lints: ^6.0.0
  test: ^1.25.0
""",
        encoding="utf-8",
    )
    (ROOT / "packages/nano_domain/analysis_options.yaml").write_text(
        "include: package:lints/recommended.yaml\n",
        encoding="utf-8",
    )

    for name in ["nano_data", "nano_auth", "nano_media", "nano_games"]:
        (ROOT / f"packages/{name}/pubspec.yaml").write_text(
            f"""name: {name}
description: Nano {name} package
publish_to: none
version: 0.1.0

environment:
  sdk: ^3.12.2

dependencies:
  nano_domain:
    path: ../nano_domain

dev_dependencies:
  lints: ^6.0.0
  test: ^1.25.0
""",
            encoding="utf-8",
        )
        (ROOT / f"packages/{name}/analysis_options.yaml").write_text(
            "include: package:lints/recommended.yaml\n",
            encoding="utf-8",
        )

    # design system + testing keep flutter
    (ROOT / "packages/nano_design_system/pubspec.yaml").write_text(
        """name: nano_design_system
description: Nano design tokens and shared UI primitives
publish_to: none
version: 0.1.0

environment:
  sdk: ^3.12.2

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_lints: ^6.0.0
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: true
""",
        encoding="utf-8",
    )
    (ROOT / "packages/nano_testing/pubspec.yaml").write_text(
        """name: nano_testing
description: Nano shared test fixtures and helpers
publish_to: none
version: 0.1.0

environment:
  sdk: ^3.12.2

dependencies:
  flutter:
    sdk: flutter
  nano_domain:
    path: ../nano_domain

dev_dependencies:
  flutter_lints: ^6.0.0
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: true
""",
        encoding="utf-8",
    )

    shared = """  nano_domain:
    path: ../../packages/nano_domain
  nano_design_system:
    path: ../../packages/nano_design_system
"""
    patch_app_pubspec("student_app", shared)
    patch_app_pubspec("teacher_app", shared)
    patch_app_pubspec("admin_web", shared)

    # Update app titles in pubspec description
    for app, desc in [
        ("student_app", "Nano student application"),
        ("teacher_app", "Nano teacher application"),
        ("admin_web", "Nano school management and superadmin web"),
    ]:
        p = ROOT / "apps" / app / "pubspec.yaml"
        t = p.read_text(encoding="utf-8")
        t = t.replace('description: "A new Flutter project."', f'description: "{desc}"')
        p.write_text(t, encoding="utf-8")

    app = ROOT / "apps/student_app"
    (app / "lib/main.dart").write_text(STUDENT_MAIN, encoding="utf-8")
    (app / "lib/app").mkdir(exist_ok=True)
    (app / "lib/app/diagnostics_page.dart").write_text(DIAGNOSTICS, encoding="utf-8")
    (app / "lib/app/environment_badge.dart").write_text(BADGE, encoding="utf-8")
    (app / "test/widget_test.dart").write_text(
        """import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/main.dart';

void main() {
  testWidgets('student home shows Nano', (tester) async {
    const config = EnvironmentConfig(
      environment: NanoEnvironment.development,
      supabaseUrl: '',
      supabaseAnonKey: '',
      featureFlags: {'diagnostics': true},
    );
    await tester.pumpWidget(const NanoStudentApp(config: config));
    expect(find.textContaining('Nano'), findsWidgets);
    expect(find.text('Open diagnostics'), findsOneWidget);
  });
}
""",
        encoding="utf-8",
    )

    (ROOT / "apps/teacher_app/lib/main.dart").write_text(TEACHER_MAIN, encoding="utf-8")
    (ROOT / "apps/teacher_app/test/widget_test.dart").write_text(
        """import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:teacher_app/main.dart';

void main() {
  testWidgets('teacher foundation loads', (tester) async {
    const config = EnvironmentConfig(
      environment: NanoEnvironment.development,
      supabaseUrl: '',
      supabaseAnonKey: '',
      featureFlags: {},
    );
    await tester.pumpWidget(const NanoTeacherApp(config: config));
    expect(find.textContaining('Teacher'), findsWidgets);
  });
}
""",
        encoding="utf-8",
    )

    (ROOT / "apps/admin_web/lib/main.dart").write_text(ADMIN_MAIN, encoding="utf-8")
    (ROOT / "apps/admin_web/test/widget_test.dart").write_text(
        """import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:admin_web/main.dart';

void main() {
  testWidgets('admin foundation loads', (tester) async {
    const config = EnvironmentConfig(
      environment: NanoEnvironment.development,
      supabaseUrl: '',
      supabaseAnonKey: '',
      featureFlags: {},
    );
    await tester.pumpWidget(const NanoAdminApp(config: config));
    expect(find.textContaining('Admin'), findsWidgets);
  });
}
""",
        encoding="utf-8",
    )

    # assets placeholders
    for d in ["shared", "junior", "senior", "companion", "licenses", "provenance"]:
        (ROOT / "assets" / d).mkdir(parents=True, exist_ok=True)
        (ROOT / "assets" / d / ".gitkeep").write_text("", encoding="utf-8")

    print("apps wired")


if __name__ == "__main__":
    main()
