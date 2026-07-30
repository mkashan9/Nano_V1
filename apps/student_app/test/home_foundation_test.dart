import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:student_app/features/home/fixtures/student_home_fixtures.dart';
import 'package:student_app/features/home/presentation/junior_home_foundation.dart';
import 'package:student_app/features/home/presentation/senior_home_foundation.dart';

void main() {
  testWidgets('junior and senior render same subject titles', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: NanoTheme.junior(),
        home: const Scaffold(body: JuniorHomeFoundation()),
      ),
    );
    await tester.pumpAndSettle();
    for (final subject in StudentHomeFixtures.subjects) {
      expect(find.text(subject.title), findsOneWidget);
    }
    expect(find.byType(JuniorActionCard), findsNWidgets(4));

    await tester.pumpWidget(
      MaterialApp(
        theme: NanoTheme.senior(),
        home: const Scaffold(body: SeniorHomeFoundation()),
      ),
    );
    await tester.pumpAndSettle();
    // ListView builds lazily — assert visible shared domain titles.
    expect(find.byType(SeniorProgressCard), findsAtLeastNWidgets(3));
    expect(find.text('Math'), findsWidgets);
    expect(find.text('English'), findsWidgets);
  });

  testWidgets('text scale does not overflow junior home', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: MaterialApp(
          theme: NanoTheme.junior(),
          home: const Scaffold(body: JuniorHomeFoundation()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Hi'), findsOneWidget);
  });
}
