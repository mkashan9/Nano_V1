import 'package:admin_web/features/parent/presentation/parent_guidance_admin_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  testWidgets('creates draft and shows package detail', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.superadmin(),
          home: ParentGuidanceAdminPage(
            repository: FakeWeeklyGuidanceAdminRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('New draft'), findsOneWidget);
    await tester.tap(find.text('New draft'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Weekly tip'), findsWidgets);
    expect(find.text('Attach PDF'), findsOneWidget);
    expect(find.text('Publish'), findsOneWidget);
  });
}
