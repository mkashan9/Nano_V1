import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('parses attendance correction history and result', () {
    final history = AttendanceCorrectionHistory.fromJson({
      'assignment_id': 'asg-1',
      'session_id': 'sess-1',
      'session_date': '2026-08-03',
      'period_key': 'daily',
      'corrections': [
        {
          'id': 'corr-1',
          'session_id': 'sess-1',
          'student_user_id': 'stu-1',
          'display_name': 'Ali Khan',
          'previous_status': 'present',
          'new_status': 'absent',
          'reason': 'Late arrival noted',
          'corrected_by': 'tch-1',
          'corrected_by_name': 'Teacher',
          'corrected_at': '2026-08-02T12:00:00Z',
          'revision_before': 1,
          'revision_after': 2,
        },
      ],
    });

    expect(history.corrections, hasLength(1));
    expect(history.corrections.first.previousStatus,
        AttendanceEntryStatus.present);
    expect(history.corrections.first.newStatus, AttendanceEntryStatus.absent);
    expect(history.corrections.first.reason, 'Late arrival noted');
  });
}
