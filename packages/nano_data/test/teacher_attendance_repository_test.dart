import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('loads and submits attendance idempotently', () async {
    final repo = FakeTeacherAttendanceRepository();
    final grid = await repo.load(
      assignmentId: 'asg-1',
      sessionDate: '2026-08-02',
    );
    expect(grid.roster, isNotEmpty);

    final marks = [
      for (final s in grid.roster)
        AttendanceEntryMark(
          studentUserId: s.id,
          status: AttendanceEntryStatus.present,
        ),
    ];
    final submitted = await repo.submit(
      assignmentId: 'asg-1',
      sessionDate: '2026-08-02',
      idempotencyKey: 'key-1',
      entries: marks,
    );
    expect(submitted.isSubmitted, isTrue);

    final again = await repo.submit(
      assignmentId: 'asg-1',
      sessionDate: '2026-08-02',
      idempotencyKey: 'key-1',
      entries: marks,
    );
    expect(again.session?.idempotencyKey, 'key-1');

    expect(
      () => repo.submit(
        assignmentId: 'asg-1',
        sessionDate: '2026-08-02',
        idempotencyKey: 'key-2',
        entries: marks,
      ),
      throwsStateError,
    );
  });
}
