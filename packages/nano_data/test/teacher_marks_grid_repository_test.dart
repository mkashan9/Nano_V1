import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('saves draft marks for an assessment', () async {
    final repo = FakeTeacherAssessmentRepository();
    final created = await repo.create(
      assignmentId: 'asg-1',
      input: const TeacherAssessmentDraftInput(
        category: 'Quiz',
        name: 'Chapter 1',
        assessmentDate: '2026-08-03',
        totalMarks: 20,
      ),
    );
    final assessmentId = created.assessments.first.id;
    final grid = await repo.loadMarks(assessmentId);
    expect(grid.roster, isNotEmpty);

    final saved = await repo.saveMarks(
      assessmentId: assessmentId,
      entries: [
        for (final s in grid.roster)
          MarksEntryMark(
            studentUserId: s.id,
            status: MarksEntryStatus.scored,
            obtainedMarks: 15,
          ),
      ],
    );
    expect(saved.entries, hasLength(grid.roster.length));
    expect(saved.entries.first.obtainedMarks, 15);
  });

  test('rejects over-total marks when bonus disallowed', () async {
    final repo = FakeTeacherAssessmentRepository();
    final created = await repo.create(
      assignmentId: 'asg-1',
      input: const TeacherAssessmentDraftInput(
        category: 'Quiz',
        name: 'Chapter 1',
        assessmentDate: '2026-08-03',
        totalMarks: 20,
      ),
    );
    final assessmentId = created.assessments.first.id;
    final grid = await repo.loadMarks(assessmentId);

    expect(
      () => repo.saveMarks(
        assessmentId: assessmentId,
        entries: [
          MarksEntryMark(
            studentUserId: grid.roster.first.id,
            status: MarksEntryStatus.scored,
            obtainedMarks: 25,
          ),
        ],
      ),
      throwsStateError,
    );
  });
}
