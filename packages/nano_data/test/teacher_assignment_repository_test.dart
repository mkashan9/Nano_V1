import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('assigns ends and surfaces uncovered workload', () async {
    final repo = FakeTeacherAssignmentRepository();
    final loaded = await repo.load();
    expect(loaded.activeAssignments, isNotEmpty);
    expect(loaded.uncovered, isNotEmpty);

    final assigned = await repo.assign(
      teacherUserId: 'teacher-2',
      classId: 'class-5a',
      schoolSubjectId: 'subj-eng',
    );
    expect(assigned.activeAssignments.length, greaterThan(loaded.activeAssignments.length));
    expect(repo.assignCount, 1);

    final ended = await repo.end(
      assignmentId: assigned.activeAssignments.first.id,
      reason: 'Schedule change',
    );
    expect(ended.assignments.any((a) => a.status == 'left'), isTrue);
    expect(repo.endReasons, ['Schedule change']);

    expect(
      () => repo.end(assignmentId: 'missing', reason: 'x'),
      throwsStateError,
    );
  });
}
