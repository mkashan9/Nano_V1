import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/qa/presentation/screenshot_senior_profile_page.dart';

void main() {
  testWidgets('screenshot route shows senior profile sections', (tester) async {
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
          home: ScreenshotSeniorProfilePage(
            repository: FakeStudentProfileRepository(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Hey Ayaan!'), findsOneWidget);
    expect(find.text('Master Builder'), findsOneWidget);
    expect(find.text('23 Day Streak'), findsOneWidget);
    expect(find.text('This Week'), findsOneWidget);
    expect(find.text('Achievements'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('Learning Journey'),
      find.byType(ListView).first,
      const Offset(0, -240),
    );
    expect(find.text('Learning Journey'), findsOneWidget);
    expect(find.text('Top Builders'), findsOneWidget);
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
            theme: NanoTheme.senior(),
            home: ScreenshotSeniorProfilePage(
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
