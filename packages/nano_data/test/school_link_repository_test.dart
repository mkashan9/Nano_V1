import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('previewInvite returns Alpha Academy for ALPHA01', () async {
    final repo = FakeSchoolLinkRepository();
    final preview = await repo.previewInvite('alpha01');
    expect(preview.schoolName, 'Alpha Academy');
    expect(preview.isLinkable, isTrue);
  });

  test('linkAccount preserves progress and upgrades principal', () async {
    final repo = FakeSchoolLinkRepository();
    final indie = SessionPrincipal.independent().copyWith(userId: 'indie-1');
    final result = await repo.linkAccount(principal: indie, code: 'ALPHA01');
    expect(result.progressPreserved, isTrue);
    expect(result.schoolCode, 'ALPHA01');
    expect(result.principal.role, AppRole.seniorStudent);
    expect(result.principal.flexEligible, isTrue);
    expect(repo.linkedUserIds, contains('indie-1'));
  });

  test('suspended invite cannot be linked', () async {
    final repo = FakeSchoolLinkRepository();
    final indie = SessionPrincipal.independent().copyWith(userId: 'indie-1');
    expect(
      () => repo.linkAccount(principal: indie, code: 'SUSP01'),
      throwsStateError,
    );
  });

  test('unknown code fails preview', () async {
    final repo = FakeSchoolLinkRepository();
    expect(repo.previewInvite('NOPE99'), throwsStateError);
  });
}
