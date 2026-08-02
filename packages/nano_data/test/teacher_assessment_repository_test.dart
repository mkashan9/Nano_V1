import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('creates and updates draft assessments', () async {
    final repo = FakeTeacherAssessmentRepository();
    final created = await repo.create(
      assignmentId: 'asg-1',
      input: const TeacherAssessmentDraftInput(
        category: 'Quiz',
        name: 'Chapter 1',
        assessmentDate: '2026-08-03',
        totalMarks: 20,
        weight: 1,
        description: 'Warm-up',
      ),
    );
    expect(created.assessments, hasLength(1));
    expect(created.assessments.first.isDraft, isTrue);

    final updated = await repo.update(
      assessmentId: created.assessments.first.id,
      input: const TeacherAssessmentDraftInput(
        category: 'Homework',
        name: 'Chapter 1b',
        assessmentDate: '2026-08-04',
        totalMarks: 25,
      ),
    );
    expect(updated.assessments.first.category, 'Homework');
    expect(updated.assessments.first.name, 'Chapter 1b');
    expect(updated.assessments.first.totalMarks, 25);
  });

  test('rejects invalid draft input', () async {
    final repo = FakeTeacherAssessmentRepository();
    expect(
      () => repo.create(
        assignmentId: 'asg-1',
        input: const TeacherAssessmentDraftInput(
          category: '',
          name: 'X',
          assessmentDate: '2026-08-03',
          totalMarks: 10,
        ),
      ),
      throwsStateError,
    );
    expect(
      () => repo.create(
        assignmentId: 'asg-1',
        input: const TeacherAssessmentDraftInput(
          category: 'Quiz',
          name: 'X',
          assessmentDate: '2026-08-03',
          totalMarks: 0,
        ),
      ),
      throwsStateError,
    );
  });
}
