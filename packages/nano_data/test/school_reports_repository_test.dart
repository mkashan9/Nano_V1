import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';

void main() {
  test('loads school reports summary', () async {
    final repo = FakeSchoolReportsRepository();
    final summary = await repo.load();
    expect(summary.learnerCount, greaterThan(0));
    expect(summary.teacherWorkload, isNotEmpty);

    repo.alwaysFail = true;
    expect(repo.load, throwsStateError);
  });
}
