import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/communities/presentation/communities_hub_page.dart';
import 'package:student_app/main.dart';

void main() {
  testWidgets('communities hub shows my and discover lists', (tester) async {
    final repo = FakeCommunityDiscoveryRepository();
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.senior(),
          home: CommunitiesHubPage(repository: repo),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Communities'), findsOneWidget);
    expect(find.text('Study Circle'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();
    expect(find.text('Science Lab'), findsOneWidget);
  });

  testWidgets('create community lands on My list', (tester) async {
    final repo = FakeCommunityDiscoveryRepository();
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.senior(),
          home: CommunitiesHubPage(repository: repo),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Chess Club');
    await tester.tap(find.widgetWithText(FilledButton, 'Create').last);
    await tester.pumpAndSettle();
    expect(find.text('Chess Club'), findsWidgets);
  });

  testWidgets('senior shell shows Communities destination', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const config = EnvironmentConfig(
      environment: NanoEnvironment.development,
      supabaseUrl: '',
      supabaseAnonKey: '',
      featureFlags: {'diagnostics': true},
    );
    await tester.pumpWidget(
      NanoStudentApp(
        config: config,
        initialPrincipal: SessionPrincipal.seniorSchool(),
        communityDiscoveryRepository: FakeCommunityDiscoveryRepository(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Communities'), findsWidgets);
  });
}
