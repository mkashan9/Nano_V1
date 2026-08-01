import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';

void main() {
  test('loads and updates branding', () async {
    final repo = FakeSchoolDashboardRepository();
    final loaded = await repo.load();
    expect(loaded.code, 'ALPHA01');

    final updated = await repo.updateBranding(
      displayName: 'Alpha Prep',
      primaryColor: '#112233',
      contactEmail: 'hello@alpha.example',
      markSetupComplete: true,
    );
    expect(updated.displayName, 'Alpha Prep');
    expect(updated.primaryColor, '#112233');
    expect(updated.setup.setupCompleted, isTrue);
    expect(repo.updateCount, 1);
  });

  test('rejects invalid brand color', () async {
    final repo = FakeSchoolDashboardRepository();
    expect(
      () => repo.updateBranding(primaryColor: 'blue'),
      throwsStateError,
    );
  });
}
