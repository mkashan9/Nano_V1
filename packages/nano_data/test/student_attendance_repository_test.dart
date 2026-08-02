import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('filters attendance to requested month', () async {
    final repo = FakeStudentAttendanceRepository();
    final august = await repo.loadMine(
      from: DateTime.utc(2026, 8, 1),
      to: DateTime.utc(2026, 8, 31),
    );
    expect(august.recordedDays, 2);
    expect(august.presentCount, 1);
    expect(august.lateCount, 1);

    final july = await repo.loadMine(
      from: DateTime.utc(2026, 7, 1),
      to: DateTime.utc(2026, 7, 31),
    );
    expect(july.recordedDays, 1);
    expect(july.absentCount, 1);
  });
}
