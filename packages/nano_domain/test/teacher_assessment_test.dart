import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('parses teacher assessment list', () {
    final list = TeacherAssessmentList.fromJson({
      'assignment_id': 'asg-1',
      'school_id': 'school-1',
      'class_label': '5-A',
      'subject_code': 'MATH',
      'assessments': [
        {
          'id': 'asm-1',
          'school_id': 'school-1',
          'teacher_assignment_id': 'asg-1',
          'category': 'Quiz',
          'name': 'Chapter 1',
          'assessment_date': '2026-08-03',
          'total_marks': 20,
          'weight': 1.5,
          'description': 'Warm-up',
          'status': 'draft',
        },
      ],
    });

    expect(list.scopeLabel, '5-A · MATH');
    expect(list.draftCount, 1);
    expect(list.assessments.first.name, 'Chapter 1');
    expect(list.assessments.first.isDraft, isTrue);
    expect(AssessmentStatus.parse('published'), AssessmentStatus.published);
  });
}
