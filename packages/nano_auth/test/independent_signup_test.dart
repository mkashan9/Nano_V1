import 'package:nano_auth/nano_auth.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('SignUpValidator', () {
    test('rejects malformed emails', () {
      expect(SignUpValidator.emailError(''), isNotNull);
      expect(SignUpValidator.emailError('nope'), isNotNull);
      expect(SignUpValidator.emailError('learner@nano.dev'), isNull);
    });

    test('requires 8+ chars with letters and digits', () {
      expect(SignUpValidator.passwordError('short1'), isNotNull);
      expect(SignUpValidator.passwordError('allletters'), isNotNull);
      expect(SignUpValidator.passwordError('12345678'), isNotNull);
      expect(SignUpValidator.passwordError('NanoLearn1'), isNull);
    });

    test('requires a display name', () {
      expect(SignUpValidator.displayNameError('   '), isNotNull);
      expect(SignUpValidator.displayNameError('Sana'), isNull);
    });
  });

  group('FakeAuthRepository independent signup', () {
    test('creates an independent principal without a school', () async {
      final repo = FakeAuthRepository();
      final result = await repo.signUpIndependent(
        email: 'sana@nano.dev',
        password: 'NanoLearn1',
        displayName: 'Sana',
      );

      expect(result.needsEmailConfirmation, isFalse);
      final principal = result.bootstrap!.principal;
      expect(principal.isAuthenticated, isTrue);
      expect(principal.role, AppRole.independentStudent);
      expect(principal.schoolId, isNull);
      expect((await repo.restoreSession())?.principal.displayName, 'Sana');
    });

    test('rejects duplicate email', () async {
      final repo = FakeAuthRepository(registeredEmails: {'sana@nano.dev'});
      expect(
        () => repo.signUpIndependent(
          email: 'Sana@nano.dev',
          password: 'NanoLearn1',
          displayName: 'Sana',
        ),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('reports pending confirmation instead of a session', () async {
      final repo = FakeAuthRepository(requireEmailConfirmation: true);
      final result = await repo.signUpIndependent(
        email: 'sana@nano.dev',
        password: 'NanoLearn1',
        displayName: 'Sana',
      );
      expect(result.needsEmailConfirmation, isTrue);
      expect(result.bootstrap, isNull);
      expect(await repo.restoreSession(), isNull);
    });

    test('records recovery requests and validates the address', () async {
      final repo = FakeAuthRepository();
      await repo.requestPasswordRecovery('  Sana@nano.dev ');
      expect(repo.recoveryRequests, ['sana@nano.dev']);
      expect(
        () => repo.requestPasswordRecovery('nope'),
        throwsA(isA<AuthFailure>()),
      );
    });
  });
}
