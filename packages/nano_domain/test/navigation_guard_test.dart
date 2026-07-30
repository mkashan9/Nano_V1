import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('independent student never sees Flex destination', () {
    final principal = SessionPrincipal.independent();
    final visible = NavCatalog.visibleFor(principal);
    expect(visible.any((d) => d.id == 'flex'), isFalse);
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

  test('unknown deep link falls back to home', () {
    final result =
        DeepLinkResolver.resolve(SessionPrincipal.junior(), '/not-a-route');
    expect(result.fellBack, isTrue);
    expect(result.location, '/');
  });
}
