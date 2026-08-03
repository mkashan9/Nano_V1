import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('loads taxonomy and school health snapshots', () async {
    final repo = FakeAnalyticsHealthRepository();
    final taxonomy = await repo.loadTaxonomy();
    expect(taxonomy, isNotEmpty);
    expect(
      taxonomy.any((e) => e.name == 'learning.topic_completed'),
      isTrue,
    );

    final alpha = await repo.loadSchoolHealth(
      schoolId: TenancyFixtures.alphaSchoolId,
    );
    expect(alpha.health.band, SchoolHealthBand.healthy);

    final platform = await repo.loadPlatformSchoolHealth();
    expect(platform, hasLength(2));
  });
}
