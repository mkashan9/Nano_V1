import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('parses student attendance summary', () {
    final summary = StudentAttendanceSummary.fromJson({
      'from': '2026-08-01',
      'to': '2026-08-31',
      'present_count': 1,
      'absent_count': 0,
      'late_count': 1,
      'leave_count': 0,
      'excused_count': 0,
      'days': [
        {
          'session_date': '2026-08-02',
          'status': 'late',
          'subject_code': 'MATH',
          'class_label': '5-A',
        },
        {
          'session_date': '2026-08-01',
          'status': 'present',
          'subject_code': 'MATH',
          'class_label': '5-A',
        },
      ],
    });
    expect(summary.recordedDays, 2);
    expect(summary.days.first.status, AttendanceEntryStatus.late);
    expect(summary.presentCount, 1);
  });
}
