import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';

void main() {
  test('loads teacher dashboard fake seed', () async {
    final repo = FakeTeacherDashboardRepository();
    final dashboard = await repo.load();
    expect(dashboard.activeAssignmentCount, 2);
    expect(dashboard.assignments, hasLength(2));

    repo.alwaysFail = true;
    expect(repo.load, throwsStateError);
  });
}
