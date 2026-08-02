import 'package:nano_domain/nano_domain.dart';

import 'student_attendance_repository.dart';
import 'student_classroom_repository.dart';
import 'student_marks_repository.dart';

/// FLX-01 Flex hub for school-linked students.
abstract class StudentFlexRepository {
  Future<FlexHubSummary> loadHub({required bool flexEligible});
}

class FakeStudentFlexRepository implements StudentFlexRepository {
  FakeStudentFlexRepository({
    FlexHubSummary? seed,
    this.alwaysFail = false,
  }) : _seed = seed;

  FlexHubSummary? _seed;
  var alwaysFail;

  @override
  Future<FlexHubSummary> loadHub({required bool flexEligible}) async {
    if (alwaysFail) throw StateError('Flex unavailable');
    if (!flexEligible) {
      throw StateError('Flex is not available for this account.');
    }
    return _seed ??
        FlexHubSummary(
          updatedAt: DateTime.utc(2026, 8, 2, 7),
          sections: const [
            FlexHubSection(
              kind: FlexHubSectionKind.attendance,
              openCount: 1,
              nextDueLabel: 'Today',
            ),
            FlexHubSection(
              kind: FlexHubSectionKind.marks,
              openCount: 1,
              nextDueLabel: 'Due Friday',
            ),
            FlexHubSection(
              kind: FlexHubSectionKind.classroom,
              openCount: 1,
              nextDueLabel: 'New announcement',
            ),
          ],
        );
  }
}

/// Live hub counts from FLX-02/03/04 repositories (no fixture badges).
class ComposedStudentFlexRepository implements StudentFlexRepository {
  ComposedStudentFlexRepository({
    required StudentAttendanceRepository attendance,
    required StudentMarksRepository marks,
    required StudentClassroomRepository classroom,
  })  : _attendance = attendance,
        _marks = marks,
        _classroom = classroom;

  final StudentAttendanceRepository _attendance;
  final StudentMarksRepository _marks;
  final StudentClassroomRepository _classroom;

  @override
  Future<FlexHubSummary> loadHub({required bool flexEligible}) async {
    if (!flexEligible) {
      throw StateError('Flex is not available for this account.');
    }
    final now = DateTime.now().toUtc();
    final from = DateTime.utc(now.year, now.month, 1);
    final to = DateTime.utc(now.year, now.month + 1, 0);

    StudentAttendanceSummary? attendance;
    StudentMarksSummary? marks;
    StudentClassroomFeed? classroom;
    try {
      attendance = await _attendance.loadMine(from: from, to: to);
    } catch (_) {}
    try {
      marks = await _marks.loadMine(from: from, to: to);
    } catch (_) {}
    try {
      classroom = await _classroom.loadFeed();
    } catch (_) {}

    final pendingAck = classroom?.pendingAckCount ?? 0;
    return FlexHubSummary(
      updatedAt: now,
      sections: [
        FlexHubSection(
          kind: FlexHubSectionKind.attendance,
          openCount: attendance?.recordedDays ?? 0,
          nextDueLabel: null,
        ),
        FlexHubSection(
          kind: FlexHubSectionKind.marks,
          openCount: marks?.recordedCount ?? 0,
          nextDueLabel: null,
        ),
        FlexHubSection(
          kind: FlexHubSectionKind.classroom,
          openCount: pendingAck,
          nextDueLabel: pendingAck > 0 ? 'Acknowledge' : null,
        ),
      ],
    );
  }
}
