import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('parses assignment matrix coverage and workload', () {
    final matrix = TeacherAssignmentMatrix.fromJson({
      'school_id': TenancyFixtures.alphaSchoolId,
      'assignments': [
        {
          'id': 'asg-1',
          'teacher_user_id': TenancyFixtures.teacherId,
          'teacher_name': 'Ms. Khan',
          'class_id': 'class-5a',
          'section_id': null,
          'school_subject_id': 'subj-math',
          'class_label': '5-A',
          'section_name': '',
          'subject_code': 'MATH',
          'subject_name': 'Mathematics',
          'status': 'active',
          'starts_on': '2026-08-01',
          'ends_on': null,
        },
      ],
      'teachers': [
        {'id': TenancyFixtures.teacherId, 'display_name': 'Ms. Khan'},
      ],
      'classes': [
        {'id': 'class-5a', 'name': '5-A'},
      ],
      'sections': [],
      'subjects': [
        {'id': 'subj-math', 'name': 'Mathematics', 'code': 'MATH'},
      ],
      'uncovered': [
        {
          'class_id': 'class-5a',
          'class_name': '5-A',
          'section_id': null,
          'section_name': null,
          'school_subject_id': 'subj-eng',
          'subject_code': 'ENG',
          'subject_name': 'English',
        },
      ],
      'conflicts': [],
      'workload': [
        {
          'teacher_user_id': TenancyFixtures.teacherId,
          'display_name': 'Ms. Khan',
          'active_count': 1,
        },
      ],
    });

    expect(matrix.activeAssignments, hasLength(1));
    expect(matrix.uncovered.single.label, contains('ENG'));
    expect(matrix.workload.single.activeCount, 1);
  });
}
