import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('parses attendance grid and cycles status', () {
    final grid = TeacherAttendanceGrid.fromJson({
      'assignment_id': 'asg-1',
      'school_id': TenancyFixtures.alphaSchoolId,
      'session_date': '2026-08-02',
      'period_key': 'daily',
      'attendance_mode': 'daily',
      'class_label': '5-A',
      'subject_code': 'MATH',
      'roster': [
        {'id': TenancyFixtures.aliAlphaId, 'display_name': 'Ali Khan'},
      ],
      'entries': [
        {
          'student_user_id': TenancyFixtures.aliAlphaId,
          'status': 'late',
        },
      ],
    });
    expect(grid.scopeLabel, '5-A · MATH');
    expect(grid.statusByStudent[TenancyFixtures.aliAlphaId],
        AttendanceEntryStatus.late);
    expect(AttendanceEntryStatus.present.next, AttendanceEntryStatus.absent);
  });
}
