import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/games/presentation/games_catalog_page.dart';

void main() {
  testWidgets('lists eligible games for a junior school learner', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.junior(),
          home: GamesCatalogPage(
            repository: FakeGameCatalogRepository(),
            gradeLevel: 3,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Games'), findsWidgets);
    expect(find.text('Number Rush'), findsOneWidget);
    expect(find.text('School Circuit'), findsNothing);
    expect(find.textContaining('Play opens'), findsOneWidget);
  });
}
