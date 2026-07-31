import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_auth/nano_auth.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/auth/presentation/recover_password_page.dart';
import 'package:student_app/features/auth/presentation/sign_up_page.dart';

void main() {
  testWidgets('signup creates an independent learner', (tester) async {
    AuthBootstrap? result;
    await tester.pumpWidget(
      MaterialApp(
        home: SignUpPage(
          authRepository: FakeAuthRepository(),
          onSignedUp: (b) => result = b,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'Sana');
    await tester.enterText(find.byType(TextField).at(1), 'sana@nano.dev');
    await tester.enterText(find.byType(TextField).at(2), 'NanoLearn1');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(result?.principal.role, AppRole.independentStudent);
    expect(result?.principal.schoolId, isNull);
  });

  testWidgets('signup shows validation error for weak password',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SignUpPage(
          authRepository: FakeAuthRepository(),
          onSignedUp: (_) {},
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'Sana');
    await tester.enterText(find.byType(TextField).at(1), 'sana@nano.dev');
    await tester.enterText(find.byType(TextField).at(2), 'abc');
    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(find.text('Use at least 8 characters'), findsOneWidget);
  });

  testWidgets('recovery confirms without revealing account existence',
      (tester) async {
    final repo = FakeAuthRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: RecoverPasswordPage(authRepository: repo),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'unknown@nano.dev');
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();

    expect(find.textContaining('a reset link is on its way'), findsOneWidget);
    expect(repo.recoveryRequests, ['unknown@nano.dev']);
  });
}
