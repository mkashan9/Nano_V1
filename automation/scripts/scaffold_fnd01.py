"""Scaffold Nano FND-01 Melos workspace, apps, packages, env config (no Docker)."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(r"d:\nano")

ANALYSIS = """include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_const_constructors: true
    avoid_print: true
"""

PACKAGE_NAMES = [
    "nano_design_system",
    "nano_domain",
    "nano_data",
    "nano_auth",
    "nano_media",
    "nano_games",
    "nano_testing",
]


def write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content.lstrip("\n") if content.startswith("\n") else content, encoding="utf-8")
    if not content.endswith("\n"):
        path.write_text(path.read_text(encoding="utf-8") + "\n", encoding="utf-8")


def dart_package(name: str, description: str, deps: list[str] | None = None, flutter: bool = False) -> None:
    pkg = ROOT / "packages" / name
    dep_lines = []
    if flutter:
        dep_lines.append("  flutter:\n    sdk: flutter")
    for d in deps or []:
        dep_lines.append(f"  {d}:\n    path: ../{d}")
    deps_block = "\n".join(dep_lines) if dep_lines else "  # none"
    pub = f"""name: {name}
description: {description}
publish_to: none
version: 0.1.0

environment:
  sdk: ^3.12.2

dependencies:
{deps_block}

dev_dependencies:
  flutter_lints: ^6.0.0
{"  flutter_test:\n    sdk: flutter" if flutter else "  test: ^1.25.0"}
"""
    if flutter:
        pub += "\nflutter:\n  uses-material-design: true\n"
    write(pkg / "pubspec.yaml", pub)
    write(pkg / "analysis_options.yaml", ANALYSIS)
    write(pkg / f"lib/{name}.dart", f"library {name};\n\nexport 'src/{name}.dart';\n")
    write(pkg / f"lib/src/{name}.dart", f"/// {description}\nclass {''.join(p.capitalize() for p in name.split('_'))}Marker {{\n  const {''.join(p.capitalize() for p in name.split('_'))}Marker();\n}}\n")


def main() -> None:
    # Root workspace
    write(
        ROOT / "pubspec.yaml",
        """name: nano_workspace
description: Nano monorepo workspace root
publish_to: none

environment:
  sdk: ^3.12.2

dev_dependencies:
  flutter_lints: ^6.0.0
  melos: ^7.0.0
""",
    )
    write(
        ROOT / "melos.yaml",
        """name: nano
repository: https://github.com/mkashan9/Nano_V1

packages:
  - apps/**
  - packages/**

command:
  bootstrap:
    environment:
      sdk: ^3.12.2

scripts:
  analyze:
    run: melos exec -- flutter analyze
    description: Analyze all packages and apps
  test:
    run: melos exec --dir-exists=test -- flutter test
    description: Run tests in packages that have a test directory
  format:
    run: melos exec -- dart format .
    description: Format all Dart code
  verify:
    run: melos run format && melos run analyze && melos run test
    description: Format, analyze, and test the workspace
""",
    )
    write(ROOT / "analysis_options.yaml", ANALYSIS)

    # Packages
    dart_package("nano_domain", "Nano shared domain models and environment contracts", flutter=False)
    dart_package("nano_design_system", "Nano design tokens and shared UI primitives", flutter=True)
    dart_package("nano_data", "Nano data layer repositories and DTO adapters", ["nano_domain"], flutter=False)
    dart_package("nano_auth", "Nano authentication contracts and session models", ["nano_domain"], flutter=False)
    dart_package("nano_media", "Nano media delivery contracts", ["nano_domain"], flutter=False)
    dart_package("nano_games", "Nano game host contracts", ["nano_domain"], flutter=False)
    dart_package("nano_testing", "Nano shared test fixtures and helpers", ["nano_domain"], flutter=True)

    # Domain: EnvironmentConfig, FeatureFlag, BuildInfo, ServiceEndpoint
    write(
        ROOT / "packages/nano_domain/lib/src/environment/nano_environment.dart",
        """enum NanoEnvironment {
  development,
  staging,
  production;

  static NanoEnvironment fromName(String? value) {
    switch ((value ?? 'development').toLowerCase()) {
      case 'staging':
        return NanoEnvironment.staging;
      case 'production':
      case 'prod':
        return NanoEnvironment.production;
      default:
        return NanoEnvironment.development;
    }
  }

  bool get isProduction => this == NanoEnvironment.production;
  bool get showDebugTools => this != NanoEnvironment.production;
}
""",
    )
    write(
        ROOT / "packages/nano_domain/lib/src/environment/environment_config.dart",
        """import 'nano_environment.dart';
import 'service_endpoint.dart';

class EnvironmentConfig {
  const EnvironmentConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.featureFlags,
    this.appDisplayName = 'Nano',
  });

  final NanoEnvironment environment;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final Map<String, bool> featureFlags;
  final String appDisplayName;

  ServiceEndpoint get supabaseEndpoint => ServiceEndpoint(
        name: 'supabase',
        baseUrl: supabaseUrl,
      );

  bool isFeatureEnabled(String flag) => featureFlags[flag] ?? false;

  factory EnvironmentConfig.fromEnvironment({
    String environmentName = const String.fromEnvironment(
      'NANO_ENV',
      defaultValue: 'development',
    ),
    String supabaseUrl = const String.fromEnvironment('SUPABASE_URL'),
    String supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY'),
  }) {
    final env = NanoEnvironment.fromName(environmentName);
    if (env.isProduction) {
      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        throw StateError(
          'Production builds require SUPABASE_URL and SUPABASE_ANON_KEY.',
        );
      }
      if (supabaseAnonKey.contains('test') || supabaseUrl.contains('localhost')) {
        throw StateError(
          'Production builds must not use test credentials or localhost endpoints.',
        );
      }
    }
    return EnvironmentConfig(
      environment: env,
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      featureFlags: const {
        'diagnostics': true,
        'games_kill_switch': false,
      },
    );
  }
}
""",
    )
    write(
        ROOT / "packages/nano_domain/lib/src/environment/service_endpoint.dart",
        """class ServiceEndpoint {
  const ServiceEndpoint({required this.name, required this.baseUrl});

  final String name;
  final String baseUrl;
}
""",
    )
    write(
        ROOT / "packages/nano_domain/lib/src/environment/build_info.dart",
        """class BuildInfo {
  const BuildInfo({
    required this.appName,
    required this.version,
    required this.buildNumber,
    required this.packageName,
  });

  final String appName;
  final String version;
  final String buildNumber;
  final String packageName;
}
""",
    )
    write(
        ROOT / "packages/nano_domain/lib/src/environment/feature_flag.dart",
        """class FeatureFlag {
  const FeatureFlag({
    required this.key,
    required this.enabled,
    this.description = '',
  });

  final String key;
  final bool enabled;
  final String description;
}
""",
    )
    write(
        ROOT / "packages/nano_domain/lib/src/nano_domain.dart",
        """export 'environment/build_info.dart';
export 'environment/environment_config.dart';
export 'environment/feature_flag.dart';
export 'environment/nano_environment.dart';
export 'environment/service_endpoint.dart';
""",
    )
    write(
        ROOT / "packages/nano_domain/lib/nano_domain.dart",
        """library nano_domain;

export 'src/nano_domain.dart';
""",
    )
    write(
        ROOT / "packages/nano_domain/test/environment_config_test.dart",
        """import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('NanoEnvironment', () {
    test('parses known names', () {
      expect(NanoEnvironment.fromName('staging'), NanoEnvironment.staging);
      expect(NanoEnvironment.fromName('production'), NanoEnvironment.production);
      expect(NanoEnvironment.fromName(null), NanoEnvironment.development);
    });

    test('debug tools hidden in production', () {
      expect(NanoEnvironment.production.showDebugTools, isFalse);
      expect(NanoEnvironment.development.showDebugTools, isTrue);
    });
  });

  group('EnvironmentConfig', () {
    test('exposes supabase endpoint', () {
      const config = EnvironmentConfig(
        environment: NanoEnvironment.development,
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'anon',
        featureFlags: {'diagnostics': true},
      );
      expect(config.supabaseEndpoint.baseUrl, 'https://example.supabase.co');
      expect(config.isFeatureEnabled('diagnostics'), isTrue);
      expect(config.appDisplayName, 'Nano');
    });
  });
}
""",
    )

    # Design system stub
    write(
        ROOT / "packages/nano_design_system/lib/src/nano_design_system.dart",
        """import 'package:flutter/material.dart';

/// Placeholder tokens — FND-02 owns the full design system.
class NanoColors {
  static const Color brandPrimary = Color(0xFF0B6E4F);
  static const Color brandSecondary = Color(0xFF08A045);
  static const Color surface = Color(0xFFF7FBF8);
}

class NanoTheme {
  static ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: NanoColors.brandPrimary,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }
}
""",
    )
    write(
        ROOT / "packages/nano_design_system/lib/nano_design_system.dart",
        """library nano_design_system;

export 'src/nano_design_system.dart';
""",
    )
    write(
        ROOT / "packages/nano_design_system/test/nano_theme_test.dart",
        """import 'package:flutter_test/flutter_test.dart';
import 'package:nano_design_system/nano_design_system.dart';

void main() {
  test('light theme builds', () {
    final theme = NanoTheme.light();
    expect(theme.colorScheme.primary, isNotNull);
  });
}
""",
    )

    # Other package barrels
    for name in ["nano_data", "nano_auth", "nano_media", "nano_games", "nano_testing"]:
        class_name = "".join(p.capitalize() for p in name.split("_"))
        write(
            ROOT / f"packages/{name}/lib/src/{name}.dart",
            f"/// Package placeholder for {name}.\nclass {class_name} {{\n  const {class_name}();\n}}\n",
        )
        write(
            ROOT / f"packages/{name}/lib/{name}.dart",
            f"library {name};\n\nexport 'src/{name}.dart';\n",
        )

    write(
        ROOT / "packages/nano_testing/test/smoke_test.dart",
        """import 'package:flutter_test/flutter_test.dart';
import 'package:nano_testing/nano_testing.dart';

void main() {
  test('testing package loads', () {
    expect(const NanoTesting(), isNotNull);
  });
}
""",
    )

    # Env examples
    write(
        ROOT / "docs/setup/ENVIRONMENTS.md",
        """# Nano Environments (remote-first, no Docker)

## Environments

| Name | Purpose | Supabase |
|------|---------|----------|
| development | Daily integration, disposable data | Remote project `nano_v1` (`jjsnvmxasbtimesjsyoy`) |
| staging | Release candidates (future) | Separate project TBD |
| production | Live users (future) | Separate project TBD |

## No Docker

Owner policy: **do not use Docker** and do not run `supabase start`.

Alternatives:

1. Author SQL migrations in `supabase/migrations/`.
2. Apply to the remote **development** project via Supabase MCP `apply_migration` or CLI after `supabase link` (owner-approved).
3. Run SQL / RLS checks with MCP `execute_sql` against development.
4. Deploy Edge Functions only to development with owner approval (`supabase functions deploy` is still gated).
5. Keep secrets in `supabase/functions/.env.local` (gitignored) and remote function secrets.

## Flutter compile-time values

```bash
flutter run \\
  --dart-define=NANO_ENV=development \\
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \\
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Never place service-role keys in Flutter.
""",
    )
    write(
        ROOT / ".env.example",
        """# Names only — copy values locally; never commit real secrets.
NANO_ENV=development
SUPABASE_URL=
SUPABASE_ANON_KEY=
""",
    )

    write(
        ROOT / "supabase/seed.sql",
        """-- Disposable development seed (no real private data).
-- Applied only to development environments.
-- SEC modules will expand schools/users fixtures.
""",
    )
    write(
        ROOT / "docs/setup/SUPABASE_REMOTE_WORKFLOW.md",
        """# Supabase remote workflow (no Docker)

## Link (once)

```bash
supabase link --project-ref jjsnvmxasbtimesjsyoy
```

## Migrations

1. Add files under `supabase/migrations/`.
2. Prefer MCP `apply_migration` for development.
3. Never apply unreviewed migrations to staging/production.

## Forbidden without owner approval

- `supabase db push` to non-dev
- `supabase functions deploy` to non-dev
- `supabase secrets set` for production
""",
    )

    # Scripts
    write(
        ROOT / "scripts/verify.ps1",
        """# One-command workspace verify (Windows)
$ErrorActionPreference = "Stop"
dart pub global activate melos
melos bootstrap
melos run verify
""",
    )
    write(
        ROOT / "scripts/verify.sh",
        """#!/usr/bin/env bash
set -euo pipefail
dart pub global activate melos
melos bootstrap
melos run verify
""",
    )

    # README
    write(
        ROOT / "README.md",
        """# Nano

Education platform monorepo.

## Apps

- `apps/student_app` — students (Junior / Senior)
- `apps/teacher_app` — teachers
- `apps/admin_web` — school management + superadmin (role shells later)

## Packages

- `nano_design_system`, `nano_domain`, `nano_data`, `nano_auth`, `nano_media`, `nano_games`, `nano_testing`

## Setup

1. Install Flutter stable (3.44+).
2. `dart pub global activate melos`
3. `melos bootstrap`
4. Copy `.env.example` values into your shell / `--dart-define` (never commit secrets).
5. Supabase is **remote-first** — no Docker. See `docs/setup/ENVIRONMENTS.md`.

## Verify

```bash
melos run verify
```

Or `scripts/verify.ps1` on Windows.
""",
    )

    print("FND-01 package scaffold written")


if __name__ == "__main__":
    main()
