import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';

void main() {
  test('fake dashboard filters schools by query', () async {
    final repo = FakePlatformDashboardRepository();
    final all = await repo.load();
    expect(all.schools, hasLength(2));
    final filtered = await repo.load(query: 'beta');
    expect(filtered.schools, hasLength(1));
    expect(filtered.schools.single.code, 'BETA');
  });

  test('fake dashboard can fail closed', () async {
    final repo = FakePlatformDashboardRepository()..alwaysFail = true;
    expect(repo.load(), throwsStateError);
  });
}
