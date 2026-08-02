import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('composed hub uses live section counts without fixture badges', () async {
    final attendance = FakeStudentAttendanceRepository(
      seed: [
        StudentAttendanceDay(
          sessionDate: DateTime.utc(2026, 8, 1),
          status: AttendanceEntryStatus.present,
        ),
        StudentAttendanceDay(
          sessionDate: DateTime.utc(2026, 8, 2),
          status: AttendanceEntryStatus.absent,
        ),
      ],
    );
    final marks = FakeStudentMarksRepository(
      seed: [
        StudentMarksResult(
          assessmentId: 'a1',
          entryId: 'e1',
          name: 'Quiz 1',
          category: 'quiz',
          assessmentDate: DateTime.utc(2026, 8, 1),
          assessmentStatus: AssessmentStatus.published,
          entryStatus: MarksEntryStatus.scored,
          totalMarks: 10,
          obtainedMarks: 8,
        ),
      ],
    );
    final classroom = FakeStudentClassroomRepository();
    final hub = await ComposedStudentFlexRepository(
      attendance: attendance,
      marks: marks,
      classroom: classroom,
    ).loadHub(flexEligible: true);

    expect(hub.sections, hasLength(3));
    expect(
      hub.sections.firstWhere((s) => s.kind == FlexHubSectionKind.attendance).openCount,
      2,
    );
    expect(
      hub.sections.firstWhere((s) => s.kind == FlexHubSectionKind.marks).openCount,
      1,
    );
    expect(
      hub.sections
          .firstWhere((s) => s.kind == FlexHubSectionKind.classroom)
          .nextDueLabel,
      'Acknowledge',
    );
    expect(
      hub.sections.any((s) => s.nextDueLabel == 'Due Friday'),
      isFalse,
    );
  });
}
