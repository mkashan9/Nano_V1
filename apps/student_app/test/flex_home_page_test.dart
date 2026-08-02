import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/flex/presentation/flex_home_page.dart';

void main() {
  testWidgets('shows hub cards and opens placeholder section', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.senior(),
          home: FlexHomePage(
            repository: FakeStudentFlexRepository(),
            flexEligible: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Flex'), findsWidgets);
    expect(find.text('Attendance'), findsOneWidget);
    expect(find.text('Marks'), findsOneWidget);
    expect(find.text('Classroom'), findsOneWidget);

    await tester.tap(find.text('Marks'));
    await tester.pumpAndSettle();
    expect(find.text('This section arrives in a later module.'), findsOneWidget);
  });

  testWidgets('blocks independent learners', (tester) async {
    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.senior(),
          home: FlexHomePage(
            repository: FakeStudentFlexRepository(),
            flexEligible: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Independent students never see Flex.'),
      findsOneWidget,
    );
  });
}
