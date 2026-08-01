import 'package:admin_web/features/content/presentation/learning_catalog_admin_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  testWidgets('lists subjects and shows shared version preview', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.superadmin(),
          home: LearningCatalogAdminPage(
            repository: FakeLearningContentRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Math'), findsWidgets);
    expect(find.text('New subject'), findsOneWidget);
    expect(find.textContaining('Shared version'), findsOneWidget);
    expect(
      find.textContaining('20000000-0000-0000-0000-000000000001'),
      findsWidgets,
    );
  });
}
