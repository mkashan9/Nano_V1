import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/home/fixtures/student_home_fixtures.dart';
import 'package:student_app/features/qa/presentation/screenshot_junior_home_page.dart';

void main() {
  testWidgets('screenshot route content shows greeting and subjects',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(370, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.junior(),
          home: ScreenshotJuniorHomePage(
            useVisualAssets: false,
            repository: FakeStudentHomeRepository(
              subjects: StudentHomeFixtures.subjects,
              missions: const [],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Hi Ali'), findsOneWidget);
    expect(find.text('Animals Adventure'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Math'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('smaller and larger viewports do not overflow', (tester) async {
    for (final size in const [Size(360, 640), Size(430, 932)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        NanoLocaleScope(
          locale: NanoAppLocale.en,
          copy: const NanoCopy(NanoAppLocale.en),
          child: MediaQuery(
            data: MediaQueryData(size: size),
            child: MaterialApp(
              theme: NanoTheme.junior(),
              home: ScreenshotJuniorHomePage(
                useVisualAssets: false,
                repository: FakeStudentHomeRepository(
                  subjects: StudentHomeFixtures.subjects,
                  missions: const [],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      expect(find.text('Hi Ali'), findsOneWidget);
    }
    await tester.binding.setSurfaceSize(null);
  });
}
