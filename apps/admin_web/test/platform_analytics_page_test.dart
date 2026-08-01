import 'package:admin_web/features/analytics/presentation/platform_analytics_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  testWidgets('shows health and activity metrics', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.superadmin(),
          home: PlatformAnalyticsPage(
            repository: FakePlatformAnalyticsRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Platform analytics'), findsOneWidget);
    expect(find.text('Active schools'), findsOneWidget);
    expect(find.text('Last 7 days'), findsOneWidget);
  });
}
