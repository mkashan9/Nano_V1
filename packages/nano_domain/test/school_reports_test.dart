import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('parses privacy-safe school reports summary', () {
    final summary = SchoolReportsSummary.fromJson({
      'school_id': TenancyFixtures.alphaSchoolId,
      'learner_count': 30,
      'teacher_count': 3,
      'staff_count': 1,
      'class_count': 4,
      'subject_count': 6,
      'class_subject_count': 8,
      'uncovered_class_subject_count': 2,
      'active_assignment_count': 5,
      'teachers_with_assignment_count': 2,
      'students_with_class_count': 25,
      'students_without_class_count': 5,
      'open_period_count': 1,
      'closed_period_count': 0,
      'passing_percent': 40,
      'attendance_mode': 'daily',
      'report_card_format': 'both',
      'teacher_workload': [
        {'display_name': 'Ms. Khan', 'active_count': 3},
      ],
      'generated_at': '2026-08-02T00:00:00Z',
    });
    expect(summary.hasCoverageGap, isTrue);
    expect(summary.teacherWorkload.single.activeCount, 3);
    expect(
      () => SchoolReportsSummary.fromJson({
        'school_id': TenancyFixtures.alphaSchoolId,
        'email': 'secret@example.com',
        'learner_count': 1,
      }),
      throwsStateError,
    );
  });
}
