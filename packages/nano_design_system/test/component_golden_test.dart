import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_design_system/nano_design_system.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpCard(WidgetTester tester, ThemeData theme, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(body: Center(child: SizedBox(width: 320, child: child))),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('junior action card golden', (tester) async {
    await pumpCard(
      tester,
      NanoTheme.junior(),
      JuniorActionCard(
        title: 'Math',
        subtitle: 'Play and learn',
        backgroundColor: NanoColors.worldMath,
      ),
    );
    await expectLater(
      find.byType(JuniorActionCard),
      matchesGoldenFile('goldens/junior_action_card.png'),
    );
  });

  testWidgets('senior progress card golden', (tester) async {
    await pumpCard(
      tester,
      NanoTheme.senior(),
      const SeniorProgressCard(
        title: 'Genetics: The Code of Life',
        tag: 'Science',
        progress: 0.65,
        meta: '45 min',
      ),
    );
    await expectLater(
      find.byType(SeniorProgressCard),
      matchesGoldenFile('goldens/senior_progress_card.png'),
    );
  });
}
