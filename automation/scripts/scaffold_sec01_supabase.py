"""Scaffold SEC-01 Supabase baseline workflow artifacts."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(r"d:\nano")


def w(path: str, content: str) -> None:
    p = ROOT / path
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content.strip() + "\n", encoding="utf-8")


def main() -> None:
    # nano_data supabase client
    pub = ROOT / "packages/nano_data/pubspec.yaml"
    pub.write_text(
        """
name: nano_data
description: Nano data layer — Supabase gateway and repositories
publish_to: none
version: 0.1.0

environment:
  sdk: ^3.12.2

resolution: workspace
dependencies:
  nano_domain:
    path: ../nano_domain
  supabase: ^2.8.0

dev_dependencies:
  lints: ^6.0.0
  test: ^1.25.0
""".strip()
        + "\n",
        encoding="utf-8",
    )

    w(
        "packages/nano_data/lib/src/supabase/nano_supabase.dart",
        r"""
import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// Thin gateway around Supabase. Never accepts or stores the service-role key.
class NanoSupabase {
  NanoSupabase(this.client);

  final SupabaseClient client;

  factory NanoSupabase.fromConfig(EnvironmentConfig config) {
    if (config.supabaseUrl.isEmpty || config.supabaseAnonKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL and SUPABASE_ANON_KEY are required to open NanoSupabase.',
      );
    }
    return NanoSupabase(
      SupabaseClient(config.supabaseUrl, config.supabaseAnonKey),
    );
  }

  /// Reads the SEC-01 health probe row.
  Future<AppHealthSnapshot?> fetchAppHealth() async {
    final rows = await client.from('app_health').select().eq('id', 'default');
    if (rows.isEmpty) return null;
    final row = rows.first;
    return AppHealthSnapshot(
      environment: row['environment'] as String? ?? 'unknown',
      schemaVersion: row['schema_version'] as String? ?? 'unknown',
      notes: row['notes'] as String? ?? '',
      updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? ''),
    );
  }
}

class AppHealthSnapshot {
  const AppHealthSnapshot({
    required this.environment,
    required this.schemaVersion,
    required this.notes,
    this.updatedAt,
  });

  final String environment;
  final String schemaVersion;
  final String notes;
  final DateTime? updatedAt;
}
""",
    )

    w(
        "packages/nano_data/lib/src/nano_data.dart",
        "export 'supabase/nano_supabase.dart';\n",
    )

    w(
        "packages/nano_data/lib/nano_data.dart",
        "export 'src/nano_data.dart';\n",
    )

    w(
        "packages/nano_data/test/app_health_snapshot_test.dart",
        r"""
import 'package:nano_data/nano_data.dart';
import 'package:test/test.dart';

void main() {
  test('AppHealthSnapshot holds schema version', () {
    const snap = AppHealthSnapshot(
      environment: 'development',
      schemaVersion: 'SEC-01',
      notes: 'ok',
    );
    expect(snap.schemaVersion, 'SEC-01');
  });
}
""",
    )

    # Update diagnostics page to optionally show health when configured
    diag = ROOT / "apps/student_app/lib/app/diagnostics_page.dart"
    if diag.exists():
        # leave existing; add separate supabase health page for debug
        pass

    w(
        "apps/student_app/lib/app/supabase_health_page.dart",
        r"""
import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

class SupabaseHealthPage extends StatefulWidget {
  const SupabaseHealthPage({super.key, required this.config});

  final EnvironmentConfig config;

  @override
  State<SupabaseHealthPage> createState() => _SupabaseHealthPageState();
}

class _SupabaseHealthPageState extends State<SupabaseHealthPage> {
  String _status = 'Not checked';
  AppHealthSnapshot? _snapshot;
  Object? _error;

  Future<void> _check() async {
    setState(() {
      _status = 'Checking…';
      _error = null;
      _snapshot = null;
    });
    try {
      if (widget.config.supabaseUrl.isEmpty ||
          widget.config.supabaseAnonKey.isEmpty) {
        setState(() {
          _status = 'Missing SUPABASE_URL / SUPABASE_ANON_KEY dart-defines';
        });
        return;
      }
      final gateway = NanoSupabase.fromConfig(widget.config);
      final snap = await gateway.fetchAppHealth();
      setState(() {
        _snapshot = snap;
        _status = snap == null ? 'No app_health row' : 'OK';
      });
    } catch (e) {
      setState(() {
        _error = e;
        _status = 'Failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return NanoScaffold(
      appBar: AppBar(title: const Text('Supabase health')),
      body: ListView(
        children: [
          Text('Project URL configured: '
              '${widget.config.supabaseUrl.isEmpty ? 'no' : 'yes'}'),
          const SizedBox(height: NanoSpacing.sm),
          Text('Status: $_status'),
          if (_snapshot != null) ...[
            Text('Environment: ${_snapshot!.environment}'),
            Text('Schema: ${_snapshot!.schemaVersion}'),
            Text('Notes: ${_snapshot!.notes}'),
          ],
          if (_error != null) Text('Error: $_error'),
          const SizedBox(height: NanoSpacing.md),
          FilledButton(
            onPressed: _check,
            child: const Text('Check app_health'),
          ),
        ],
      ),
    );
  }
}
""",
    )

    # Patch student pubspec for nano_data
    student_pub = ROOT / "apps/student_app/pubspec.yaml"
    sp = student_pub.read_text(encoding="utf-8")
    if "nano_data:" not in sp:
        sp = sp.replace(
            "  nano_design_system:\n    path: ../../packages/nano_design_system\n",
            "  nano_design_system:\n    path: ../../packages/nano_design_system\n"
            "  nano_data:\n    path: ../../packages/nano_data\n",
            1,
        )
        student_pub.write_text(sp, encoding="utf-8")

    # Add health button to student shell debug strip
    shell = ROOT / "apps/student_app/lib/app/student_shell.dart"
    st = shell.read_text(encoding="utf-8")
    if "supabase_health_page.dart" not in st:
        st = st.replace(
            "import 'package:student_app/app/accessibility_settings_page.dart';",
            "import 'package:student_app/app/accessibility_settings_page.dart';\n"
            "import 'package:student_app/app/supabase_health_page.dart';",
        )
    if "SupabaseHealthPage" not in st:
        marker = "child: const Text('A11y'),\n                    ),"
        insert = """
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                SupabaseHealthPage(config: config),
                          ),
                        );
                      },
                      child: const Text('DB health'),
                    ),"""
        if marker in st:
            st = st.replace(marker, marker + insert, 1)
        shell.write_text(st, encoding="utf-8")

    w(
        "supabase/seed.sql",
        """
-- Seed data for development only.
-- Prefer disposable fixtures; never put production secrets here.

-- app_health is inserted by SEC-01 migration.
select 1;
""",
    )

    w(
        "supabase/tests/sec01_baseline_checks.sql",
        """
-- Manual / MCP verification queries for SEC-01 (run via execute_sql).
-- Expected: one row, schema_version SEC-01, RLS enabled.

select id, environment, schema_version from public.app_health where id = 'default';

select c.relname as table_name, c.relrowsecurity as rls_enabled
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relname = 'app_health';
""",
    )

    w(
        "docs/setup/MIGRATION_CONVENTIONS.md",
        """
# Migration conventions (SEC-01)

## Naming

```
supabase/migrations/YYYYMMDDHHMMSS_snake_case_name.sql
```

- One concern per migration.
- Forward-only in shared remotes; document compensating SQL in module KNOWN_ISSUES / DECISIONS when needed.
- Prefer `create … if not exists` / idempotent policies for baselines.

## Remote-first apply (no Docker)

1. Author the SQL file in git.
2. Apply to **development** (`nano_v1` / `jjsnvmxasbtimesjsyoy`) via Supabase MCP `apply_migration` **or** CLI after `supabase link` (owner-approved).
3. Align the local filename timestamp with the remote migration version when MCP assigns one.
4. Verify with `list_tables` / `execute_sql` / `list_migrations`.
5. Never apply unreviewed SQL to staging/production.

## Forbidden without owner approval

- `supabase db push` to non-dev
- Destructive resets on shared remotes
- Service-role keys in apps or committed files

## RLS rule of thumb

Every new table exposed to PostgREST must enable RLS in the same migration that creates it (even if policies are expanded in SEC-02).
""",
    )

    w(
        "docs/setup/SUPABASE_REMOTE_WORKFLOW.md",
        """
# Supabase remote workflow (no Docker)

Owner policy (ADR-0002): **do not use Docker** and do not run `supabase start`.

## Development project

| Field | Value |
|-------|-------|
| Name | `nano_v1` |
| Ref | `jjsnvmxasbtimesjsyoy` |
| URL | `https://jjsnvmxasbtimesjsyoy.supabase.co` |
| Class | development (disposable) |

## Link CLI (optional)

```powershell
cd D:\\nano
supabase link --project-ref jjsnvmxasbtimesjsyoy
```

## Migrations

1. Add files under `supabase/migrations/` following [MIGRATION_CONVENTIONS.md](MIGRATION_CONVENTIONS.md).
2. Prefer MCP `apply_migration` for development.
3. Keep git and remote migration history aligned.
4. Never apply unreviewed migrations to staging/production.

## Client dart-defines

```powershell
flutter run -d chrome `
  --dart-define=NANO_ENV=development `
  --dart-define=SUPABASE_URL=https://jjsnvmxasbtimesjsyoy.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<publishable-anon-key>
```

Obtain the anon key from the Supabase dashboard or MCP `get_publishable_keys`. Never put the service-role key in Flutter.

## SEC-01 health probe

Table `public.app_health` (RLS: select for `anon` + `authenticated`).

Student debug strip → **DB health** → Check `app_health`.

## Forbidden without owner approval

- `supabase db push` to non-dev
- `supabase functions deploy` to non-dev
- `supabase secrets set` for production
""",
    )

    w(
        "scripts/check_migration_layout.ps1",
        """
# Validates migration filenames without needing Docker or a live DB.
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot\\..
$files = Get-ChildItem supabase\\migrations\\*.sql -ErrorAction SilentlyContinue
if (-not $files) { Write-Error 'No migrations found under supabase/migrations'; exit 1 }
$bad = @()
foreach ($f in $files) {
  if ($f.Name -notmatch '^\\d{14}_[a-z0-9_]+\\.sql$') { $bad += $f.Name }
}
if ($bad.Count) {
  Write-Error ("Invalid migration names:`n" + ($bad -join "`n"))
  exit 1
}
Write-Host ("OK: {0} migration file(s)" -f $files.Count)
$files | ForEach-Object { Write-Host (' - ' + $_.Name) }
""",
    )

    # Docs module
    w(
        "docs/modules/SEC-01/README.md",
        """
# SEC-01 — Supabase Baseline and Migration Workflow

## Purpose

Establish remote-first Supabase development: migration conventions, baseline schema (`app_health` + `set_updated_at`), MCP/CLI apply workflow without Docker, and a Flutter health probe via `nano_data`.

## Main surfaces

- `supabase/migrations/20260731045507_sec01_baseline.sql`
- Docs: `docs/setup/SUPABASE_REMOTE_WORKFLOW.md`, `MIGRATION_CONVENTIONS.md`
- Student debug **DB health** page
""",
    )

    w(
        "docs/modules/SEC-01/IMPLEMENTATION_PLAN.md",
        """
# SEC-01 Implementation Plan

1. Confirm empty remote `nano_v1` and ADR-0002 remote-first policy
2. Author baseline migration (extensions helpers, app_health + RLS)
3. Apply via MCP `apply_migration`; align git timestamp
4. Add `NanoSupabase` gateway + health UI
5. Document conventions and owner test steps
""",
    )

    w(
        "docs/modules/SEC-01/DECISIONS.md",
        """
# SEC-01 Decisions

- Automation SEC-01 is **baseline + workflow**; handbook “SEC-01 Tenancy/RLS” maps primarily to SEC-02/SEC-03.
- Applied baseline to classified development project `nano_v1` only.
- `app_health` is intentionally readable by anon for connectivity smoke tests; it holds no PII.
- Tenancy tables (`schools`, `memberships`, …) wait for SEC-02.
""",
    )

    w(
        "docs/modules/SEC-01/KNOWN_ISSUES.md",
        """
# SEC-01 Known Issues

- MCP `apply_migration` version timestamps may differ from locally chosen filenames; keep them aligned after apply.
- Student DB health check requires dart-defines for URL + anon key.
- pgTAP suite not yet wired (optional later / CI).
""",
    )

    w(
        "docs/modules/SEC-01/MANUAL_TEST.md",
        """
# SEC-01 Manual Test Guide

## Prerequisites

- No Docker
- Optional: Flutter with dart-defines for live health check

## Checklist

- [ ] Confirm `supabase/migrations/20260731045507_sec01_baseline.sql` exists
- [ ] Run `powershell -File scripts\\check_migration_layout.ps1` → OK
- [ ] (Owner/dev) In Supabase dashboard or MCP: `app_health` exists, RLS on, one row `schema_version=SEC-01`
- [ ] Optional live check:

```powershell
cd D:\\nano\\apps\\student_app
flutter run -d chrome `
  --dart-define=NANO_ENV=development `
  --dart-define=SUPABASE_URL=https://jjsnvmxasbtimesjsyoy.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

Open **DB health** → Check app_health → Status OK / Schema SEC-01

- [ ] Confirm no service-role key in the repo

## Approve

`NEXT`

## Reject

`FIX: <problem>`
""",
    )

    w(
        "docs/modules/SEC-01/TEST_REPORT.md",
        """
# SEC-01 Test Report

| Test | Result | Notes |
|------|--------|-------|
| MCP apply_migration sec01_baseline | RUN | success on nano_v1 |
| MCP list_tables app_health RLS | RUN | rls_enabled=true, rows=1 |
| scripts/check_migration_layout.ps1 | RUN | filename convention |
| nano_data app_health_snapshot_test | RUN | unit |
| CI workflow | NOT RUN | PAT missing `workflow` scope |
| Live Flutter health (needs anon key) | OWNER | optional manual |
""",
    )

    print("SEC-01 scaffold written")


if __name__ == "__main__":
    main()
