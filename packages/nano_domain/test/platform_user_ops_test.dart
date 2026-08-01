import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('platform user summary rejects privacy fields', () {
    expect(
      () => PlatformUserSummary.fromJson({
        'id': TenancyFixtures.aliAlphaId,
        'display_name': 'Ali',
        'account_kind': 'school_student',
        'status': 'active',
        'email': 'ali@example.com',
      }),
      throwsStateError,
    );
  });

  test('platform user summary parses schools and status', () {
    final user = PlatformUserSummary.fromJson({
      'id': TenancyFixtures.schoolAdminId,
      'display_name': 'Alpha Admin',
      'account_kind': 'school_staff',
      'status': 'suspended',
      'active_session_count': 2,
      'schools': [
        {
          'school_id': TenancyFixtures.alphaSchoolId,
          'school_code': 'ALPHA01',
          'role': 'school_admin',
          'status': 'active',
        },
      ],
    });
    expect(user.isSuspended, isTrue);
    expect(user.activeSessionCount, 2);
    expect(user.schoolSummaries.single.role, MembershipRole.schoolAdmin);
    expect(MembershipStatus.active.wireName, 'active');
  });
}
