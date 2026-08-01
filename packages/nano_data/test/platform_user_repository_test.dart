import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('suspend and restore require a reason', () async {
    final repo = FakePlatformUserRepository();
    expect(
      () => repo.setProfileStatus(
        userId: TenancyFixtures.aliAlphaId,
        status: MembershipStatus.suspended,
        reason: '  ',
      ),
      throwsStateError,
    );
    final suspended = await repo.setProfileStatus(
      userId: TenancyFixtures.aliAlphaId,
      status: MembershipStatus.suspended,
      reason: 'Abuse report',
    );
    expect(suspended.isSuspended, isTrue);
    expect(repo.statusReasons, ['Abuse report']);
  });

  test('replace admin demotes prior admin membership', () async {
    final repo = FakePlatformUserRepository();
    await repo.replaceSchoolAdmin(
      schoolId: TenancyFixtures.alphaSchoolId,
      newUserId: TenancyFixtures.teacherId,
      reason: 'Handover',
    );
    expect(repo.replaceReasons, ['Handover']);
    final users = await repo.search();
    final prior = users.firstWhere((u) => u.id == TenancyFixtures.schoolAdminId);
    final next = users.firstWhere((u) => u.id == TenancyFixtures.teacherId);
    expect(
      prior.schoolSummaries.any(
        (s) =>
            s.role == MembershipRole.schoolAdmin &&
            s.status == MembershipStatus.left,
      ),
      isTrue,
    );
    expect(
      next.schoolSummaries.any(
        (s) =>
            s.role == MembershipRole.schoolAdmin &&
            s.status == MembershipStatus.active,
      ),
      isTrue,
    );
  });

  test('revoke sessions clears active count', () async {
    final repo = FakePlatformUserRepository();
    final count = await repo.revokeSessions(
      userId: TenancyFixtures.aliAlphaId,
      reason: 'Lost device',
    );
    expect(count, 1);
    final users = await repo.search(query: 'Ali');
    expect(users.single.activeSessionCount, 0);
    expect(repo.revokeReasons, ['Lost device']);
  });
}
