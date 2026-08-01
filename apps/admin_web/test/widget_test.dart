import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:admin_web/main.dart';

void main() {
  testWidgets('school admin shell shows side destinations', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const config = EnvironmentConfig(
      environment: NanoEnvironment.development,
      supabaseUrl: '',
      supabaseAnonKey: '',
      featureFlags: {},
    );
    await tester.pumpWidget(const NanoAdminApp(config: config));
    await tester.pumpAndSettle();
    expect(find.textContaining('School'), findsWidgets);
    expect(find.text('Students'), findsOneWidget);
    expect(find.text('Teachers'), findsOneWidget);
  });

  testWidgets('superadmin shell shows platform destinations', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const config = EnvironmentConfig(
      environment: NanoEnvironment.development,
      supabaseUrl: '',
      supabaseAnonKey: '',
      featureFlags: {},
    );
    await tester.pumpWidget(
      NanoAdminApp(
        config: config,
        initialPrincipal: SessionPrincipal.superadmin(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Platform'), findsWidgets);
    expect(find.text('Platform dashboard'), findsOneWidget);
    expect(find.text('Moderation'), findsWidgets);
    expect(find.text('Audit'), findsWidgets);
  });
}
