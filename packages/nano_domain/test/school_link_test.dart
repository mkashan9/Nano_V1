import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('SchoolLinkPolicy', () {
    test('normalizes and validates codes', () {
      expect(SchoolLinkPolicy.normalizeCode(' alpha01 '), 'ALPHA01');
      expect(SchoolLinkPolicy.looksLikeCode('AB'), isFalse);
      expect(SchoolLinkPolicy.looksLikeCode('ALPHA01'), isTrue);
    });

    test('only independents without a school may preview', () {
      expect(
        SchoolLinkPolicy.canPreview(
          role: AppRole.independentStudent,
          schoolId: null,
        ).allowed,
        isTrue,
      );
      expect(
        SchoolLinkPolicy.canPreview(
          role: AppRole.seniorStudent,
          schoolId: null,
        ).reason,
        SchoolLinkDenial.notIndependent,
      );
      expect(
        SchoolLinkPolicy.canPreview(
          role: AppRole.independentStudent,
          schoolId: 'school',
        ).reason,
        SchoolLinkDenial.alreadyLinked,
      );
    });

    test('suspended schools cannot be linked', () {
      const preview = SchoolInvitePreview(
        code: 'SUSP01',
        schoolId: 's1',
        schoolName: 'Paused',
        schoolStatus: SchoolStatus.suspended,
      );
      expect(
        SchoolLinkPolicy.canLink(
          role: AppRole.independentStudent,
          schoolId: null,
          preview: preview,
        ).reason,
        SchoolLinkDenial.schoolUnavailable,
      );
    });

    test('linkedPrincipal upgrades to school senior with Flex', () {
      final indie = SessionPrincipal.independent().copyWith(userId: 'u1');
      final linked = SchoolLinkPolicy.linkedPrincipal(
        indie,
        schoolId: TenancyFixtures.alphaSchoolId,
      );
      expect(linked.role, AppRole.seniorStudent);
      expect(linked.schoolId, TenancyFixtures.alphaSchoolId);
      expect(linked.flexEligible, isTrue);
      expect(linked.userId, 'u1');
    });
  });
}
