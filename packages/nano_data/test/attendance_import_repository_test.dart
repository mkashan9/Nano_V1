import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('previews and commits attendance csv import', () async {
    final repo = FakeTeacherAttendanceRepository();
    final template = await repo.loadTemplate(
      assignmentId: 'asg-1',
      sessionDate: '2026-08-03',
    );
    expect(template.rows, isNotEmpty);

    final rows = AttendanceImportCsv.parse(template.csvText);
    final preview = await repo.previewImport(
      assignmentId: 'asg-1',
      sessionDate: '2026-08-03',
      idempotencyKey: 'import-key-1',
      rows: rows,
    );
    expect(preview.canCommit, isTrue);

    final committed = await repo.commitImport(
      assignmentId: 'asg-1',
      sessionDate: '2026-08-03',
      idempotencyKey: 'import-key-1',
      rows: rows,
    );
    expect(committed.committed, isTrue);
    expect(committed.grid.isSubmitted, isTrue);
  });
}
