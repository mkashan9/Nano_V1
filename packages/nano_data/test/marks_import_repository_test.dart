import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('previews and commits marks csv import', () async {
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
    final template = await repo.loadMarksTemplate(assessmentId);
    expect(template.rows, isNotEmpty);

    final rows = MarksImportCsv.parse(template.csvText);
    for (final row in rows) {
      row['status'] = 'scored';
      row['obtained_marks'] = '15';
    }

    final preview = await repo.previewMarksImport(
      assessmentId: assessmentId,
      idempotencyKey: 'import-key-1',
      rows: rows,
    );
    expect(preview.canCommit, isTrue);

    final committed = await repo.commitMarksImport(
      assessmentId: assessmentId,
      idempotencyKey: 'import-key-1',
      rows: rows,
    );
    expect(committed.committed, isTrue);
    expect(committed.grid.entries, isNotEmpty);
    expect(committed.grid.entries.first.obtainedMarks, 15);
  });
}
