import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/qa/presentation/screenshot_senior_learning_page.dart';

void main() {
  testWidgets('screenshot route shows senior learning sections', (tester) async {
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
          home: ScreenshotSeniorLearningPage(
            repository: FakeLearningCatalogRepository(seniorEligible: true),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('AI Mentor'), findsOneWidget);
    expect(find.text('Recently Learned'), findsOneWidget);
    expect(find.text('Explore by Category'), findsOneWidget);
    expect(find.text('Programming'), findsOneWidget);
    expect(find.text('Learn'), findsWidgets);

    await tester.dragUntilVisible(
      find.text('Learning Paths'),
      find.byType(ListView).first,
      const Offset(0, -240),
    );
    expect(find.text('Learning Paths'), findsOneWidget);
    expect(find.text('Foundations'), findsOneWidget);
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
            home: ScreenshotSeniorLearningPage(
              repository: FakeLearningCatalogRepository(seniorEligible: true),
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
