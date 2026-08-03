import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/qa/presentation/screenshot_junior_profile_page.dart';

void main() {
  testWidgets('screenshot route shows junior profile sections', (tester) async {
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
          home: ScreenshotJuniorProfilePage(
            repository: FakeStudentProfileRepository(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Ali'), findsOneWidget);
    expect(find.text('Level 7'), findsOneWidget);
    expect(find.text('320 / 500'), findsOneWidget);
    expect(find.text('Recent Learning'), findsOneWidget);
    expect(find.text('Counting Fun'), findsOneWidget);
    expect(find.text('Wild Animals'), findsOneWidget);
    expect(find.text('The Letter A'), findsOneWidget);
    expect(find.text('My Weekly Journey'), findsOneWidget);
    expect(find.text('For Parents'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Sound'), findsOneWidget);
    expect(find.text('Profile'), findsWidgets);
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
            home: ScreenshotJuniorProfilePage(
              repository: FakeStudentProfileRepository(),
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
