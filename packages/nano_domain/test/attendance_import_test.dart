import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('parses attendance csv by stable student ids', () {
    final rows = AttendanceImportCsv.parse('''
student_user_id,display_name,status
aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa,Ali Khan,absent
bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb,Sara,late
''');
    expect(rows, hasLength(2));
    expect(rows.first['student_user_id'], TenancyFixtures.aliAlphaId);
    expect(rows.first['status'], 'absent');
  });

  test('builds csv template text', () {
    final template = AttendanceImportTemplate(
      assignmentId: 'asg-1',
      sessionDate: '2026-08-02',
      periodKey: 'daily',
      classLabel: '5-A',
      subjectCode: 'MATH',
      headers: const ['student_user_id', 'display_name', 'status'],
      rows: const [
        {
          'student_user_id': TenancyFixtures.aliAlphaId,
          'display_name': 'Ali Khan',
          'status': 'present',
        },
      ],
    );
    expect(template.csvText, contains('student_user_id,display_name,status'));
    expect(template.csvText, contains(TenancyFixtures.aliAlphaId));
  });
}
