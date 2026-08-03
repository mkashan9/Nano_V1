import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/home/fixtures/student_home_fixtures.dart';
import 'package:student_app/features/qa/presentation/screenshot_senior_home_page.dart';

void main() {
  testWidgets('screenshot route shows senior home sections', (tester) async {
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
          home: ScreenshotSeniorHomePage(
            repository: FakeStudentHomeRepository(
              subjects: StudentHomeFixtures.subjects,
              missions: StudentHomeFixtures.missions,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('my future'), findsOneWidget);
    expect(find.text('Continue Building'), findsOneWidget);
    expect(find.text('Space Explorer Game'), findsOneWidget);
    expect(find.text("Today's Mission"), findsOneWidget);
    expect(find.text('Builder Dashboard'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);

    await tester.dragUntilVisible(
      find.text('Build a Calculator'),
      find.byType(ListView).first,
      const Offset(0, -240),
    );
    expect(find.text('Genetics: The Code of Life'), findsOneWidget);
    expect(find.text('Build a Calculator'), findsOneWidget);
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
            home: ScreenshotSeniorHomePage(
              repository: FakeStudentHomeRepository(
                subjects: StudentHomeFixtures.subjects,
                missions: StudentHomeFixtures.missions,
              ),
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
