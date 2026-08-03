import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('CommunityEntitlements and policies parse JSON', () {
    final entitlements = CommunityEntitlements.fromJson({
      'communities_enabled': true,
      'platform_enabled': true,
      'school_enabled': true,
      'junior_blocked': false,
      'reason': 'ok',
    });
    expect(entitlements.communitiesEnabled, isTrue);
    expect(entitlements.reason, 'ok');

    final platform = PlatformCommunityPolicy.fromJson({
      'communities_enabled': false,
      'updated_at': '2026-08-02T12:00:00Z',
      'updated_by': 'user-1',
    });
    expect(platform.communitiesEnabled, isFalse);
    expect(platform.updatedBy, 'user-1');

    final school = SchoolCommunityPolicy.fromJson({
      'school_id': TenancyFixtures.alphaSchoolId,
      'school_name': 'Alpha',
      'communities_enabled': true,
    });
    expect(school.schoolId, TenancyFixtures.alphaSchoolId);
    expect(school.communitiesEnabled, isTrue);
  });
}
