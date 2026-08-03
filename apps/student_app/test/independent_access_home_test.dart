import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/home/fixtures/student_home_fixtures.dart';
import 'package:student_app/features/home/presentation/senior_home_page.dart';

Future<void> _pump(WidgetTester tester, Widget app) async {
  await tester.binding.setSurfaceSize(const Size(800, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('independent limited access shows ending-soon banner',
      (tester) async {
    await _pump(
      tester,
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.senior(),
          home: Scaffold(
            body: SeniorHomePage(
              repository: FakeStudentHomeRepository(
                subjects: StudentHomeFixtures.subjects,
                missions: StudentHomeFixtures.missions,
              ),
              learnerName: 'Ali',
              independent: true,
              accessEntitlements: IndependentAccessPolicy.limited(
                accessEndsAt:
                    DateTime.now().toUtc().add(const Duration(days: 3)),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('access is ending soon'), findsOneWidget);
    expect(find.text('Flex'), findsNothing);
  });

  testWidgets('restricted access shows reduced banner', (tester) async {
    await _pump(
      tester,
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.senior(),
          home: Scaffold(
            body: SeniorHomePage(
              repository: FakeStudentHomeRepository(
                subjects: StudentHomeFixtures.subjects,
                missions: StudentHomeFixtures.missions,
              ),
              learnerName: 'Ali',
              independent: true,
              accessEntitlements: IndependentAccessPolicy.restricted(),
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('Access is reduced'), findsOneWidget);
  });
}
