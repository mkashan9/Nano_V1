import 'package:admin_web/features/security/presentation/security_hardening_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  testWidgets('shows security hardening checklist', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.superadmin(),
          home: SecurityHardeningPage(
            config: const EnvironmentConfig(
              environment: NanoEnvironment.development,
              supabaseUrl: 'https://example.supabase.co',
              supabaseAnonKey: 'public-anon-preview-key',
              featureFlags: {},
            ),
            principal: SessionPrincipal.superadmin(),
            repository: FakeSecurityHardeningRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Security hardening'), findsOneWidget);
    expect(find.text('All checks passed'), findsOneWidget);
    expect(find.textContaining('AccessGuard'), findsOneWidget);
  });
}
