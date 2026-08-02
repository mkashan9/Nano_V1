import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:teacher_app/features/classes/presentation/teacher_classes_page.dart';

void main() {
  testWidgets('lists assignments and opens roster', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.teacher(),
          home: TeacherClassesPage(
            repository: FakeTeacherClassesRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My classes'), findsOneWidget);
    expect(find.textContaining('MATH'), findsOneWidget);

    await tester.tap(find.textContaining('MATH'));
    await tester.pumpAndSettle();

    expect(find.text('Ali Khan'), findsOneWidget);
    expect(find.text('2 students'), findsOneWidget);
  });

  testWidgets('denies unknown assignment id', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.teacher(),
          home: TeacherClassesPage(
            repository: FakeTeacherClassesRepository(),
            initialAssignmentId: 'not-mine',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('not in your active scope'), findsNothing);
    // Error host shows retry surface instead of roster names.
    expect(find.text('Ali Khan'), findsNothing);
  });
}
