import 'package:admin_web/features/platform/presentation/community_controls_page.dart';
import 'package:admin_web/features/school/presentation/school_communities_settings_page.dart';
import 'package:admin_web/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  testWidgets('school communities tab toggles policy', (tester) async {
    final repo = FakeCommunityControlsRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SchoolCommunitiesSettingsPage(
            repository: repo,
            schoolId: TenancyFixtures.alphaSchoolId,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Enable Communities'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(
      (await repo.loadSchoolPolicy(TenancyFixtures.alphaSchoolId))
          .communitiesEnabled,
      isTrue,
    );
  });

  testWidgets('platform community controls page loads', (tester) async {
    final repo = FakeCommunityControlsRepository(platformEnabled: true);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CommunityControlsPage(repository: repo),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Community controls'), findsOneWidget);
    expect(find.text('Alpha School'), findsOneWidget);
  });

  testWidgets('superadmin shell shows Community controls nav', (tester) async {
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
    expect(find.text('Community controls'), findsWidgets);
  });
}
