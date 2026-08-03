import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('FakeCommunityControlsRepository toggles platform and school', () async {
    final repo = FakeCommunityControlsRepository();
    expect((await repo.loadPlatformPolicy()).communitiesEnabled, isFalse);

    final platform = await repo.savePlatformPolicy(enabled: true);
    expect(platform.communitiesEnabled, isTrue);

    final school = await repo.saveSchoolPolicy(
      schoolId: TenancyFixtures.alphaSchoolId,
      enabled: true,
    );
    expect(school.communitiesEnabled, isTrue);
    expect(
      (await repo.loadSchoolPolicy(TenancyFixtures.alphaSchoolId))
          .communitiesEnabled,
      isTrue,
    );

    final listed = await repo.listSchoolPolicies();
    expect(listed, isNotEmpty);
  });
}
