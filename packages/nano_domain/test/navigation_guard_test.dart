import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('independent student never sees Flex destination', () {
    final principal = SessionPrincipal.independent();
    final visible = NavCatalog.visibleFor(principal);
    expect(visible.any((d) => d.id == 'flex'), isFalse);
  });

  test('independent nav copy uses Home Learn Play Me', () {
    const copy = NanoCopy(NanoAppLocale.en);
    expect(
      copy.studentNavLabel('home', junior: false, independent: true),
      'Home',
    );
    expect(
      copy.studentNavLabel('learning', junior: false, independent: true),
      'Learn',
    );
    expect(
      copy.studentNavLabel('games', junior: false, independent: true),
      'Play',
    );
    expect(
      copy.studentNavLabel('profile', junior: false, independent: true),
      'Me',
    );
  });

  test('senior school student sees Flex when eligible', () {
    final principal = SessionPrincipal.seniorSchool(flexEligible: true);
    final visible = NavCatalog.visibleFor(principal);
    expect(visible.any((d) => d.id == 'flex'), isTrue);
  });

  test('senior without flex eligibility hides Flex', () {
    final principal = SessionPrincipal.seniorSchool(flexEligible: false);
    final visible = NavCatalog.visibleFor(principal);
    expect(visible.any((d) => d.id == 'flex'), isFalse);
  });

  test('deep link to Flex falls back for independent student', () {
    final principal = SessionPrincipal.independent();
    final result = DeepLinkResolver.resolve(principal, '/flex');
    expect(result.fellBack, isTrue);
    expect(result.location, '/');
  });

  test('deep link /flex/marks lands on Flex hub for eligible senior', () {
    final principal = SessionPrincipal.seniorSchool(flexEligible: true);
    final result = DeepLinkResolver.resolve(principal, '/flex/marks');
    expect(result.fellBack, isFalse);
    expect(result.location, '/flex');
    expect(result.requestedPath, '/flex/marks');
  });

  test('deep link /flex/marks falls back for independent', () {
    final principal = SessionPrincipal.independent();
    final result = DeepLinkResolver.resolve(principal, '/flex/marks');
    expect(result.fellBack, isTrue);
    expect(result.location, '/');
  });

  test('deep link to allowed games succeeds for junior', () {
    final principal = SessionPrincipal.junior();
    final result = DeepLinkResolver.resolve(principal, '/games');
    expect(result.fellBack, isFalse);
    expect(result.location, '/games');
  });

  test('feature flag hides games destination', () {
    final principal = SessionPrincipal(
      role: AppRole.juniorStudent,
      displayName: 'Ali',
      permissions: const {'student.read'},
      featureFlags: const {'games': false},
    );
    final visible = NavCatalog.visibleFor(principal);
    expect(visible.any((d) => d.id == 'games'), isFalse);
    final result = DeepLinkResolver.resolve(principal, '/games');
    expect(result.fellBack, isTrue);
    expect(result.location, '/');
  });

  test('teacher without marks permission cannot open marks', () {
    final principal = SessionPrincipal(
      role: AppRole.teacher,
      displayName: 'Limited',
      permissions: const {'teacher.dashboard', 'teacher.classes'},
    );
    final marks = NavCatalog.teacher.firstWhere((d) => d.id == 'marks');
    expect(RouteAccess.canAccess(principal, marks), isFalse);
    final result = DeepLinkResolver.resolve(principal, '/marks');
    expect(result.fellBack, isTrue);
  });

  test('junior never sees communities even when flag is on', () {
    final principal = SessionPrincipal.junior().copyWith(
      featureFlags: const {'games': true, 'communities': true},
    );
    // Junior catalog has no communities destination.
    expect(
      NavCatalog.visibleFor(principal).any((d) => d.id == 'communities'),
      isFalse,
    );
  });

  test('senior communities destination requires feature flag', () {
    final off = SessionPrincipal.seniorSchool().copyWith(
      featureFlags: const {'games': true, 'communities': false},
    );
    expect(
      NavCatalog.visibleFor(off).any((d) => d.id == 'communities'),
      isFalse,
    );
    final on = SessionPrincipal.seniorSchool();
    expect(
      NavCatalog.visibleFor(on).any((d) => d.id == 'communities'),
      isTrue,
    );
  });

  test('unknown deep link falls back to home', () {
    final result =
        DeepLinkResolver.resolve(SessionPrincipal.junior(), '/not-a-route');
    expect(result.fellBack, isTrue);
    expect(result.location, '/');
  });

  test('notification aliases map learning and me', () {
    final learning =
        DeepLinkResolver.resolve(SessionPrincipal.seniorSchool(), '/learning');
    expect(learning.fellBack, isFalse);
    expect(learning.location, '/learning');

    final me =
        DeepLinkResolver.resolve(SessionPrincipal.seniorSchool(), '/me');
    expect(me.fellBack, isFalse);
    expect(me.location, '/profile');
  });
}
