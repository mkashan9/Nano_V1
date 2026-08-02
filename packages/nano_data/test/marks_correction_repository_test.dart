import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('publishes draft marks and corrects with history', () async {
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
    final studentId = grid.roster.first.id;

    await repo.saveMarks(
      assessmentId: assessmentId,
      idempotencyKey: 'save-1',
      entries: [
        for (final s in grid.roster)
          MarksEntryMark(
            studentUserId: s.id,
            status: MarksEntryStatus.scored,
            obtainedMarks: 15,
          ),
      ],
    );

    final published = await repo.publishMarks(assessmentId: assessmentId);
    expect(published.assessmentStatus, AssessmentStatus.published);

    final result = await repo.correctMarks(
      assessmentId: assessmentId,
      studentUserId: studentId,
      newStatus: MarksEntryStatus.absent,
      reason: 'Parent called in sick',
    );

    expect(result.corrected, isTrue);
    expect(result.grid.assessmentStatus, AssessmentStatus.corrected);
    expect(
      result.grid.entryByStudent[studentId]?.status,
      MarksEntryStatus.absent,
    );
    expect(result.history.corrections, hasLength(1));
    expect(result.history.corrections.first.reason, 'Parent called in sick');
  });

  test('requires reason and rejects unchanged correction', () async {
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
    final studentId = grid.roster.first.id;
    await repo.saveMarks(
      assessmentId: assessmentId,
      entries: [
        MarksEntryMark(
          studentUserId: studentId,
          status: MarksEntryStatus.scored,
          obtainedMarks: 10,
        ),
      ],
    );
    await repo.publishMarks(assessmentId: assessmentId);

    expect(
      () => repo.correctMarks(
        assessmentId: assessmentId,
        studentUserId: studentId,
        newStatus: MarksEntryStatus.absent,
        reason: '   ',
      ),
      throwsStateError,
    );
    expect(
      () => repo.correctMarks(
        assessmentId: assessmentId,
        studentUserId: studentId,
        newStatus: MarksEntryStatus.scored,
        obtainedMarks: 10,
        reason: 'noop',
      ),
      throwsStateError,
    );
  });
}
