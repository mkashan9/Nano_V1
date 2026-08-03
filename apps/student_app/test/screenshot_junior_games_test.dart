import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/qa/presentation/screenshot_junior_games_page.dart';

void main() {
  testWidgets('screenshot route shows adventure header and world games',
      (tester) async {
    tester.view.physicalSize = const Size(740, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.junior(),
          home: ScreenshotJuniorGamesPage(
            repository: FakeGameCatalogRepository(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text("Today's"), findsOneWidget);
    expect(find.text('Adventure!'), findsOneWidget);
    expect(find.text('Math Island'), findsOneWidget);
    expect(find.text('Word Forest'), findsOneWidget);
    expect(find.text('Science Ocean'), findsOneWidget);
    expect(find.text('Puzzle Castle'), findsOneWidget);
    expect(find.text('Games'), findsWidgets);
  });

  testWidgets('smaller and larger viewports do not overflow', (tester) async {
    for (final size in const [Size(390, 844), Size(1024, 1366)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        NanoLocaleScope(
          locale: NanoAppLocale.en,
          copy: const NanoCopy(NanoAppLocale.en),
          child: MaterialApp(
            theme: NanoTheme.junior(),
            home: ScreenshotJuniorGamesPage(
              repository: FakeGameCatalogRepository(),
              useVisualAssets: false,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    }
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
