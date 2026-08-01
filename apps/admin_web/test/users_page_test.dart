import 'package:admin_web/features/users/presentation/users_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  testWidgets('lists users and opens suspend dialog', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.superadmin(),
          home: UsersPage(repository: FakePlatformUserRepository()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Ali'), findsOneWidget);
    expect(find.textContaining('Alpha Admin'), findsOneWidget);
    await tester.tap(find.text('Suspend').first);
    await tester.pumpAndSettle();
    expect(find.text('Suspend user'), findsOneWidget);
    expect(find.text('Reason'), findsOneWidget);
  });
}
