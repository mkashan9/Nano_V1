import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';

void main() {
  test('saves policy and closes period with reason', () async {
    final repo = FakeSchoolMarksPolicyRepository();
    final saved = await repo.save(
      attendanceMode: 'session',
      passingPercent: 50,
      allowBonus: true,
      reportCardFormat: 'percent',
    );
    expect(saved.attendanceMode, 'session');
    expect(saved.passingPercent, 50);
    expect(repo.saveCount, 1);

    final created = await repo.createPeriod(name: 'Final');
    expect(created.periods.any((p) => p.name == 'Final'), isTrue);

    final closed = await repo.closePeriod(
      periodId: created.periods.last.id,
      reason: 'Year end',
    );
    expect(closed.periods.last.status, 'closed');
    expect(repo.closeReasons, ['Year end']);
  });
}
