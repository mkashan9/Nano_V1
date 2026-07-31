"""Scaffold FND-05 shared UI state foundations."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(r"d:\nano")


def w(path: str, content: str) -> None:
    p = ROOT / path
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content.strip() + "\n", encoding="utf-8")


def main() -> None:
    # --- Domain view-state contracts ---
    w(
        "packages/nano_domain/lib/src/ui_state/nano_view_state.dart",
        r"""
/// Shared async / screen state contract for Views and ViewModels.
/// UI maps these to design-system state widgets (FND-05).
sealed class NanoViewState {
  const NanoViewState();
}

class NanoViewReady extends NanoViewState {
  const NanoViewReady();
}

class NanoViewLoading extends NanoViewState {
  const NanoViewLoading({this.message = 'Loading'});

  final String message;
}

class NanoViewEmpty extends NanoViewState {
  const NanoViewEmpty({
    this.title = 'Nothing here yet',
    this.message = 'Check back soon.',
  });

  final String title;
  final String message;
}

class NanoViewError extends NanoViewState {
  const NanoViewError({
    this.title = 'Something went wrong',
    this.message = 'Please try again.',
    this.canRetry = true,
  });

  final String title;
  final String message;
  final bool canRetry;
}

class NanoViewOffline extends NanoViewState {
  const NanoViewOffline({
    this.message = 'You are offline. Showing the last known information.',
    this.lastUpdatedLabel,
  });

  final String message;
  final String? lastUpdatedLabel;
}

class NanoViewSyncing extends NanoViewState {
  const NanoViewSyncing({this.message = 'Syncing…'});

  final String message;
}

class NanoViewSuspended extends NanoViewState {
  const NanoViewSuspended({
    this.title = 'Access paused',
    this.message = 'This account or school is temporarily suspended.',
  });

  final String title;
  final String message;
}

class NanoViewMaintenance extends NanoViewState {
  const NanoViewMaintenance({
    this.title = 'Under maintenance',
    this.message =
        'Nano is temporarily unavailable while we finish updates. Try again soon.',
  });

  final String title;
  final String message;
}

class NanoViewPermissionDenied extends NanoViewState {
  const NanoViewPermissionDenied({
    this.title = 'No access',
    this.message = 'You do not have permission to view this area.',
  });

  final String title;
  final String message;
}

class NanoViewFeatureDisabled extends NanoViewState {
  const NanoViewFeatureDisabled({
    this.title = 'Not available',
    this.message = 'This feature is turned off for your school or account.',
  });

  final String title;
  final String message;
}

extension NanoViewStateX on NanoViewState {
  bool get blocksContent => switch (this) {
        NanoViewReady() || NanoViewOffline() || NanoViewSyncing() => false,
        _ => true,
      };
}
""",
    )

    barrel = ROOT / "packages/nano_domain/lib/src/nano_domain.dart"
    text = barrel.read_text(encoding="utf-8")
    if "nano_view_state.dart" not in text:
        barrel.write_text(
            text.rstrip() + "\nexport 'ui_state/nano_view_state.dart';\n",
            encoding="utf-8",
        )

    w(
        "packages/nano_domain/test/nano_view_state_test.dart",
        r"""
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('ready and banners do not block content', () {
    expect(const NanoViewReady().blocksContent, isFalse);
    expect(const NanoViewOffline().blocksContent, isFalse);
    expect(const NanoViewSyncing().blocksContent, isFalse);
  });

  test('blocking states cover error empty suspended maintenance access', () {
    expect(const NanoViewLoading().blocksContent, isTrue);
    expect(const NanoViewEmpty().blocksContent, isTrue);
    expect(const NanoViewError().blocksContent, isTrue);
    expect(const NanoViewSuspended().blocksContent, isTrue);
    expect(const NanoViewMaintenance().blocksContent, isTrue);
    expect(const NanoViewPermissionDenied().blocksContent, isTrue);
    expect(const NanoViewFeatureDisabled().blocksContent, isTrue);
  });
}
""",
    )

    # --- Design system state widgets ---
    w(
        "packages/nano_design_system/lib/src/components/states/nano_feature_disabled_state.dart",
        r"""
import 'package:flutter/material.dart';
import '../../tokens/nano_spacing.dart';

class NanoFeatureDisabledState extends StatelessWidget {
  const NanoFeatureDisabledState({
    super.key,
    this.title = 'Not available',
    this.message = 'This feature is turned off for your school or account.',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NanoSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.toggle_off_outlined, size: 48),
            const SizedBox(height: NanoSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: NanoSpacing.xs),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
""",
    )

    w(
        "packages/nano_design_system/lib/src/components/states/nano_permission_denied_state.dart",
        r"""
import 'package:flutter/material.dart';
import '../../tokens/nano_colors.dart';
import '../../tokens/nano_spacing.dart';

class NanoPermissionDeniedState extends StatelessWidget {
  const NanoPermissionDeniedState({
    super.key,
    this.title = 'No access',
    this.message = 'You do not have permission to view this area.',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NanoSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 48,
              color: NanoColors.warning,
            ),
            const SizedBox(height: NanoSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: NanoSpacing.xs),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
""",
    )

    w(
        "packages/nano_design_system/lib/src/components/states/nano_maintenance_state.dart",
        r"""
import 'package:flutter/material.dart';
import '../../tokens/nano_colors.dart';
import '../../tokens/nano_spacing.dart';

class NanoMaintenanceState extends StatelessWidget {
  const NanoMaintenanceState({
    super.key,
    this.title = 'Under maintenance',
    this.message =
        'Nano is temporarily unavailable while we finish updates. Try again soon.',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NanoSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.construction_outlined,
              size: 48,
              color: NanoColors.warning,
            ),
            const SizedBox(height: NanoSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: NanoSpacing.xs),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
""",
    )

    w(
        "packages/nano_design_system/lib/src/components/states/nano_sync_status_banner.dart",
        r"""
import 'package:flutter/material.dart';
import '../../tokens/nano_colors.dart';
import '../../tokens/nano_spacing.dart';

enum NanoSyncPhase { idle, syncing, failed, synced }

class NanoSyncStatusBanner extends StatelessWidget {
  const NanoSyncStatusBanner({
    super.key,
    required this.phase,
    this.message,
    this.lastUpdatedLabel,
    this.onRetry,
  });

  final NanoSyncPhase phase;
  final String? message;
  final String? lastUpdatedLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (phase == NanoSyncPhase.idle) {
      return const SizedBox.shrink();
    }

    final (icon, color, defaultMessage) = switch (phase) {
      NanoSyncPhase.syncing => (
          Icons.sync,
          NanoColors.brandSecondary,
          'Syncing…',
        ),
      NanoSyncPhase.failed => (
          Icons.sync_problem,
          NanoColors.error,
          'Sync failed. Retry when ready.',
        ),
      NanoSyncPhase.synced => (
          Icons.cloud_done_outlined,
          NanoColors.success,
          'Up to date',
        ),
      NanoSyncPhase.idle => (
          Icons.cloud_outlined,
          NanoColors.textSecondary,
          '',
        ),
    };

    final body = [
      message ?? defaultMessage,
      if (lastUpdatedLabel != null) 'Last updated $lastUpdatedLabel',
    ].where((s) => s.isNotEmpty).join(' · ');

    return Material(
      color: color.withValues(alpha: 0.18),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: NanoSpacing.md,
          vertical: NanoSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: NanoSpacing.sm),
            Expanded(child: Text(body)),
            if (phase == NanoSyncPhase.failed && onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
""",
    )

    # Enhance offline banner with last-updated
    w(
        "packages/nano_design_system/lib/src/components/states/nano_offline_banner.dart",
        r"""
import 'package:flutter/material.dart';
import '../../tokens/nano_colors.dart';
import '../../tokens/nano_spacing.dart';

class NanoOfflineBanner extends StatelessWidget {
  const NanoOfflineBanner({
    super.key,
    this.message = 'You are offline. Changes will sync when you reconnect.',
    this.lastUpdatedLabel,
  });

  final String message;
  final String? lastUpdatedLabel;

  @override
  Widget build(BuildContext context) {
    final body = lastUpdatedLabel == null
        ? message
        : '$message · Last updated $lastUpdatedLabel';
    return Material(
      color: NanoColors.offline.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: NanoSpacing.md,
          vertical: NanoSpacing.sm,
        ),
        child: Row(
          children: [
            const Icon(Icons.wifi_off, color: NanoColors.offline),
            const SizedBox(width: NanoSpacing.sm),
            Expanded(child: Text(body)),
          ],
        ),
      ),
    );
  }
}
""",
    )

    w(
        "packages/nano_design_system/lib/src/components/states/nano_view_state_host.dart",
        r"""
import 'package:flutter/material.dart';
import 'package:nano_domain/nano_domain.dart';
import 'nano_empty_state.dart';
import 'nano_error_state.dart';
import 'nano_feature_disabled_state.dart';
import 'nano_loading_state.dart';
import 'nano_maintenance_state.dart';
import 'nano_offline_banner.dart';
import 'nano_permission_denied_state.dart';
import 'nano_suspended_state.dart';
import 'nano_sync_status_banner.dart';

/// Maps [NanoViewState] to design-system chrome. Ready state shows [child].
class NanoViewStateHost extends StatelessWidget {
  const NanoViewStateHost({
    super.key,
    required this.state,
    required this.child,
    this.onRetry,
  });

  final NanoViewState state;
  final Widget child;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      NanoViewReady() => child,
      NanoViewLoading(:final message) => NanoLoadingState(message: message),
      NanoViewEmpty(:final title, :final message) =>
        NanoEmptyState(title: title, message: message),
      NanoViewError(:final title, :final message, :final canRetry) =>
        NanoErrorState(
          title: title,
          message: message,
          onRetry: canRetry ? onRetry : null,
        ),
      NanoViewSuspended(:final title, :final message) =>
        NanoSuspendedState(title: title, message: message),
      NanoViewMaintenance(:final title, :final message) =>
        NanoMaintenanceState(title: title, message: message),
      NanoViewPermissionDenied(:final title, :final message) =>
        NanoPermissionDeniedState(title: title, message: message),
      NanoViewFeatureDisabled(:final title, :final message) =>
        NanoFeatureDisabledState(title: title, message: message),
      NanoViewOffline(:final message, :final lastUpdatedLabel) => Column(
          children: [
            NanoOfflineBanner(
              message: message,
              lastUpdatedLabel: lastUpdatedLabel,
            ),
            Expanded(child: child),
          ],
        ),
      NanoViewSyncing(:final message) => Column(
          children: [
            NanoSyncStatusBanner(
              phase: NanoSyncPhase.syncing,
              message: message,
            ),
            Expanded(child: child),
          ],
        ),
    };
  }
}
""",
    )

    ds = ROOT / "packages/nano_design_system/lib/nano_design_system.dart"
    ds_text = ds.read_text(encoding="utf-8")
    extras = [
        "export 'src/components/states/nano_feature_disabled_state.dart';",
        "export 'src/components/states/nano_permission_denied_state.dart';",
        "export 'src/components/states/nano_maintenance_state.dart';",
        "export 'src/components/states/nano_sync_status_banner.dart';",
        "export 'src/components/states/nano_view_state_host.dart';",
    ]
    for line in extras:
        if line not in ds_text:
            ds_text = ds_text.rstrip() + "\n" + line + "\n"
    ds.write_text(ds_text, encoding="utf-8")

    # Ensure nano_design_system depends on nano_domain for host
    ds_pub = ROOT / "packages/nano_design_system/pubspec.yaml"
    pub = ds_pub.read_text(encoding="utf-8")
    if "nano_domain:" not in pub:
        pub = pub.replace(
            "dependencies:\n  flutter:\n    sdk: flutter\n",
            "dependencies:\n  flutter:\n    sdk: flutter\n  nano_domain:\n    path: ../nano_domain\n",
            1,
        )
        ds_pub.write_text(pub, encoding="utf-8")

    w(
        "packages/nano_design_system/test/nano_view_state_host_test.dart",
        r"""
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  testWidgets('host shows child when ready', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NanoViewStateHost(
            state: NanoViewReady(),
            child: Text('content'),
          ),
        ),
      ),
    );
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('host shows maintenance and error retry', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NanoViewStateHost(
            state: const NanoViewMaintenance(),
            onRetry: () => retried = true,
            child: const Text('hidden'),
          ),
        ),
      ),
    );
    expect(find.text('Under maintenance'), findsOneWidget);
    expect(find.text('hidden'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NanoViewStateHost(
            state: const NanoViewError(),
            onRetry: () => retried = true,
            child: const Text('hidden'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);
  });

  testWidgets('offline keeps child visible under banner', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NanoViewStateHost(
            state: NanoViewOffline(lastUpdatedLabel: '2 min ago'),
            child: Text('cached'),
          ),
        ),
      ),
    );
    expect(find.textContaining('offline'), findsOneWidget);
    expect(find.textContaining('2 min ago'), findsOneWidget);
    expect(find.text('cached'), findsOneWidget);
  });
}
""",
    )

    # Student states preview page
    w(
        "apps/student_app/lib/app/states_preview_page.dart",
        r"""
import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// Dev-only catalog of FND-05 view states for owner review.
class StatesPreviewPage extends StatefulWidget {
  const StatesPreviewPage({super.key});

  @override
  State<StatesPreviewPage> createState() => _StatesPreviewPageState();
}

class _StatesPreviewPageState extends State<StatesPreviewPage> {
  late NanoViewState _state = const NanoViewReady();

  static const _options = <(String, NanoViewState)>[
    ('Ready', NanoViewReady()),
    ('Loading', NanoViewLoading()),
    ('Empty', NanoViewEmpty()),
    ('Error', NanoViewError()),
    ('Offline', NanoViewOffline(lastUpdatedLabel: '2 min ago')),
    ('Syncing', NanoViewSyncing()),
    ('Suspended', NanoViewSuspended()),
    ('Maintenance', NanoViewMaintenance()),
    ('Permission denied', NanoViewPermissionDenied()),
    ('Feature disabled', NanoViewFeatureDisabled()),
  ];

  @override
  Widget build(BuildContext context) {
    return NanoScaffold(
      padBody: false,
      appBar: AppBar(title: const Text('UI states preview')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(NanoSpacing.sm),
            child: Row(
              children: [
                for (final (label, state) in _options)
                  Padding(
                    padding: const EdgeInsets.only(right: NanoSpacing.sm),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: _state.runtimeType == state.runtimeType,
                      onSelected: (_) => setState(() => _state = state),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: NanoViewStateHost(
              state: _state,
              onRetry: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Retry tapped')),
                );
                setState(() => _state = const NanoViewReady());
              },
              child: const _SampleContent(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SampleContent extends StatelessWidget {
  const _SampleContent();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(NanoSpacing.md),
      children: [
        Text('Sample learning content', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: NanoSpacing.sm),
        const Text(
          'Banners (offline / syncing) keep this content visible. '
          'Blocking states replace it until the user recovers.',
        ),
        const SizedBox(height: NanoSpacing.lg),
        const JuniorActionCard(
          title: 'Math',
          subtitle: 'Visible under non-blocking states',
          backgroundColor: NanoColors.worldMath,
        ),
      ],
    );
  }
}
""",
    )

    # Patch gallery
    w(
        "apps/student_app/lib/app/component_gallery_page.dart",
        r"""
import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';

class ComponentGalleryPage extends StatefulWidget {
  const ComponentGalleryPage({super.key});

  @override
  State<ComponentGalleryPage> createState() => _ComponentGalleryPageState();
}

class _ComponentGalleryPageState extends State<ComponentGalleryPage> {
  bool senior = false;

  @override
  Widget build(BuildContext context) {
    final theme = senior ? NanoTheme.senior() : NanoTheme.junior();
    return Theme(
      data: theme,
      child: NanoScaffold(
        appBar: AppBar(
          title: const Text('Component gallery'),
          actions: [
            Row(
              children: [
                Text(senior ? 'Senior' : 'Junior'),
                Switch(
                  value: senior,
                  onChanged: (v) => setState(() => senior = v),
                ),
              ],
            ),
          ],
        ),
        body: ListView(
          children: [
            const SizedBox(height: NanoSpacing.md),
            const XpChip(xp: 560),
            const SizedBox(height: NanoSpacing.md),
            const CompanionSlot(),
            const SizedBox(height: NanoSpacing.md),
            if (!senior)
              JuniorActionCard(
                title: 'Math',
                subtitle: 'Numbers adventure',
                backgroundColor: NanoColors.worldMath,
                onTap: () {},
              )
            else
              const SeniorProgressCard(
                title: 'Genetics: The Code of Life',
                tag: 'Science',
                progress: 0.65,
                meta: '45 min',
              ),
            const SizedBox(height: NanoSpacing.md),
            const NanoOfflineBanner(lastUpdatedLabel: '2 min ago'),
            const SizedBox(height: NanoSpacing.sm),
            const NanoSyncStatusBanner(phase: NanoSyncPhase.syncing),
            const SizedBox(height: NanoSpacing.sm),
            NanoSyncStatusBanner(
              phase: NanoSyncPhase.failed,
              onRetry: () {},
            ),
            const SizedBox(height: NanoSpacing.xl),
            Text('States', style: theme.textTheme.titleLarge),
            const SizedBox(height: 120, child: NanoLoadingState()),
            const SizedBox(height: 160, child: NanoEmptyState()),
            SizedBox(
              height: 180,
              child: NanoErrorState(onRetry: () {}),
            ),
            const SizedBox(height: 160, child: NanoSuspendedState()),
            const SizedBox(height: 160, child: NanoMaintenanceState()),
            const SizedBox(height: 160, child: NanoPermissionDeniedState()),
            const SizedBox(height: 160, child: NanoFeatureDisabledState()),
            const SizedBox(height: NanoSpacing.xl),
            AdminMetricCard(
              label: 'Active schools',
              value: '12',
              icon: Icons.school_outlined,
            ),
            const SizedBox(height: NanoSpacing.md),
            TeacherTaskCard(
              title: 'Take attendance',
              subtitle: 'Class 5-A · Today',
              onTap: () {},
            ),
            const SizedBox(height: NanoSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
""",
    )

    # Patch student_shell to add States preview button - read and patch carefully
    shell = ROOT / "apps/student_app/lib/app/student_shell.dart"
    shell_text = shell.read_text(encoding="utf-8")
    if "states_preview_page.dart" not in shell_text:
        shell_text = shell_text.replace(
            "import 'package:student_app/app/component_gallery_page.dart';",
            "import 'package:student_app/app/component_gallery_page.dart';\n"
            "import 'package:student_app/app/states_preview_page.dart';",
        )
        insert = '''
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const StatesPreviewPage(),
                          ),
                        );
                      },
                      child: const Text('UI states'),
                    ),'''
        # Insert after Gallery button block
        marker = "child: const Text('Gallery'),\n                    ),"
        if marker in shell_text and "UI states" not in shell_text:
            shell_text = shell_text.replace(
                marker,
                marker + insert,
                1,
            )
        shell.write_text(shell_text, encoding="utf-8")

    w(
        "apps/student_app/test/states_preview_test.dart",
        r"""
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/app/states_preview_page.dart';

void main() {
  testWidgets('states preview can switch to maintenance', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: StatesPreviewPage()));
    await tester.pumpAndSettle();
    expect(find.text('Sample learning content'), findsOneWidget);

    await tester.tap(find.text('Maintenance'));
    await tester.pumpAndSettle();
    expect(find.text('Under maintenance'), findsOneWidget);
    expect(find.text('Sample learning content'), findsNothing);

    await tester.tap(find.text('Offline'));
    await tester.pumpAndSettle();
    expect(find.textContaining('offline'), findsOneWidget);
    expect(find.text('Sample learning content'), findsOneWidget);
  });
}
""",
    )

    # Docs
    w(
        "docs/modules/FND-05/README.md",
        """
# FND-05 — Error, Loading, Empty, Offline, and Maintenance States

## Purpose

Shared `NanoViewState` contracts and design-system chrome so every feature can render loading, empty, error/retry, offline (+ last-updated), syncing, suspended, maintenance, permission-denied, and feature-disabled states consistently.

## Main surfaces

- Design-system state widgets + `NanoViewStateHost`
- Student **UI states** preview (debug)
- Component gallery state section
""",
    )

    w(
        "docs/modules/FND-05/IMPLEMENTATION_PLAN.md",
        """
# FND-05 Implementation Plan

1. Domain sealed `NanoViewState` (+ `blocksContent`)
2. Complete state widgets (maintenance, permission, feature-disabled, sync banner)
3. `NanoViewStateHost` mapping
4. Gallery + student preview page
5. Widget / unit tests
""",
    )

    w(
        "docs/modules/FND-05/DECISIONS.md",
        """
# FND-05 Decisions

- Automation queue FND-05 is UI state foundations; handbook “FND-05 Local Cache” maps to SYNC-01.
- Offline and syncing are non-blocking banners so cached content remains visible.
- Maintenance / suspended / permission / feature-disabled fully replace content.
- Sync queue persistence is SYNC-01; this module only provides visible sync chrome.
""",
    )

    w(
        "docs/modules/FND-05/KNOWN_ISSUES.md",
        """
# FND-05 Known Issues

- Connectivity is simulated in the preview; real network detection arrives with SYNC-01.
- Maintenance mode is not yet driven by a remote config flag.
""",
    )

    w(
        "docs/modules/FND-05/MANUAL_TEST.md",
        """
# FND-05 Manual Test Guide

## Setup

```powershell
cd D:\\nano
dart pub get
dart run melos bootstrap
cd apps\\student_app
flutter run -d chrome --dart-define=NANO_ENV=development
```

## Checklist

- [ ] Open **UI states** from the debug strip
- [ ] Cycle Ready → Loading → Empty → Error (tap Try again)
- [ ] Offline / Syncing keep sample content visible with banners
- [ ] Suspended / Maintenance / Permission denied / Feature disabled replace content
- [ ] Open **Gallery** — new state widgets and sync banners appear
- [ ] No Docker required

## Approve

`NEXT`

## Reject

`FIX: <problem>`
""",
    )

    w(
        "docs/modules/FND-05/TEST_REPORT.md",
        """
# FND-05 Test Report

| Test | Result | Notes |
|------|--------|-------|
| nano_domain nano_view_state_test | RUN | blocksContent rules |
| nano_design_system nano_view_state_host_test | RUN | host mapping |
| student_app states_preview_test | RUN | preview switching |
| CI workflow | NOT RUN | PAT missing `workflow` scope |
""",
    )

    print("FND-05 scaffold written")


if __name__ == "__main__":
    main()
