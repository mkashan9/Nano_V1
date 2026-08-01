import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';

void main() {
  test('fake analytics loads seed metrics', () async {
    final repo = FakePlatformAnalyticsRepository();
    final snap = await repo.load();
    expect(snap.activeSchoolCount, 2);
    expect(snap.actionBreakdown7d, isNotEmpty);
  });

  test('fake analytics can fail', () async {
    final repo = FakePlatformAnalyticsRepository()..alwaysFail = true;
    expect(repo.load, throwsStateError);
  });
}
