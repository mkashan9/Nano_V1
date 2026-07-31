import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_auth/nano_auth.dart';
import 'package:student_app/features/auth/presentation/sign_in_page.dart';

void main() {
  testWidgets('sign-in page authenticates Ali via fake repo', (tester) async {
    AuthBootstrap? result;
    final repo = FakeAuthRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: SignInPage(
          authRepository: repo,
          onSignedIn: (b) => result = b,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).at(1), AuthFixtures.aliPassword);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(result?.principal.isAuthenticated, isTrue);
    expect(result?.principal.userId, AuthFixtures.aliUserId);
  });
}
