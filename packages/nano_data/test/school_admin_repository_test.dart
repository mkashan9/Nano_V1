import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('create school rejects invalid codes and duplicates', () async {
    final repo = FakeSchoolAdminRepository();
    expect(
      () => repo.createSchool(code: 'ab', name: 'Tiny'),
      throwsStateError,
    );
    await repo.createSchool(code: 'gamma01', name: 'Gamma School');
    expect(
      () => repo.createSchool(code: 'GAMMA01', name: 'Other'),
      throwsStateError,
    );
  });

  test('status change requires a reason', () async {
    final repo = FakeSchoolAdminRepository();
    expect(
      () => repo.setStatus(
        schoolId: TenancyFixtures.alphaSchoolId,
        status: SchoolStatus.suspended,
        reason: '  ',
      ),
      throwsStateError,
    );
    final updated = await repo.setStatus(
      schoolId: TenancyFixtures.alphaSchoolId,
      status: SchoolStatus.suspended,
      reason: 'Pilot pause',
    );
    expect(updated.status, SchoolStatus.suspended);
    expect(repo.statusReasons, ['Pilot pause']);
  });

  test('first admin assign is once-only', () async {
    final repo = FakeSchoolAdminRepository();
    final assigned = await repo.assignFirstAdmin(
      schoolId: TenancyFixtures.betaSchoolId,
      userId: TenancyFixtures.schoolAdminId,
    );
    expect(assigned.hasSchoolAdmin, isTrue);
    expect(
      () => repo.assignFirstAdmin(
        schoolId: TenancyFixtures.betaSchoolId,
        userId: TenancyFixtures.teacherId,
      ),
      throwsStateError,
    );
  });
}
