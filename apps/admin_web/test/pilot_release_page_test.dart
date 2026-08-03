import 'package:admin_web/features/pilot/presentation/pilot_release_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  testWidgets('shows pilot release readiness checklist', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.superadmin(),
          home: PilotReleasePage(
            config: const EnvironmentConfig(
              environment: NanoEnvironment.development,
              supabaseUrl: 'https://example.supabase.co',
              supabaseAnonKey: 'public-anon-preview-key',
              featureFlags: {},
            ),
            repository: FakePilotReleaseRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pilot release readiness'), findsOneWidget);
    expect(find.text('All pilot gates passed'), findsOneWidget);
    expect(find.textContaining('QA-01'), findsOneWidget);
    expect(find.textContaining('QA-05'), findsOneWidget);
  });
}
