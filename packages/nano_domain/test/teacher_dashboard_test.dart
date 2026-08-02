import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('parses teacher dashboard with assignment scopes', () {
    final dashboard = TeacherDashboard.fromJson({
      'school_id': TenancyFixtures.alphaSchoolId,
      'school_code': 'ALPHA01',
      'school_name': 'Alpha Academy',
      'teacher_id': TenancyFixtures.teacherId,
      'teacher_name': 'Ms. Khan',
      'active_assignment_count': 1,
      'pending_attendance_count': 0,
      'draft_assessment_count': 0,
      'unpublished_marks_count': 0,
      'recent_classroom_count': 0,
      'assignments': [
        {
          'id': 'asg-1',
          'class_label': '5-A',
          'section_name': '',
          'subject_code': 'MATH',
          'subject_name': 'Mathematics',
          'status': 'active',
        },
      ],
      'generated_at': '2026-08-02T00:00:00Z',
    });

    expect(dashboard.activeAssignmentCount, 1);
    expect(dashboard.pendingTotal, 0);
    expect(dashboard.assignments.single.scopeLabel, '5-A · MATH');
  });
}
