import 'package:admin_web/features/platform/presentation/platform_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  testWidgets('shows metric cards and school directory', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => PlatformDashboardPage(
            repository: FakePlatformDashboardRepository(),
          ),
        ),
        GoRoute(
          path: '/content',
          builder: (_, __) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/moderation',
          builder: (_, __) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/schools',
          builder: (_, __) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/audit',
          builder: (_, __) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/pilot',
          builder: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp.router(
          theme: NanoTheme.superadmin(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Platform dashboard'), findsOneWidget);
    expect(find.text('Alpha Academy'), findsOneWidget);
    expect(find.text('Beta School'), findsOneWidget);
    expect(find.byType(AdminMetricCard), findsWidgets);
  });
}
