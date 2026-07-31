import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('AccessGuard', () {
    test('allows active school membership with permission', () {
      final decision = AccessGuard.evaluate(
        schoolStatus: SchoolStatus.active,
        membershipStatus: MembershipStatus.active,
        profileStatus: MembershipStatus.active,
        sessionRevoked: false,
        requiredPermission: 'student.read',
        permissions: {'student.read'},
      );
      expect(decision.allowed, isTrue);
    });

    test('denies suspended school', () {
      final decision = AccessGuard.evaluate(
        schoolStatus: SchoolStatus.suspended,
        membershipStatus: MembershipStatus.active,
        profileStatus: MembershipStatus.active,
        sessionRevoked: false,
      );
      expect(decision.reason, AccessDenialReason.schoolSuspended);
    });

    test('denies revoked session', () {
      final decision = AccessGuard.evaluate(
        schoolStatus: SchoolStatus.active,
        membershipStatus: MembershipStatus.active,
        profileStatus: MembershipStatus.active,
        sessionRevoked: true,
      );
      expect(decision.reason, AccessDenialReason.sessionRevoked);
    });

    test('fixture sessions match seed ids', () {
      expect(SecurityFixtures.activeSession.isActive, isTrue);
      expect(SecurityFixtures.revokedSession.isActive, isFalse);
    });
  });
}
