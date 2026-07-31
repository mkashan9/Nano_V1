import 'package:nano_auth/nano_auth.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('FakeAuthRepository', () {
    test('signs in Ali and restores session', () async {
      final repo = FakeAuthRepository();
      final bootstrap = await repo.signInWithPassword(
        email: AuthFixtures.aliEmail,
        password: AuthFixtures.aliPassword,
      );
      expect(bootstrap.principal.isAuthenticated, isTrue);
      expect(bootstrap.principal.userId, AuthFixtures.aliUserId);
      expect(bootstrap.isBlocked, isFalse);

      final restored = await repo.restoreSession();
      expect(restored?.principal.displayName, 'Ali');

      await repo.signOut();
      expect(await repo.restoreSession(), isNull);
    });

    test('rejects bad password', () async {
      final repo = FakeAuthRepository();
      expect(
        () => repo.signInWithPassword(
          email: AuthFixtures.aliEmail,
          password: 'wrong',
        ),
        throwsA(isA<AuthFailure>()),
      );
    });
  });

  group('AuthFixtures', () {
    test('bind to tenancy Ali UUID', () {
      expect(AuthFixtures.aliUserId, TenancyFixtures.aliAlphaId);
    });
  });
}
