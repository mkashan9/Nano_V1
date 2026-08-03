import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/qa/presentation/screenshot_senior_games_page.dart';

void main() {
  testWidgets('screenshot route shows senior games sections', (tester) async {
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
          theme: NanoTheme.senior(),
          home: ScreenshotSeniorGamesPage(
            repository: FakeGameCatalogRepository(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Play. Learn.'), findsOneWidget);
    expect(find.text('Build the future.'), findsOneWidget);
    expect(find.text('Code Quest'), findsOneWidget);
    expect(find.text('Math Arena'), findsOneWidget);
    expect(find.text('Games'), findsWidgets);

    await tester.dragUntilVisible(
      find.text('Unlock Worlds'),
      find.byType(ListView).first,
      const Offset(0, -240),
    );
    expect(find.text('Unlock Worlds'), findsOneWidget);
    expect(find.text('Daily Challenge'), findsOneWidget);
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
            theme: NanoTheme.senior(),
            home: ScreenshotSeniorGamesPage(
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
