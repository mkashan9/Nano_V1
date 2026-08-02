import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('parses my classes and roster without email fields', () {
    final mine = TeacherMyClasses.fromJson({
      'school_id': TenancyFixtures.alphaSchoolId,
      'teacher_id': TenancyFixtures.teacherId,
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
    });
    expect(mine.assignments, hasLength(1));

    final roster = TeacherClassRoster.fromJson({
      'assignment_id': 'asg-1',
      'school_id': TenancyFixtures.alphaSchoolId,
      'class_label': '5-A',
      'section_name': '',
      'subject_code': 'MATH',
      'subject_name': 'Mathematics',
      'student_count': 1,
      'students': [
        {
          'id': TenancyFixtures.aliAlphaId,
          'display_name': 'Ali Khan',
          'enrollment_status': 'active',
        },
      ],
    });
    expect(roster.scopeLabel, '5-A · MATH');
    expect(roster.students.single.displayName, 'Ali Khan');
  });
}
