import 'package:admin_web/features/auth/presentation/admin_sign_in_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_auth/nano_auth.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  testWidgets('admin sign-in authenticates school admin via fake repo', (
    tester,
  ) async {
    AuthBootstrap? result;
    final repo = FakeAuthRepository.schoolAdmin();
    await tester.pumpWidget(
      MaterialApp(
        home: AdminSignInPage(
          authRepository: repo,
          onSignedIn: (b) => result = b,
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextField).at(1),
      AuthFixtures.schoolAdminPassword,
    );
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(result?.principal.role, AppRole.schoolAdmin);
    expect(result?.principal.userId, AuthFixtures.schoolAdminUserId);
  });
}
