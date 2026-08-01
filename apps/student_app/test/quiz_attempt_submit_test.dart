import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/quiz/presentation/junior_quiz_page.dart';

void main() {
  testWidgets('finish shows server score from attempt repository',
      (tester) async {
    final attempts = FakeQuizAttemptRepository();
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          home: JuniorQuizPage(
            topicVersionId: '40000000-0000-0000-0000-000000000001',
            repository: FakeLearnerQuizRepository(),
            attemptRepository: attempts,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Five'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(attempts.submitCount, 1);
    expect(find.textContaining('Score: 100%'), findsOneWidget);
    expect(find.text('This score was saved by the server.'), findsOneWidget);
  });
}
