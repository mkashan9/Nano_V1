import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';

void main() {
  test('filters marks to requested month', () async {
    final repo = FakeStudentMarksRepository();
    final august = await repo.loadMine(
      from: DateTime.utc(2026, 8, 1),
      to: DateTime.utc(2026, 8, 31),
    );
    expect(august.recordedCount, 2);
    expect(august.scoredCount, 2);

    final july = await repo.loadMine(
      from: DateTime.utc(2026, 7, 1),
      to: DateTime.utc(2026, 7, 31),
    );
    expect(july.recordedCount, 1);
    expect(july.absentCount, 1);
  });
}
