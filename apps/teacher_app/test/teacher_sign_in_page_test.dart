import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_auth/nano_auth.dart';
import 'package:teacher_app/features/auth/presentation/teacher_sign_in_page.dart';

void main() {
  testWidgets('teacher sign-in authenticates Ms Khan via fake repo', (
    tester,
  ) async {
    AuthBootstrap? result;
    final repo = FakeAuthRepository.teacher();
    await tester.pumpWidget(
      MaterialApp(
        home: TeacherSignInPage(
          authRepository: repo,
          onSignedIn: (b) => result = b,
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextField).at(1),
      AuthFixtures.teacherPassword,
    );
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(result?.principal.isAuthenticated, isTrue);
    expect(result?.principal.userId, AuthFixtures.teacherUserId);
  });
}
