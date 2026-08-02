import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('corrects submitted attendance and keeps history', () async {
    final repo = FakeTeacherAttendanceRepository();
    final grid = await repo.load(
      assignmentId: 'asg-1',
      sessionDate: '2026-08-03',
    );
    final studentId = grid.roster.first.id;
    final submitted = await repo.submit(
      assignmentId: 'asg-1',
      sessionDate: '2026-08-03',
      idempotencyKey: 'key-1',
      entries: [
        for (final s in grid.roster)
          AttendanceEntryMark(
            studentUserId: s.id,
            status: AttendanceEntryStatus.present,
          ),
      ],
    );
    expect(submitted.isSubmitted, isTrue);

    final result = await repo.correct(
      assignmentId: 'asg-1',
      sessionDate: '2026-08-03',
      studentUserId: studentId,
      newStatus: AttendanceEntryStatus.absent,
      reason: 'Parent called in sick',
    );

    expect(result.corrected, isTrue);
    expect(result.grid.statusByStudent[studentId], AttendanceEntryStatus.absent);
    expect(result.history.corrections, hasLength(1));
    expect(result.history.corrections.first.previousStatus,
        AttendanceEntryStatus.present);
    expect(result.history.corrections.first.reason, 'Parent called in sick');

    final history = await repo.loadHistory(
      assignmentId: 'asg-1',
      sessionDate: '2026-08-03',
    );
    expect(history.corrections, hasLength(1));
  });

  test('requires reason and rejects unchanged status', () async {
    final repo = FakeTeacherAttendanceRepository();
    final grid = await repo.load(
      assignmentId: 'asg-1',
      sessionDate: '2026-08-03',
    );
    final studentId = grid.roster.first.id;
    await repo.submit(
      assignmentId: 'asg-1',
      sessionDate: '2026-08-03',
      idempotencyKey: 'key-2',
      entries: [
        for (final s in grid.roster)
          AttendanceEntryMark(
            studentUserId: s.id,
            status: AttendanceEntryStatus.present,
          ),
      ],
    );

    expect(
      () => repo.correct(
        assignmentId: 'asg-1',
        sessionDate: '2026-08-03',
        studentUserId: studentId,
        newStatus: AttendanceEntryStatus.absent,
        reason: '   ',
      ),
      throwsStateError,
    );
    expect(
      () => repo.correct(
        assignmentId: 'asg-1',
        sessionDate: '2026-08-03',
        studentUserId: studentId,
        newStatus: AttendanceEntryStatus.present,
        reason: 'noop',
      ),
      throwsStateError,
    );
  });
}
