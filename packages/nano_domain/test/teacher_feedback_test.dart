import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('parses feedback list with categories and status', () {
    final list = TeacherFeedbackList.fromJson({
      'assignment_id': 'asg-1',
      'school_id': TenancyFixtures.alphaSchoolId,
      'class_label': '5-A',
      'subject_code': 'MATH',
      'notes': [
        {
          'id': 'n1',
          'school_id': TenancyFixtures.alphaSchoolId,
          'teacher_assignment_id': 'asg-1',
          'student_user_id': TenancyFixtures.aliAlphaId,
          'student_display_name': 'Ali Khan',
          'category': 'effort',
          'body': 'Working hard on homework.',
          'status': 'draft',
        },
        {
          'id': 'n2',
          'school_id': TenancyFixtures.alphaSchoolId,
          'teacher_assignment_id': 'asg-1',
          'student_user_id': 'student-2',
          'student_display_name': 'Sara Ahmed',
          'category': 'behavior',
          'body': 'Helpful in group work.',
          'status': 'published',
          'published_at': '2026-08-02T00:00:00Z',
        },
      ],
    });
    expect(list.notes, hasLength(2));
    expect(list.notes.first.category, FeedbackCategory.effort);
    expect(list.notes.first.isDraft, isTrue);
    expect(list.notes.last.category.label, 'Behavior');
    expect(list.notes.last.status, FeedbackNoteStatus.published);
    expect(list.scopeLabel, '5-A · MATH');
  });
}
