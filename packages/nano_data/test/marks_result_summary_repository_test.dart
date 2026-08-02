import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('loads result summary after publish', () async {
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
    await repo.saveMarks(
      assessmentId: assessmentId,
      entries: [
        for (final s in grid.roster)
          MarksEntryMark(
            studentUserId: s.id,
            status: MarksEntryStatus.scored,
            obtainedMarks: 16,
          ),
      ],
    );
    await repo.publishMarks(assessmentId: assessmentId);

    final summary = await repo.loadResultSummary(assessmentId);
    expect(summary.scoredCount, grid.roster.length);
    expect(summary.averagePercent, 80);
    expect(summary.passCount, grid.roster.length);
    expect(summary.students, isNotEmpty);
  });

  test('rejects draft summary', () async {
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
    expect(
      () => repo.loadResultSummary(created.assessments.first.id),
      throwsStateError,
    );
  });
}
