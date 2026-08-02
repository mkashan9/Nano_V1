import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/games/presentation/games_catalog_page.dart';

void main() {
  testWidgets('lists games and opens fixture host from Play', (tester) async {
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
            sessionRepository: FakeGameSessionRepository(),
            gradeLevel: 3,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Number Rush'), findsOneWidget);
    expect(find.text('Play'), findsWidgets);

    await tester.tap(find.text('Play').first);
    await tester.pumpAndSettle();

    expect(find.text('Tap to score'), findsOneWidget);
    await tester.tap(find.text('Tap to score'));
    await tester.pump();
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Verification comes later'), findsOneWidget);
  });
}
