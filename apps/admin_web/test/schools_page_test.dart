import 'package:admin_web/features/schools/presentation/schools_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  testWidgets('lists schools and opens create dialog', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.superadmin(),
          home: SchoolsPage(repository: FakeSchoolAdminRepository()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Alpha Academy'), findsOneWidget);
    expect(find.textContaining('Beta School'), findsOneWidget);
    await tester.tap(find.text('Create').first);
    await tester.pumpAndSettle();
    expect(find.text('Create school'), findsOneWidget);
  });
}
